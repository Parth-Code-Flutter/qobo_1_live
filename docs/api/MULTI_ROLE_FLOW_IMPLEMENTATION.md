# Multi-role flow implementation and verification

Client guide: `API_Multi_Role_Profile_Flow_Code_Verification_and_Rewards_Guide.md`, v2, 9 September 2026.

## Mobile changes

- Normal users have Super Admin, Agency, Host and Coins Seller shortcuts. `roleIcons` controls application shortcut visibility. Approved roles have exactly their own role shortcut; ordinary features such as wallet, chat, family and activity remain available.
- Role resolution supports `role`, nested `roleFlags`, existing seller aliases and legacy seller approval fields. Explicit privileged roles take precedence over stale compatibility flags. An icon flag alone never grants a role.
- The existing main home after login is unchanged. Profile opens Super Admin, Agency and Coins Seller dashboards; Host opens a new self-service dashboard with existing go-live, wallet/withdrawal and gift-transaction flows. No undocumented host statistics endpoint was invented.
- Agency applicants enter a Super Admin code, verify it and submit the full multipart form to `/api/agency/register-public`. Name/email prefill from the current profile. The old short `/api/agency/register` call is no longer used by this form. The public API still requires the password and identity-document fields specified by the client.
- Hosts verify an agency code before upload. `/api/agency/host-onboarding` includes `host_name`, `whatsapp` and `agencyCode` while preserving existing field aliases and extra profile fields. Normal applicants no longer inherit an agency code from a previously cached agency session.
- Both code checks reject null/error/invalid responses, invalidate on edits and discard stale asynchronous responses. Submission re-verifies the code. Requests have busy guards.
- Super Admin shares a code using `/api/super-admin/my-code` and, if absent, `/api/super-admin/generate-code`. The dashboard no longer generates/shares an agency registration link. Manual creation uses `/api/super-admin/add-agency-manual` with the chosen commission percentage converted to a fraction.
- Agency processing prefers `/api/super-admin/agency/process`; the earlier process-request endpoint is retained only for an explicit HTTP 404. Unknown/network outcomes are not automatically retried as a second financial mutation.
- Existing host approve/reject and Super Admin/Coins Seller application endpoints remain in place. Successful approval refreshes relevant agency/dashboard/profile data. Agency rejection is retained as rejection rather than converted into pending, and the status screen permits reapplication.
- Recruitment earnings are read from API fields, with the existing 10,000 coins = USD 1 conversion. Active agency/host counts no longer manufacture earned money when the API omits reward fields.

## Server requirements that cannot be verified from this Flutter repository

The backend/admin-panel source and staging role accounts were not supplied. Local tests validate client requests and UI/state rules; they do not establish that production approvals or payouts work.

1. `/api/agency/register-public` must associate a logged-in applicant with their existing user ID. Confirm that the JWT is honored and an already-registered email/phone does not create an unrelated second owner or fail as a duplicate. Define the password behavior for existing/social-login accounts.
2. Code verification must check sponsor existence, approval/active status and appropriate role. The submit endpoint must independently revalidate the sponsor; client validation is not an authorization boundary.
3. Super Admin requests and seller requests must go to the central admin panel, agency requests to their inviting Super Admin, and host requests to their agency. Reject unauthorized reviewers and cross-sponsor access.
4. Approval must update the applicant's canonical role, flags and exclusive roleIcons in `/api/user/profile`; relogin/profile refresh must return the new state. Rejection must not grant any privileged role. A normal user should not hold conflicting active privileged roles.
5. In one atomic server transaction, the first qualifying agency approval/manual creation credits its Super Admin 10,000 coins; the first qualifying host approval credits its agency owner 10,000 coins. Use a unique ledger key per recruited entity. Repeated approval, retries, reactivation, concurrent requests and duplicate applications must not pay again. Never accept a client-selected reward amount.
6. Return actual recruitment totals in existing dashboard fields (`agencyRecruitmentEarningsCoins`/`agencyRecruitmentEarningsDollars` and summary `hostRecruitmentEarningsCoins`/`hostRecruitmentEarningsDollars`). Return zero explicitly when applicable. Counts alone cannot prove credits.
7. The guide describes manual agency creation but not how the created owner receives credentials or claims the account; confirm that provisioning step in the backend/admin panel.
8. Persist and return rejection feedback. Deliver `host_approved` as described, but profile refresh/relogin must also work when that notification is missed.

## Staging acceptance sequence

Use dedicated staging accounts; do not run recruitment-credit tests against real users.

| Scenario | Expected result |
| --- | --- |
| New ordinary signup | Four role shortcuts; no privileged dashboard access |
| Super Admin apply, reject, apply, approve | Central admin review; rejected stays user; approved relogin shows only Super Admin shortcut |
| Code sharing | Real backend code copied/shared; agency applicant verifies matching sponsor |
| Invalid code, network failure or code edited during verification | No application upload until the current code is successfully verified |
| Agency application | Full fields/files received; existing applicant linked; pending under correct Super Admin |
| Agency approval/rejection | Only sponsor can review; rejection feedback visible; approval changes role and credits sponsor once |
| Manual agency creation | Correct owner, commission and approved agency; sponsor credited once; owner provisioning works |
| Host application and review | Correct agency sees request; approval changes applicant to host and credits owner once |
| Five distinct hosts approved | Exactly +50,000 coins / USD 5 in ledger and wallet |
| Repeat/concurrent approval or reactivation | No additional credit |
| Coins Seller application | Existing central-admin review flow; approved relogin shows only seller shortcut |
| Logout, switch user, relogin | No prior user's privileges or prefilled sponsor code |
| Existing live/chat/wallet/agency tracking | Existing routes and behavior remain usable |

## Validation record

Final regression run: **125 tests passed** across 23 test files, including role isolation, code-verification races/errors, API payload contracts, host-dashboard access, home routing and recruitment conversion. Initial focused run: 40 passed; both additional widget tests passed after mocking secure storage.

The complete suite was attempted. Two failures reproduced on an isolated copy of original commit `b8f17e4`: `profile_background_media_test.dart` (HTTP-to-HTTPS expectation) and `live_broadcast_group_call_error_test.dart` (ZEGO platform initialization). `backpack_controller_test.dart` also stalled on both the current and original trees. Those three test files were excluded from the final 125-test regression run.

Final static analysis: no errors and no diagnostics in changed files; 234 pre-existing project diagnostics remain (warnings/information). `git diff --check` passed. No live applications, approvals, wallet mutations, deployment or push were performed for this implementation.
