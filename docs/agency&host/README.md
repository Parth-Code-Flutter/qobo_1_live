# Agency & Host Flow Implementation Plan

Last reviewed: 2026-06-04

This document reflects the current Flutter implementation after the latest agency/host UI and UX updates. It compares the app code with the backend agency flow shared by the backend team and lists the exact implementation work still needed.

## Current Entry Points

The current visible entry point is in Profile:

```text
Profile
  -> Agency & Host
       -> Join an Agency (Host)
       -> Agency Owner Dashboard
```

Code reference:

- `lib/app/user_flow/profile_tab/views/profile_tab_view.dart`
- `Join an Agency (Host)` opens `Routes.AGENCY_ACCESS` with `{ mode: 'host' }`
- `Agency Owner Dashboard` opens `Routes.AGENCY_ACCESS` with `{ mode: 'owner' }`

The earlier Discover banner/cards for agency entry are not present in the current searched Discover implementation. If product wants Discover entry again, it should be re-added as a secondary shortcut, not a separate flow.

## Current Route Map

| Route | Screen | Current purpose |
| --- | --- | --- |
| `/agency-access` | `AgencyAccessView` | Main switcher for Host and Agency Owner modes. |
| `/agency-host-onboarding` | `AgencyHostOnboardingView` | Host application form with photo upload and agency code. |
| `/agency-host-status` | `AgencyHostStatusView` | Application status lookup screen. |
| `/agency-owner-register` | `AgencyOwnerRegisterView` | Agency registration UI. Currently local/mock submit. |
| `/agency-recruit-link` | `AgencyRecruitLinkView` | Shows agency code/link. Currently static data. |
| `/agency-host-list` | `AgencyHostListView` | My Hosts list UI. Currently no API data loaded. |
| `/agency-revenue` | `AgencyRevenueView` | Revenue/payout UI. Currently local empty values. |
| `/agency-owner` | `AgencyOwnerView` | Older agency owner center. Currently local/mock dashboard. |

## Current Implementation Audit

| Area | Current files | Current state | Gap / action needed |
| --- | --- | --- | --- |
| Profile navigation | `profile_tab_view.dart` | UI has two actions: host application and owner dashboard. | Good as primary navigation. Confirm whether Discover should also expose these shortcuts. |
| Agency access | `agency_access/*` | Host/Owner mode switcher exists. Host mode routes to apply/status. Owner mode shows agency-code, phone/Gmail, password login UI. | Backend flow does not include a separate agency owner login endpoint. Decide whether to remove this login or replace it with normal user session + agency lookup. |
| Host onboarding UI | `agency_host_onboarding/*` | Modern form exists with real photo, host name, birthday, host ID, WhatsApp, Gmail, agency code, category, submit loader. | Comment still says "UI only", but controller does call API. Update comment later. API field names need alignment. |
| Host onboarding API | `AgencyRepo.hostOnboarding` | Calls `POST /api/agency/host-onboarding` multipart. Sends compatibility aliases. | Current app sends `birthday`, `hostIdNumber`, and file field `host_real_photo`; backend flow expects `dob`, `id_no`, and `real_photo`. |
| Host status UI/API | `agency_host_status/*`, `AgencyRepo.hostVerifyStatus` | Screen can search by Application ID, Host ID, Agency ID, or Phone. Auto-fetches when routed with application/phone args. | Backend flow documents only `application_id` and `phone`. App expects `{ statusCode: 1, data: {...} }`; backend sample should be wrapped consistently. |
| Agency owner register UI | `agency_owner_register/*` | Modern UI exists with logo, agency name, owner name, WhatsApp. Submit shows local success and opens recruit link. | Must call `POST /api/agency/register`. Backend currently only expects `agency_name`; extra logo/owner/WhatsApp are UI-only unless backend adds support. |
| Recruit link UI | `agency_recruit_link/*` | Screen copies agency code/link and navigates to host list. | Static values: `QOBO-AG8X9`, `https://qobo1.live/invite/QOBO-AG8X9`. Must bind `GET /api/agency/generate-link?agency_id=<id>`. |
| Host list UI | `agency_host_list/*` | List UI and empty state exist. Refresh button exists. | Controller clears list and never calls `AgencyRepo.getAgencyHostsList`. Needs agency ID source and API mapping. |
| Revenue UI | `agency_revenue/*` | Balance card, history section, payout button, empty history exist. | Controller is local only. Needs `GET /api/agency/revenue?month=<month>`. Payout API is not in shared backend flow. |
| Older owner center | `agency_host_onboarding/views/agency_owner_view.dart`, `agency_owner_controller.dart` | Local create-agency/dashboard flow with generated local code, invite link copy, and empty host list. | This overlaps with newer owner register/recruit screens. Recommended: remove or merge before API binding. |
| Agency repository | `lib/repo/agency/agency_repo.dart` | Repo methods exist for onboarding, status, register, generate link, host list, revenue, payout. | Register/link/list/revenue methods are not wired into the current owner-side controllers. Revenue lacks month parameter. Payout needs backend confirmation. |

