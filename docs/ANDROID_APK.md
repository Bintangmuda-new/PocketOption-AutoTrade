# Android APK

The Android runner is generated and built by `.github/workflows/build-android-apk.yml`.
The release artifact is a debug-keystore-signed development release intended for
direct installation on a personal Android device. It is not a Play Store signing
key and must be replaced with the owner's private release key before distribution.

The APK contains the Flutter client only. The FastAPI trading backend remains a
separate service. For a physical device, configure the backend URL with
`--dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000` when rebuilding. No SSID,
password, cookie, token, or API key is bundled in the APK.

Safety defaults:

- DEMO is the first-run mode.
- REAL order flow is disabled by backend policy.
- No paper account or simulated live account exists.
- Auto Trade remains fail-closed until broker, market data, AI, risk, and
  execution health checks are all green.
