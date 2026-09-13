# Role applications — final September 2026 contract

Aligned with `SuperAdmin_Agency_Host_Complete_API_Documentation.md`.

- Super Admin: POST `/api/user/super-admin-request`; fullName, email, phone, optional description; required doc_photo_front/doc_photo_back. No ID number or original photo.
- Agency: POST `/api/agency/register-public`; name (agency name), ownerName, phone, invitedBy, optional description and document uploads. Email is not collected or sent.
- Host: POST `/api/agency/host-onboarding`; hostName, whatsapp, agencyCode, optional description and document uploads. No additional face photo is required.

Saved profile name/contact values are reused. Missing required contact fields remain editable: email is collected only for Super Admin submissions. Host email/gmail is omitted entirely at the user’s request, overriding the supplied document’s email requirement. Agency name is separate from the owner's profile name. Applications for another person never reuse the operator's personal details.

Code verification uses GET `/api/agency/verify-super-admin-code?code=...` or GET `/api/agency/verify-code?code=...`.

Status checks use the saved phone automatically, without an email/identifier input:
- Super Admin: GET `/api/user/super-admin-status?phone=...`
- Agency: GET `/api/agency/status?query=...`
- Host: GET `/api/agency/application-status?phone=...`

The shared repository handles plain documented response objects and older statusCode/data envelopes. HTTP errors remain failures. Existing and duplicate applications open status directly; refresh failures retain the displayed status. Missing profile phone produces a clear message. Approval continues to rely on backend profile roles and the existing sign-out/sign-in flow.

The existing purple gradient, Poppins text, white application sheet, and purple buttons are retained. Optional uploads are labeled, descriptions use two lines, and status lookup requires no re-entry of contact details.

Management dashboards, manual agency creation, approval/reward operations, and the configured API host are unchanged. Tests cover request contracts, code verification, optional uploads, response formats, profile reuse, status refresh, required Super Admin documents, duplicate submission, and existing role flows. No real identity documents or applications were submitted; deployed backend acceptance still needs staging verification.