## Current User Flow In App

### Host Applicant Flow

```text
Profile
  -> Join an Agency (Host)
  -> Agency Access (Host tab)
  -> Apply as Agency Host
  -> Host Registration form
  -> Submit application
  -> Success dialog
  -> Application Status screen
```

What works now:

- Form validation exists.
- Photo picker exists.
- Category selection exists.
- API call exists.
- On success, app routes to status screen with `application_id` and `phone`.

What still needs work:

- Align multipart keys with backend.
- Remove fallback `APP-90210` once backend always returns application ID.
- Confirm public endpoint does not require token.
- Confirm backend returns normal error for invalid agency code.

### Host Status Flow

```text
Profile
  -> Join an Agency (Host)
  -> Agency Access (Host tab)
  -> Check Application Status
  -> Search by Application ID / Host ID / Agency ID / Phone
```

What works now:

- UI supports manual lookup.
- It can auto-run lookup if routed with args.
- Status card handles approved/rejected/not-found styling.

What still needs work:

- Backend officially supports only `application_id` and `phone` from the shared flow. Either hide Host ID/Agency ID chips or backend should support them.
- Backend should return `statusCode`, `message`, and `data` consistently.
- Not-found should not return HTTP 500.

### Agency Owner Flow

Current UX:

```text
Profile
  -> Agency Owner Dashboard
  -> Agency Access (Owner tab)
       -> Login to Agency Portal
            -> Older Agency Owner Center (/agency-owner)
       -> Register New Agency
            -> Register Agency screen
            -> local success
            -> Recruit Link screen
            -> Host List / Revenue
```

Important current issue:

There are two owner-side concepts:

1. `AgencyAccessView` owner tab has login fields.
2. `AgencyOwnerRegisterView` and `AgencyRecruitLinkView` are the newer registration/recruit screens.
3. `/agency-owner` is an older local dashboard that also creates an agency locally.

The backend flow says agency owners are normal logged-in users who register an agency. It does not mention a separate agency owner password/login. So the recommended implementation is:

```text
Logged-in user
  -> Agency Owner Dashboard
  -> If user owns agency: Agency Dashboard
  -> If user does not own agency: Register Agency
```

## Backend API Contract From Shared Flow

### 1. Register Agency

```http
POST /api/agency/register
Auth: user login required
```

Request:

```json
{
  "agency_name": "Star Agency"
}
```

Expected response:

```json
{
  "id": "agency-uuid",
  "name": "Star Agency",
  "code": "STAR01",
  "commissionRate": 0.10,
  "status": "active"
}
```

Mobile binding plan:

- Bind `AgencyOwnerRegisterController` to `AgencyRepo.registerAgency`.
- Send only `agency_name` first.
- After success, store `agencyId`, `agencyName`, `agencyCode`, `commissionRate`, and `status`.
- Route to recruit link/dashboard with that stored agency data.
- If keeping logo/owner/WhatsApp UI fields, treat them as optional until backend supports them.

### 2. Generate Recruitment Link

```http
GET /api/agency/generate-link?agency_id=<agency-id>
Auth: user login required
```

Expected response:

```json
{
  "link": "https://qobo1live.com/recruit?agency=STAR01"
}
```

Mobile binding plan:

- Replace static `agencyCode` and `recruitLink` in `AgencyRecruitLinkController`.
- Load agency ID/code from stored agency session or route arguments.
- Call `AgencyRepo.generateInviteLink(agencyId: agencyId)`.

### 3. Host Onboarding

```http
POST /api/agency/host-onboarding
Auth: none
Content-Type: multipart/form-data
```

Backend fields:

| Backend field | Current app field/key | Required change |
| --- | --- | --- |
| `name` | `name`, `hostName` | Keep `name`; `hostName` can remain as compatibility only if backend wants it. |
| `dob` | `birthday` | Send `dob` in `yyyy-MM-dd` format. |
| `id_no` | `hostIdNumber` | Send `id_no`. |
| `phone` | `phone`, `whatsapp` | Keep `phone`; `whatsapp` optional compatibility. |
| `gmail` | `gmail` | Already aligned. |
| `category` | `category` | Already aligned. |
| `agency_code` | `agency_code`, `agencyCode` | Keep `agency_code`; `agencyCode` optional compatibility. |
| `real_photo` | `host_real_photo` | Change file field to `real_photo`, or backend must support both. |

Expected response:

```json
{
  "statusCode": 1,
  "message": "Host application submitted",
  "data": {
    "id": "application-uuid",
    "hostName": "Priya Sharma",
    "status": "pending",
    "agencyCode": "STAR01",
    "createdAt": "2026-06-01T00:00:00.000Z"
  }
}
```

### 4. Host Verify Status

```http
GET /api/agency/host-verify-status?application_id=<uuid>
GET /api/agency/host-verify-status?phone=<whatsapp-number>
Auth: none
```

Recommended response:

```json
{
  "statusCode": 1,
  "message": "Application status fetched",
  "data": {
    "id": "application-uuid",
    "status": "pending",
    "createdAt": "2026-06-01T00:00:00.000Z",
    "reason": null
  }
}
```

