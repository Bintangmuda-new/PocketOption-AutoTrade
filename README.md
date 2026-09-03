# BM Future PO AutoTrade AI

Platform trading Pocket Option dengan Flutter Android/Web, backend FastAPI async, market data realtime, multi-AI analysis, MCP server, signal engine, risk gate, auto trade, backtest NautilusTrader, jurnal, dan analytics.

> **Status saat ini: web/PWA runnable + Flutter client source + Android release build workflow + broker-backed market/AI/Risk/Auto Trade boundary + SQLite journal/statistics.**  
> `ARCHITECTURE.md` dan `TREE.md` menjadi kontrak teknis. Client web dapat di-install sebagai aplikasi di Android/Windows melalui browser, dan APK Android release dibangun oleh GitHub Actions dari `apps/flutter_app`. Adapter backend DEMO sudah lulus health-check nyata. LiteLLM/MCP/indicator/consensus/risk/execution/journal sudah memiliki interface dan test boundary; backend tetap dijalankan terpisah dari APK.

## Peringatan penting

Pocket Option connector yang dijadikan referensi adalah implementasi tidak resmi. Auto trading, khususnya REAL, dapat menyebabkan kehilangan dana dan dapat melanggar aturan broker atau hukum yang berlaku. Sistem ini tidak menjamin profit dan bukan nasihat keuangan.

Default sistem adalah `DEMO`. Automated test hanya menggunakan DEMO atau fake/recorded broker. `REAL` harus diaktifkan secara eksplisit setelah koneksi, risk policy, dan rekonsiliasi diuji.

## Prinsip yang tidak boleh dilanggar

- Mode akun hanya `DEMO` dan `REAL`.
- Tidak ada Paper Trading, Paper Account, Paper Balance, Virtual Account, atau Simulated Live Trading.
- Backtest bukan akun dan bukan paper mode; backtest adalah riset historical data yang terisolasi.
- UI, AI, dan MCP tidak boleh memanggil broker secara langsung.
- Semua order melewati `AI Consensus → Risk Engine → Execution Engine → PocketOptionBrokerAdapter`.
- Risk Engine memiliki hak final: `APPROVED` atau `REJECTED`.
- Data stale, balance tidak tersedia, pair closed, payout tidak valid, AI gagal, atau koneksi tidak sehat berarti **tidak entry**.
- Tidak ada Martingale atau penggandaan nominal setelah loss.
- Credential, SSID, session, cookie, password, token, dan API key tidak boleh masuk Git, log, response, atau database plaintext.

## Target sistem

```text
Pocket Option
  ↓
PocketOptionBrokerAdapter
  ↓
Market Data Engine + WebSocket
  ↓
Feature / Indicator Engine
  ↓
AI Analyst 1 + AI Analyst 2
  ↓
AI Consensus Engine
  ↓
Signal Engine
  ↓
Risk Engine
  ↓
Execution Engine
  ↓
Auto Trade
  ↓
Journal + Analytics
```

Jalur backtest terpisah:

```text
DEMO account context
  ↓
Historical candles/ticks
  ↓
NautilusTrader Backtest Engine
  ↓
Strategy / Feature / AI replay
  ↓
Backtest Results + Analytics
```

Backtest tidak memiliki akses ke live order function dan tidak pernah mengirim order ke Pocket Option.

## Fitur utama

### Broker dan market

- `PocketOptionBrokerAdapter` yang dapat diganti tanpa mengubah UI, AI, atau backtest;
- `connect`, `disconnect`, `reconnect`, balance, account type, pairs, payout, history, ticks, candles, call, put, result, open trades, dan trade history;
- WebSocket realtime, heartbeat, connection health, automatic reconnect, exponential backoff, dan deduplikasi listener;
- pemisahan session, saldo, cache, histori, signal, trade, dan journal DEMO/REAL.

### AI

- Analyst teknikal untuk indicator, trend, momentum, volatility, support/resistance, candle, dan price action;
- Analyst structure untuk pattern, multi-timeframe, historical similarity, market structure, confidence verification, dan anomaly;
- `LLMProvider` abstraction melalui LiteLLM;
- provider configurable: OpenAI, Anthropic, Ollama, serta provider LiteLLM lain;
- Ollama optional pada `http://localhost:11434` untuk detect, list model, test model, default, dan fallback;
- structured JSON dengan schema validation; output invalid atau tidak lengkap selalu menjadi `WAIT/REJECT`.
- `backend/requirements-ai.txt` memakai LiteLLM dan optional `ta`; tidak ada provider yang di-hardcode;
- feedback win-rate hanya memakai settlement `WIN/LOSS/DRAW` terverifikasi dan dapat menahan bucket pair/confidence yang lemah setelah sample minimum.

