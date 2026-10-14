# Facebook login release checks

## Code fix

Facebook SDK success previously stopped at a demo toast unless the build explicitly
set FACEBOOK_SUBMIT_TO_BACKEND=true. Backend exchange now defaults to true for both
login and sign-up, using the existing POST /api/auth/social flow.
Do not override FACEBOOK_SUBMIT_TO_BACKEND=false in the release build.

Accounts without email now omit email instead of sending a fabricated address.
iOS Limited Login reads profile claims from the SDK's LimitedToken rather than
attempting a Graph API request with a limited token.

## Meta configuration (requires console verification)

- Meta app ID configured in the app: 1001720392415003
- Android package: com.qobo1live.live
- Android activity: com.qobo1live.live.MainActivity
- Play signing SHA-1 supplied on October 5, 2026:
  3E:05:5F:FB:2D:D3:CA:AB:0E:0A:2B:D2:8B:4D:06:99:48:4B:13:6D
- Corresponding Facebook Key Hash (Base64 of the SHA-1 bytes):
  PgVf+y3TyqsOCivSi00GmUhLE20=

In that Meta app's Android platform configuration, ensure this Key Hash is
registered. Keep other valid signing hashes. If the installed app uses another
Play signing certificate (including a previous key), register its hash too.
Firebase SHA registration does not register the key in Meta.

Confirm the Facebook Login use case is available to public users, the app is
live/published, and requested email/public_profile permissions have the access
required by Meta for public users. A developer/tester account alone is not a
production validation.

## Validation before rollout

1. Build an update with a higher actual build number; the UI version label is not
   the Android versionCode. Use the existing authorized upload keystore.
2. Install through a Play testing track to exercise Play signing.
3. Test with a Facebook account that is not a Meta app administrator/tester.
4. Confirm Facebook returns to Qobo, POST /api/auth/social succeeds, and the app
   enters the appropriate home/profile-setup flow with a saved backend session.
5. Check cancellation, declined email, and the browser fallback when the Facebook
   app is absent. Also test iOS Limited Login on a real iOS device.

Unit tests cover configuration default, classic/limited SDK profile mapping,
optional email and SDK failure. They do not validate Meta console settings or
the live backend. No production account was created during development.

Backend contract remains unchanged. The server must authenticate provider proof
before issuing a session; the current mobile request model contains profile
fields rather than a provider token. Verify the server's security contract with
the backend team separately; do not assume profile fields prove ownership.

Reference: https://facebook.meedu.app/docs/7.x.x/android/
