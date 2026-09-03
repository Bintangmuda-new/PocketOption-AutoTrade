# BM Future Flutter App

Satu client Flutter untuk Android, Windows 10, dan Flutter Web. Client ini
hanya berbicara dengan FastAPI melalui REST/WebSocket. SSID, cookie, password,
token, dan API key tidak pernah dimasukkan ke aplikasi.

## Jalankan

```bash
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android emulator:

```bash
flutter run -d <android-device> --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Perangkat Android fisik harus memakai IP LAN komputer, misalnya
`http://192.168.1.10:8000`, dan FastAPI harus bind ke `0.0.0.0`.

Flutter Web:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Build gratis lokal

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter build windows --release --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Hasil build tersimpan di `build/app/outputs/flutter-apk/`,
`build/windows/x64/runner/Release/`, dan `build/web/`.

## Safety boundary

- DEMO selalu menjadi mode awal.
- REAL hanya bisa dipilih sebagai status visual; koneksi/auto trade REAL tetap dikunci backend secara default.
- Tidak ada Paper Trading atau akun virtual.
- Dashboard tidak mengarang balance, candle, profit/loss, atau signal live.
- Tombol Auto Trade memanggil endpoint START/STOP/EMERGENCY backend. START tetap
  ditolak jika broker, AI, rekonsiliasi, data, Risk, atau execution gate belum PASS.
- Flutter tidak pernah melakukan raw broker call.
