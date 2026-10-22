# Google Play billing: working test setup and troubleshooting

Recorded: 22 October 2026. Reusable checklist for other Android/Flutter projects.

## Resolved Qobo case

Error shown for every coin pack:

> This version of the application is not configured for billing through Google Play.

Device logs reported billing response code 5 (DEVELOPER_ERROR). The package and
BILLING permission were correct. Build 13 was active in the Internal testing
track, and the tester email list was selected under Licence testing.

The phone nevertheless had a build installed using a version-specific sharing
link. Even though its installer was Google Play and its version was 13, its
signing certificate differed from both registered Play app-signing certificates.

The user reported that testing worked after using the actual Internal testing
invitation copied from that track's Testers tab. Do not interpret this report as
an independent verification of wallet credit, consumption, or repeated purchase;
those should still be checked when validating a payment release.

Working Qobo invitation:
https://play.google.com/apps/internaltest/4701204623684178383

Previously used version-specific sharing link:
https://play.google.com/apps/test/com.qobo1live.live/13

A guessed generic `/apps/testing/com.qobo1live.live` link did not solve this case.
Always copy the actual invitation from Play Console; do not construct its URL.
These links and certificate values are project-specific.

## Correct setup for a new project

1. Upload the billing-enabled AAB to the app's **Internal testing** track.
2. Publish the testing release and confirm **Available to internal testers**.
3. Add the phone's Google account to the track's tester list.
4. Separately select the appropriate email list under account-level **Licence
   testing**. Track membership alone does not make purchases free.
5. Open **Test and release → Testing → Internal testing → Testers**.
6. Under **How testers join your test**, copy the actual invitation, such as
   **Join on the web**. Labels and URL formats may change over time.
7. Open the invitation using the registered Google account, join the test, and
   follow its Google Play download link.
8. If an existing debug/sharing installation causes a signing conflict, uninstall
   that copy first. Uninstalling deletes local data, login and pending local retry
   state: avoid doing this during an unfinished purchase.
9. Install through the invitation. Do not subsequently replace it with Flutter run.
10. At checkout choose **Test card, always approves**. If only real payment
    methods appear, cancel and check the purchasing Google account/licence setup.

Google can select the account that downloaded the app, which may differ from the
account currently selected in Play Store when several accounts are on the phone.
Debug builds can also support billing for correctly recognised licence testers;
a debug install by itself is not proof of the error's cause.

## Three different concepts

| Feature | Purpose |
| --- | --- |
| Internal testing track | Distributes a released test build to invited testers through Google Play. Use its Testers invitation for release validation. |
| Internal app sharing | Shares a particular artifact; uses a separate test signing certificate and may require enabling Internal app sharing on the phone. |
| Licence testing | Gives registered Google accounts access to free test payment methods. Separate from track membership. |

Internal app sharing is not categorically incompatible with billing. In this
case switching to the correct track invitation resolved the reported problem.
Do not assume all error-5 cases have the same cause.

## Evidence to gather before changing code

- Installed package ID, version name/code, debug flag and installer source.
- Billing-specific response code/debug message from logcat.
- Installed APK certificate compared against current AND previous Play signing
  keys and, if needed, the Internal app sharing test certificate.
- Actual invitation used, tester Google account, release availability, active
  product IDs and regional purchase-option availability.

Useful read-only commands (replace package/path for the project):

```sh
adb devices -l
adb shell dumpsys package com.qobo1live.live
adb logcat -d -s BillingClient:V ProxyBillingActivity:V
adb shell pm path com.qobo1live.live
# Pull the base.apk path returned above, then inspect its public certificate:
adb pull '<installed-base.apk-path>' /tmp/installed-app.apk
apksigner verify --print-certs /tmp/installed-app.apk
```

`installerPackageName=com.android.vending` alone does not distinguish an Internal
app sharing install from a testing-track install. A matching version code also
cannot establish the route used.

Qobo diagnostic fingerprints at resolution:

- Current Play SHA-1: `3E:05:5F:FB:2D:D3:CA:AB:0E:0A:2B:D2:8B:4D:06:99:48:4B:13:6D`
- Previous Play SHA-1 supplied by user: `A4:79:DE:F8:BA:2C:16:09:DE:7B:8F:ED:6C:4C:E6:83:DC:AE:E2:02`
- Failing installed SHA-1: `BE:72:C6:A8:69:10:FD:6F:DE:3F:4F:CB:89:AE:B0:45:7E:E1:59:B6`

The failing certificate was not independently compared with the Console's
Internal app sharing certificate. Treat that identification as an inference
supported by the sharing link, rather than a separately verified certificate match.

## What not to do

- Do not publish to production merely to try to fix test checkout.
- Do not reset/rotate signing keys or edit Firebase SHA entries to fix this error.
- Do not assume clearing cache resolves signing or invitation/account problems.
- Do not promise a successful payment based only on products loading or tests passing.
- Do not keep recommending the same steps once new device evidence rules them out.

## Final payment checks

- Approved purchase adds the correct coins exactly once.
- Cancelled/declined/pending purchases do not prematurely add coins.
- Consumption completes and the same pack can be purchased again.
- Network interruption/restart recovers without duplicate credit.
- Switching app accounts cannot redirect another account's purchase.
- Check regional prices before release. Test purchases do not produce bank payouts.

Qobo's current backend trusts mobile-reported purchase success and can credit
real wallet coins for free test purchases. Use dedicated test accounts and arrange
cleanup of test credits. This does not independently validate payments with Google.

## Official references

- Billing tests: https://developer.android.com/google/play/billing/test
- Licence testing: https://support.google.com/googleplay/android-developer/answer/6062777
- Internal app sharing: https://support.google.com/googleplay/android-developer/answer/9844679
- Billing response codes: https://developer.android.com/reference/com/android/billingclient/api/BillingClient.BillingResponseCode

Recheck official documentation when applying this guide to a future project.