### MCP

- `mcp/trading_mcp/server.py` mengikuti MCP Python SDK dan hanya memanggil application API;
- tools status, market snapshot, indicators, scan, signal, AI health, journal/statistics, dan DEMO-only backtest guard;
- tidak ada raw broker call atau tool order di MCP.

### Signal dan auto trade

- `ANALYZE ALL MARKETS` untuk pair open dengan payout, data, dan health yang valid;
- ranking pair berdasarkan direction, confidence, payout, trend, expiration, consensus, dan score;
- expiry signal server-side dan countdown di UI;
- start, stop, dan emergency stop;
- monitoring result dan journal otomatis;
- Risk Engine memeriksa balance, payout, confidence, signal age, simultaneous trades, stop loss, target profit, daily loss, consecutive losses, connection health, dan emergency stop.

### Backtest

- hanya dapat dijalankan saat `AccountMode=DEMO`;
- REAL menonaktifkan menu secara UI dan menerima `403 BACKTEST_DEMO_ONLY` dari backend;
- parameter pair, OTC/Regular, tanggal, timeframe, expiration, strategy, confidence, payout, entry amount, indicators, AI model, dan consensus threshold;
- metrik total trades, win/loss/draw, win rate, profit/loss, net result, drawdown, consecutive wins/losses, profit factor, expectancy, pair/timeframe/strategy performance, dan AI confidence performance;
- equity curve, win/loss chart, pair/hour/strategy statistics, confidence analysis, dan seluruh entry table.

### UI

- dark futuristic trading terminal;
- Android bottom navigation: Dashboard, Market, Signals, Trade, More;
- Web sidebar dengan menu yang sama;
- dashboard balance, P/L, win rate, AI health, signals, auto trade, market state, dan chart;
- chart candlestick/line/area, zoom, pan, crosshair, price/time scale, volume, indicators, entry/win/loss/signal marker;
- REAL warning visual berbeda dan status connection/data/AI/auto trade yang jelas.

## Arsitektur singkat

```text
apps/web_dashboard/               Web UI runnable, fixture lokal, tanpa order
apps/flutter_app/                 Target Flutter Android + Web satu codebase
backend/src/bmfuture/             FastAPI, domain, use case, broker, AI, risk
mcp/trading_mcp/                  BMFuture Trading MCP Server
contracts/                        OpenAPI, event schema, AI schema
tests/                            Unit, integration, contract, e2e, fixtures
docker/                           Container image dan healthcheck
docs/                             ADR, runbook, API, AI, backtest, operations
```

Baca detail lengkap di [ARCHITECTURE.md](ARCHITECTURE.md) dan daftar file target di [TREE.md](TREE.md).

## Kontrak utama

### Account mode

```text
AccountMode = DEMO | REAL
```

DEMO dipilih saat first run. Setiap repository dan service menerima scope `account_id + account_mode`; tidak ada mutable global account mode.

### Consensus output

Minimal output yang harus lolos schema:

```json
{
  "schema_version": "1.0",
  "pair": "EURUSD_otc",
  "direction": "CALL",
  "expiration": 60,
  "confidence": 82,
  "market_regime": "TRENDING",
  "risk": "MEDIUM",
  "reason": [],
  "indicators": {},
  "analyst_1_confidence": 84,
  "analyst_2_confidence": 80,
  "consensus_count": 2,
  "decision": "APPROVE",
  "source_snapshot_id": "uuid",
  "generated_at": "UTC timestamp",
  "expires_at": "UTC timestamp"
}
```

`direction` hanya `CALL`, `PUT`, atau `WAIT`. AI tidak boleh mengarang market data dan tidak pernah memiliki akses ke `place_call`/`place_put`.

### Risk output

```text
RiskDecision {
  decision: APPROVED | REJECTED
  reasons: list[RiskReason]
  checked_at: UTC timestamp
  policy_version: string
}
```

Tidak ada `APPROVED` jika health, balance, payout, signal freshness, mode, atau batas risiko tidak lulus.

## Prasyarat implementasi

Target environment:

- Python 3.12 atau lebih baru;
- Flutter stable yang mendukung Android dan Web;
- Android SDK/command-line tools;
- Docker Desktop dan Docker Compose;
- Git;
- PostgreSQL;
- Redis;
- Ollama optional;
- akun Pocket Option DEMO untuk smoke test konektor.

Dependency akan dipin menggunakan lockfile saat phase implementasi. Jangan mengandalkan versi floating pada production.