If no application exists:

```json
{
  "statusCode": 0,
  "message": "No host application found",
  "data": null
}
```

### 5. Agency Host List

```http
GET /api/agency/host-list?agency_id=<agency-id>
Auth: user login required
```

Mobile binding plan:

- Add agency ID source to `AgencyHostListController`.
- Call `AgencyRepo.getAgencyHostsList`.
- Map approved hosts into `AgencyHostModel`.
- Keep current empty state when list is empty.

Recommended host fields:

```json
{
  "id": "host-application-or-host-id",
  "name": "Priya Sharma",
  "phone": "9876543210",
  "gmail": "name@gmail.com",
  "photo": "https://...",
  "category": "Music",
  "status": "approved",
  "totalGifts": 120,
  "totalEarnings": 4500,
  "createdAt": "2026-06-01T00:00:00.000Z"
}
```

### 6. Agency Revenue

```http
GET /api/agency/revenue?month=June
Auth: user login required
```

Mobile binding plan:

- Add `month` parameter to `AgencyRepo.getAgencyRevenueStats`.
- Bind `AgencyRevenueController` to API.
- Map `totalRevenue`, `totalEarnedCommissions`, `pendingCommissionAmount`, `pendingCommissionCount`, `hostsCount`, `payoutStatus`, `agencyCode`, and `commissionRate`.
- Keep current no-history empty state if backend returns no records.

## Recommended Implementation Phases

### Phase 1 — Consolidate Owner Navigation

- Decide one owner dashboard path.
- Recommended:
  - Profile owner action opens `AgencyAccessView` owner mode only as a landing screen.
  - Remove owner password login unless backend adds an owner login API.
  - Owner CTA should either:
    - open Register Agency if no agency exists, or
    - open Agency Dashboard if user already owns one.
- Merge or retire `/agency-owner` because it is local/mock and overlaps with newer screens.

### Phase 2 — Add Agency State Source

Create a small agency session/state model used by owner screens:

```text
agencyId
agencyName
agencyCode
commissionRate
status
recruitLink
```

This can start as a GetX service or controller-level state. Later it can persist with the logged-in user/session.

### Phase 3 — Bind Register Agency

- Inject/use `AgencyRepo` in `AgencyOwnerRegisterController`.
- Replace local delay and local success message with API call.
- Navigate to recruit link screen with returned agency data.
- Handle duplicate-owner API error clearly.

### Phase 4 — Bind Recruit Link, Host List, Revenue

- `AgencyRecruitLinkController`: call generate link API.
- `AgencyHostListController`: call host list API.
- `AgencyRevenueController`: call revenue API with month.
- Add consistent loading/error/no-data states.

### Phase 5 — Align Host Application API

- Send `dob`, `id_no`, and `real_photo` according to backend contract.
- Keep compatibility aliases temporarily only if deployed backend still requires them.
- Use returned `id` only; remove fallback `APP-90210` once backend is stable.

### Phase 6 — Status Verification Polish

- Confirm backend support for Host ID/Agency ID lookups.
- If unsupported, hide those chips and keep only Application ID + Phone.
- Make not-found a normal UI state.

### Phase 7 — Live/Gift Commission Integration

After live streaming and gifts are stable:

- Approved hosts should be linkable to their agency.
- Gifts received by approved hosts should generate agency commission.
- Revenue endpoint should reflect gift volume and pending/earned commission.

## Testing Checklist

| Test | Expected result |
| --- | --- |
| Profile -> Join an Agency | Opens Agency Access in Host mode. |
| Profile -> Agency Owner Dashboard | Opens Agency Access in Owner mode. |
| Host application submit | Public multipart API creates pending application. |
| Host application success | App routes to status screen with real application ID. |
| Status by application ID | Shows pending/approved/rejected. |
| Status by phone | Shows latest matching application or no-data. |
| Register agency | Logged-in user gets agency ID/code/status. |
| Duplicate agency owner | Shows backend duplicate-owner error. |
| Recruit link | Shows real backend link/code, not static data. |
| Host list | Shows approved hosts from backend. |
| Revenue | Shows backend stats or no-data state. |

## Backend Questions Still Open

1. Does agency owner need a separate login/password flow, or does normal user login cover owner access?
2. Should `/api/agency/register` accept logo, owner name, and WhatsApp, or only `agency_name`?
3. Should invalid `agency_code` in host onboarding be rejected, or should backend auto-create placeholder agency?
4. Should `host-verify-status` support `host_id` and `agency_id`, or only `application_id` and `phone`?
5. Should every agency API use the same `{ statusCode, message, data }` envelope?
6. Is `POST /api/agency/payout` actually available? It exists in mobile repo but not in the shared backend flow.
7. When admin approves a host, should backend auto-create/link a user host account?

## Immediate Next Step

Start with owner flow consolidation, then bind `POST /api/agency/register`. That unlocks the real `agencyId`, which is required for recruit link, host list, and revenue screens.