## Konfigurasi environment

File yang akan digunakan:

```text
.env.example       template tanpa secret
.env.test.example  konfigurasi fake/recorded test
.env               local-only dan wajib masuk .gitignore
```

Kelompok konfigurasi:

```text
APP_ENV
API_HOST
API_PORT
DATABASE_URL
REDIS_URL

BROKER_DEMO_*      credential/config DEMO terpisah
BROKER_REAL_*      credential/config REAL terpisah

AI_PROVIDER
AI_MODEL
AI_TEMPERATURE
AI_TIMEOUT_SECONDS
AI_FALLBACK_PROVIDER
AI_FALLBACK_MODEL
OLLAMA_BASE_URL

RISK_MIN_CONFIDENCE
RISK_MIN_PAYOUT
RISK_MAX_SIMULTANEOUS_TRADES
RISK_STOP_LOSS
RISK_TARGET_PROFIT
RISK_DAILY_LOSS
RISK_MAX_CONSECUTIVE_LOSSES
MARKET_DATA_STALE_SECONDS
```

Nama konfigurasi final dapat berubah saat implementasi, tetapi pemisahan DEMO/REAL dan redaction adalah wajib.

## Cara memakai sekarang

### Aplikasi Android dan Windows tanpa biaya langganan

Buka [BM Future App](https://bm-future-po-autotrade-ai-uzwcnf.v2.appdeploy.ai/?mode=DEMO) di Chrome Android atau Edge/Chrome Windows. Pilih `Add to Home screen` atau `Install app` agar tampil sebagai aplikasi terpisah. Ini adalah PWA HTTPS yang dapat digunakan tanpa biaya langganan; koneksi broker tetap dilakukan oleh backend lokal dan tidak pernah meminta SSID di browser.

### Build native Flutter dan APK Android

Source Flutter untuk Android, Windows 10, dan Web berada di `apps/flutter_app`. Build APK release tersedia melalui workflow `.github/workflows/build-android-apk.yml`. Workflow membuat Android runner, menjalankan analyze/test, lalu mengunggah APK installable beserta SHA-256.

Untuk build lokal pada komputer yang memiliki Flutter stable, runner platform dibuat oleh script berikut:

```bash
./scripts/bootstrap_flutter_platforms.sh
./scripts/build_android.sh
```

Windows PowerShell:

```powershell
.\scripts\build_windows.ps1
```

Build native tidak menyimpan credential. API URL hanya diberikan lewat `--dart-define` dan SSID tetap berada di backend.

## Quick start setelah source code tersedia

Client web/PWA dapat dijalankan sekarang. Backend adapter DEMO, market
normalization, indicators, LiteLLM boundary, MCP read-only tools, consensus,
risk, Auto Trade lifecycle, serta SQLite journal/statistics sudah tersedia dengan default execution gate OFF.
Install optional dependencies dari `backend/requirements-ai.txt`,
`mcp/requirements.txt`, atau `backend/requirements-backtest.txt` sesuai fitur.
Adapter historical Nautilus lengkap tetap menjadi pekerjaan lanjutan; sistem
tidak mengarang metrik ketika data belum ada.

### Client web saat ini

```bash
cd apps/web_dashboard
npm install
VITE_API_URL=http://127.0.0.1:8000 npm run dev
```

Buka `http://localhost:5173`. Jika `VITE_API_URL` tidak diisi, dashboard tetap berada di mode aman tanpa koneksi broker. Jika diisi, gunakan tombol `CONNECT DEMO`; dashboard hanya menerima health/balance yang sudah dinormalisasi dari backend. Browser tidak pernah menerima SSID dan tidak dapat mengirim order.

### DEMO broker health-check

```bash
PYTHONPATH=backend/src python backend/scripts/connect_demo.py \
  --ssid-file upload/01-SSID-Akun-Demo.txt
```

Health-check DEMO berhasil pada environment ini dengan `CONNECTED=True`, saldo
tersedia, dan 183 pair. SSID REAL tidak dipakai. Jangan menaruh isi SSID ke
`.env`, source code, issue, commit, atau log.

### 1. Jalankan backend dengan Docker (opsional)

```bash
cp .env.example .env
docker compose up --build api
```

Mount `upload/` hanya untuk file SSID lokal; container tetap memulai dengan
REAL connection dan kedua execution gate OFF. MCP dapat dijalankan dengan
`docker compose --profile mcp up --build`, dan Ollama optional dengan profile
`ollama`.

Ollama hanya jika memang ingin memakai local AI:

```bash
ollama serve
ollama list
```

### 2. Siapkan backend tanpa Docker

```bash
cd backend
python -m pip install -r requirements.txt
PYTHONPATH=src uvicorn bmfuture.main:app --reload
```

PowerShell:

```powershell
Set-Location backend
uv sync
uv run alembic upgrade head
uv run uvicorn bmfuture.main:app --reload
```

### 3. Jalankan MCP secara lokal

```bash
cd mcp/trading_mcp
uv sync
uv run python -m bmfuture_mcp.server --transport stdio
```

MCP stdio hanya menulis log ke stderr. Jangan memakai `print()` untuk log karena dapat merusak JSON-RPC.

### 4. Jalankan Flutter

```bash
cd apps/flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Untuk Android, gunakan alamat backend yang dapat dijangkau perangkat; `localhost` pada Android berarti perangkat itu sendiri, bukan komputer development.

### 5. Smoke test awal selalu DEMO

Urutan validasi:

1. health API, PostgreSQL, Redis;
2. koneksi Pocket Option DEMO;
3. balance dan account type;
4. pairs, payout, history, ticks, candles;
5. WebSocket connect/reconnect;
6. feature/indicator;
7. AI provider health dan JSON validation;
8. consensus/signal expiry;
9. Risk Engine rejection/approval fixture;
10. backtest DEMO dan bukti tidak ada broker submit;
11. auto-trade lifecycle memakai fake/DEMO sesuai runbook;
12. journal/statistics;
13. emergency stop.

Tidak ada automated test REAL.

## Perintah quality gate target

Perintah berikut akan tersedia setelah bootstrap:

```bash
# Backend lint/type/test
uv run ruff check .
uv run mypy src
uv run pytest -q

# Flutter
flutter analyze
flutter test

# Security/dependency checks
gitleaks detect
pip-audit
```

CI wajib menolak:

- secret yang terdeteksi;
- test yang memanggil REAL broker;
- import UI langsung ke PocketOptionAPI;
- import AI/MCP langsung ke raw broker client;
- backtest yang memanggil broker submit;
- lint/type/schema/migration/test failure.

## Urutan implementasi

| Phase | Hasil |
| --- | --- |
| 1 | Architecture, tree, README, domain contract |
| 2 | PocketOption Broker Adapter dan DEMO lifecycle |
| 3 | Market data, WebSocket, heartbeat, reconnect |
| 4 | Database, migration, repository, mode isolation |
| 5 | Feature, indicators, signal, expiry |
| 6 | LiteLLM, Ollama, two analysts, consensus |
| 7 | MCP Trading Server |
| 8 | Risk Engine, Execution Engine, Auto Trade, Emergency Stop |
| 9 | NautilusTrader backtest dan analytics |
| 10 | Flutter Android/Web terhadap API/WS nyata |
| 11 | Journal dan statistics |
| 12 | Unit/integration/contract/e2e test |
| 13 | Android APK debug/release build |
| 14 | Flutter Web release build |

Phase berikutnya dimulai dari domain ports dan `PocketOptionBrokerAdapter` DEMO, bukan dari UI kosong. Native APK/EXE harus dibuild pada mesin yang sudah memasang Flutter, Android SDK, dan (untuk Windows) Visual Studio C++ desktop tools.

## Kriteria selesai akhir

Sistem dianggap mencapai target hanya jika:

- Android dan Web dapat memakai API/WebSocket yang sama;
- DEMO dan REAL benar-benar terisolasi;
- koneksi, reconnect, health, dan reconcilation pass;
- semua entry melewati consensus, risk, dan execution;
- AI failure selalu fail-closed;
- signal expired tidak dapat dieksekusi;
- tidak ada Martingale;
- backtest hanya DEMO-gated, isolated, dan tidak mengirim order;
- journal/analytics bersumber dari settlement yang terverifikasi;
- emergency stop bekerja;
- automated tests tidak pernah menggunakan REAL;
- secret scanning, migration, build Android, dan build Web pass.

## Referensi

- [PocketOptionAPI-v2](https://github.com/Mastaaa1987/PocketOptionAPI-v2) — referensi konektor tidak resmi;
- [NautilusTrader](https://github.com/nautechsystems/nautilus_trader) — fondasi event-driven/backtest;
- [LiteLLM](https://github.com/BerriAI/litellm) — LLM gateway/provider abstraction;
- [Ollama](https://github.com/ollama/ollama) — optional local LLM runtime;
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk) — SDK server/client MCP;
- [MCP server guide](https://modelcontextprotocol.io/docs/develop/build-server) — pola pembangunan server.
