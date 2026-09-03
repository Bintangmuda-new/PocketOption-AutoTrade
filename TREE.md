# BM Future PO AutoTrade AI — Project Tree

Status: **Flutter client source + web/PWA vertical slice + broker-backed AI/Risk/Auto Trade boundary**  
Root project: `bmfuture-po-autotrade/`

Tree ini adalah target struktur implementasi. Client web/PWA dan source client Flutter tersedia; backend broker DEMO, market normalization, indicators, LiteLLM boundary, consensus, risk, execution, MCP read-only tools, SQLite journal, dan statistics tersedia dengan fail-closed guard. Full historical Nautilus adapter dan native toolchain build tetap bertahap.

## 1. Root tree

```text
bmfuture-po-autotrade/
├── README.md
├── ARCHITECTURE.md
├── TREE.md
├── LICENSE
├── SECURITY.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── .editorconfig
├── .gitignore
├── .gitattributes
├── .env.example
├── .env.test.example
├── docker-compose.yml
├── docker-compose.test.yml
├── pyproject.toml
├── Makefile
├── Taskfile.yml
├── apps/
├── backend/
├── mcp/
├── contracts/
├── tests/
├── scripts/
├── docker/
├── docs/
├── data/
└── infra/
```

`data/` hanya untuk fixture, sample historical data, dan local cache yang sengaja diizinkan. Credential, SSID, session, token, cookie, dan API key tidak boleh berada di tree atau Git.

## 2. Web dashboard yang sudah dibuat

```text
apps/
└── web_dashboard/
    ├── README.md
    ├── package.json
    ├── package-lock.json
    ├── tsconfig.json
    ├── tsconfig.app.json
    ├── tsconfig.node.json
    ├── vite.config.ts
    ├── index.html
    ├── .gitignore
    ├── src/
    │   ├── main.tsx
    │   ├── App.tsx
    │   ├── data.ts
    │   ├── icons.tsx
    │   └── styles.css
    └── dist/                 # output build; dihasilkan npm run build
```

Web dashboard ini adalah implementasi nyata yang dapat dijalankan di browser atau di-install sebagai PWA. Scanner/chart memakai fixture yang diberi label dan execution broker dikunci; koneksi DEMO hanya melewati FastAPI.

## 3. Flutter application

```text
apps/
└── flutter_app/
    ├── README.md
    ├── pubspec.yaml
    ├── pubspec.lock
    ├── analysis_options.yaml
    ├── l10n.yaml
    ├── android/
    │   ├── app/
    │   └── gradle/
    ├── web/
    ├── test/
    │   ├── unit/
    │   ├── widget/
    │   └── golden/
    ├── integration_test/
    └── lib/
        ├── main.dart
        ├── app.dart
        ├── bootstrap.dart
        ├── core/
        │   ├── config/
        │   │   ├── app_config.dart
        │   │   └── environment.dart
        │   ├── routing/
        │   │   └── app_router.dart
        │   ├── networking/
        │   │   ├── api_client.dart
        │   │   ├── websocket_client.dart
        │   │   ├── api_error.dart
        │   │   └── auth_interceptor.dart
        │   ├── storage/
        │   │   ├── secure_storage.dart
        │   │   └── local_preferences.dart
        │   ├── state/
        │   │   ├── app_scope.dart
        │   │   └── connection_scope.dart
        │   ├── models/
        │   ├── generated/
        │   ├── theme/
        │   │   ├── app_theme.dart
        │   │   ├── color_tokens.dart
        │   │   ├── spacing_tokens.dart
        │   │   └── typography_tokens.dart
        │   ├── widgets/
        │   │   ├── responsive_shell.dart
        │   │   ├── status_badge.dart
        │   │   ├── mode_switcher.dart
        │   │   ├── realtime_indicator.dart
        │   │   └── error_state.dart
        │   └── utils/
        └── features/
            ├── dashboard/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── market/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── signals/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── trade/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── auto_trade/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── backtest/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── journal/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── statistics/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── ai_engine/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── strategies/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── connection/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            ├── settings/
            │   ├── data/
            │   ├── domain/
            │   └── presentation/
            └── logs/
                ├── data/
                ├── domain/
                └── presentation/
```

### Aturan Flutter

- satu codebase untuk Android dan Web;
- `presentation` tidak mengimpor package broker/backend internal;
- semua data realtime berasal dari REST/WebSocket backend;
- mode REAL, status connection, expiry signal, dan backtest gate berasal dari server;
- chart adalah widget visual, bukan sumber kebenaran market data;
- `core/generated` dihasilkan dari kontrak OpenAPI/event schema, bukan ditulis manual berulang-ulang;
- UI memiliki state loading, empty, stale, degraded, error, reconnect, dan permission denied.

## 4. Backend Python

```text
backend/
├── pyproject.toml
├── requirements.txt
├── requirements-ai.txt
├── requirements-mcp.txt
├── requirements-backtest.txt
├── uv.lock
├── README.md
├── scripts/
│   └── connect_demo.py
├── tests/
│   ├── test_adapter_scope.py
│   ├── test_ai_consensus.py
│   ├── test_risk_and_auto_trade.py
│   └── test_metrics_backtest_mcp.py
├── alembic.ini
├── migrations/
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── src/
│   └── bmfuture/
│       ├── __init__.py
│       ├── broker/
│           └── pocketoption/
│               ├── __init__.py
│               └── adapter.py
        │       ├── main.py
        │       ├── analytics/
        │       │   ├── metrics.py
        │       │   └── feedback.py
        │       ├── ai/
        │       │   ├── models.py
        │       │   ├── ollama.py
        │       │   ├── providers/
        │       │   │   ├── base.py
        │       │   │   └── litellm_provider.py
        │       │   ├── analysts/prompt_analyst.py
        │       │   └── consensus/engine.py
        │       ├── auto_trade/engine.py
        │       ├── backtest/
        │       │   ├── gate.py
        │       │   └── engine.py
        │       ├── execution/engine.py
        │       ├── market/indicators.py
        │       ├── risk/engine.py
        │       └── signals/market_signal_engine.py
│       ├── config/
│       │   ├── settings.py
│       │   ├── enums.py
│       │   ├── secrets.py
│       │   └── validation.py
│       ├── api/
│       │   ├── app.py
│       │   ├── dependencies.py
│       │   ├── errors.py
│       │   ├── middleware.py
│       │   └── v1/
│       │       ├── router.py
│       │       ├── health.py
│       │       ├── accounts.py
│       │       ├── markets.py
│       │       ├── analysis.py
│       │       ├── signals.py
│       │       ├── trades.py
│       │       ├── auto_trade.py
│       │       ├── backtests.py
│       │       ├── journal.py
│       │       ├── statistics.py
│       │       ├── ai.py
│       │       ├── settings.py
│       │       └── logs.py
│       ├── application/
│       │   ├── commands/
│       │   │   ├── account_commands.py
│       │   │   ├── auto_trade_commands.py
│       │   │   ├── trade_commands.py
│       │   │   └── backtest_commands.py
│       │   ├── queries/
│       │   │   ├── account_queries.py
│       │   │   ├── market_queries.py
│       │   │   ├── journal_queries.py
│       │   │   └── statistics_queries.py
│       │   ├── services/
│       │   │   ├── account_service.py
│       │   │   ├── market_service.py
│       │   │   ├── signal_service.py
│       │   │   ├── trade_service.py
│       │   │   ├── auto_trade_service.py
│       │   │   ├── backtest_service.py
│       │   │   └── ai_service.py
│       │   ├── ports/
│       │   │   ├── repositories.py
│       │   │   ├── broker.py
│       │   │   ├── llm.py
│       │   │   ├── event_bus.py
│       │   │   └── clock.py
│       │   └── handlers/
│       ├── domain/
│       │   ├── common/
│       │   │   ├── ids.py
│       │   │   ├── money.py
│       │   │   ├── timestamps.py
│       │   │   ├── errors.py
│       │   │   └── result.py
│       │   ├── accounts/
│       │   │   ├── entities.py
│       │   │   ├── value_objects.py
│       │   │   └── policies.py
│       │   ├── market/
│       │   │   ├── entities.py
│       │   │   ├── value_objects.py
│       │   │   └── policies.py
│       │   ├── ai/
│       │   │   ├── entities.py
│       │   │   ├── schemas.py
│       │   │   └── policies.py
│       │   ├── signals/
│       │   │   ├── entities.py
│       │   │   ├── schemas.py
│       │   │   └── policies.py
│       │   ├── trades/
│       │   │   ├── entities.py
│       │   │   ├── schemas.py
│       │   │   └── state_machine.py
│       │   ├── risk/
│       │   │   ├── entities.py
│       │   │   ├── schemas.py
│       │   │   └── policies.py
│       │   ├── backtests/
│       │   │   ├── entities.py
│       │   │   ├── schemas.py
│       │   │   └── policies.py
│       │   └── journal/
│       │       ├── entities.py
│       │       ├── schemas.py
│       │       └── policies.py
│       ├── broker/
│       │   ├── base.py
│       │   ├── registry.py
│       │   ├── errors.py
│       │   └── pocketoption/
│       │       ├── adapter.py
│       │       ├── client.py
│       │       ├── config.py
│       │       ├── mapper.py
│       │       ├── normalizer.py
│       │       ├── websocket.py
│       │       ├── heartbeat.py
│       │       ├── reconnect.py
│       │       ├── health.py
│       │       ├── redaction.py
│       │       └── fixtures/
│       ├── market/
│       │   ├── data_engine.py
│       │   ├── stream.py
│       │   ├── normalizer.py
│       │   ├── validator.py
│       │   ├── freshness.py
│       │   ├── candle_builder.py
│       │   └── snapshot.py
│       ├── features/
│       │   ├── engine.py
│       │   ├── registry.py
│       │   ├── indicators/
│       │   │   ├── ema.py
│       │   │   ├── sma.py
│       │   │   ├── rsi.py
│       │   │   ├── macd.py
│       │   │   ├── bollinger.py
│       │   │   ├── stochastic.py
│       │   │   ├── adx.py
│       │   │   └── atr.py
│       │   ├── price_action.py
│       │   ├── market_structure.py
│       │   ├── similarity.py
│       │   └── anomaly.py
│       ├── ai/
│       │   ├── engine.py
│       │   ├── prompts/
│       │   │   ├── analyst_1_system.txt
│       │   │   ├── analyst_2_system.txt
│       │   │   └── consensus_system.txt
│       │   ├── analysts/
│       │   │   ├── base.py
│       │   │   ├── technical_analyst.py
│       │   │   └── structure_analyst.py
│       │   ├── consensus/
│       │   │   ├── engine.py
│       │   │   ├── policy.py
│       │   │   └── validator.py
│       │   ├── providers/
│       │   │   ├── base.py
│       │   │   ├── litellm_provider.py
│       │   │   ├── ollama_provider.py
│       │   │   ├── fallback.py
│       │   │   └── health.py
│       │   ├── schemas.py
│       │   ├── redaction.py
│       │   └── health.py
│       ├── signals/
│       │   ├── engine.py
│       │   ├── scanner.py
│       │   ├── ranking.py
│       │   ├── expiry.py
│       │   └── schemas.py
│       ├── strategies/
│       │   ├── base.py
│       │   ├── registry.py
│       │   ├── configs.py
│       │   └── implementations/
│       ├── risk/
│       │   ├── engine.py
│       │   ├── policy.py
│       │   ├── checks.py
│       │   ├── locks.py
│       │   └── no_martingale.py
│       ├── execution/
│       │   ├── engine.py
│       │   ├── intents.py
│       │   ├── idempotency.py
│       │   ├── lifecycle.py
│       │   ├── monitor.py
│       │   ├── reconciliation.py
│       │   ├── auto_trade.py
│       │   └── emergency_stop.py
│       ├── backtest/
│       │   ├── engine.py
│       │   ├── mode_gate.py
│       │   ├── nautilus_bridge.py
│       │   ├── data_feed.py
│       │   ├── execution_model.py
│       │   ├── ai_replay.py
│       │   ├── metrics.py
│       │   └── reports.py
│       ├── journal/
│       │   ├── service.py
│       │   ├── settlement.py
│       │   ├── statistics.py
│       │   └── export.py
│       ├── database/
│       │   ├── base.py
│       │   ├── session.py
│       │   ├── models/
│       │   │   ├── account.py
│       │   │   ├── broker_session.py
│       │   │   ├── market.py
│       │   │   ├── signal.py
│       │   │   ├── ai_analysis.py
│       │   │   ├── trade.py
│       │   │   ├── journal.py
│       │   │   ├── backtest.py
│       │   │   ├── strategy.py
│       │   │   ├── setting.py
│       │   │   └── system_log.py
│       │   ├── repositories/
│       │   │   ├── account_repository.py
│       │   │   ├── market_repository.py
│       │   │   ├── signal_repository.py
│       │   │   ├── trade_repository.py
│       │   │   ├── journal_repository.py
│       │   │   ├── backtest_repository.py
│       │   │   └── settings_repository.py
│       │   └── filters.py
│       ├── websocket/
│       │   ├── manager.py
│       │   ├── topics.py
│       │   ├── envelopes.py
│       │   ├── backpressure.py
│       │   └── resync.py
│       ├── security/
│       │   ├── auth.py
│       │   ├── authorization.py
│       │   ├── secret_store.py
│       │   ├── redaction.py
│       │   ├── rate_limit.py
│       │   └── audit.py
│       ├── workers/
│       │   ├── broker_worker.py
│       │   ├── market_worker.py
│       │   ├── settlement_worker.py
│       │   ├── auto_trade_worker.py
│       │   └── health_worker.py
│       └── observability/
│           ├── logging.py
│           ├── metrics.py
│           ├── tracing.py
│           └── health.py
├── scripts/
│   ├── dev.ps1
│   ├── dev.sh
│   ├── test.ps1
│   ├── test.sh
│   ├── migrate.ps1
│   ├── migrate.sh
│   ├── run_demo_smoke.ps1
│   ├── run_demo_smoke.sh
│   ├── build_android.ps1
│   ├── build_android.sh
│   ├── build_web.ps1
│   └── build_web.sh
└── tests/
    ├── unit/
    ├── integration/
    ├── contract/
    ├── e2e/
    ├── fixtures/
    │   ├── broker_demo/
    │   ├── market/
    │   ├── ai/
    │   └── backtest/
    ├── fakes/
    │   ├── fake_broker.py
    │   ├── fake_llm.py
    │   └── fake_clock.py
    └── conftest.py
```

## 5. MCP server

```text
mcp/
└── trading_mcp/
    ├── README.md
    ├── requirements.txt
    └── server.py
```

MCP mengimpor client application/use-case package yang stabil. MCP tidak mengimpor `broker.pocketoption.client` dan tidak memiliki tool order mentah.

## 6. Contracts

```text
contracts/
├── openapi/
│   └── openapi.yaml
├── events/
│   ├── envelope.schema.json
│   ├── market.schema.json
│   ├── signal.schema.json
│   ├── trade.schema.json
│   └── health.schema.json
├── ai/
│   ├── analyst-output.schema.json
│   └── consensus-output.schema.json
└── database/
    └── data-dictionary.md
```

Semua perubahan API/WS/AI event harus memperbarui schema version dan contract test.

## 7. Docker dan infrastruktur

```text
docker/
├── backend.Dockerfile
├── worker.Dockerfile
├── mcp.Dockerfile
├── postgres-init/
└── healthchecks/
    ├── api.sh
    ├── postgres.sh
    └── redis.sh

infra/
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
├── reverse-proxy/
│   └── nginx.conf
└── deployment/
    ├── README.md
    └── environment-matrix.md
```

`docker-compose.yml` minimalnya memuat API, worker, MCP, PostgreSQL, Redis, dan optional Ollama profile. Credential hanya lewat environment/secret injection.

## 8. Dokumentasi lanjutan

```text
docs/
├── adr/
│   ├── 0001-monorepo.md
│   ├── 0002-account-mode-isolation.md
│   ├── 0003-fail-closed-execution.md
│   ├── 0004-backtest-boundary.md
│   └── 0005-llm-provider-abstraction.md
├── api/
│   ├── rest.md
│   └── websocket.md
├── broker/
│   ├── pocketoption-adapter.md
│   ├── demo-runbook.md
│   ├── real-account-runbook.md
│   └── failure-recovery.md
├── ai/
│   ├── prompts.md
│   ├── provider-matrix.md
│   └── structured-output.md
├── backtest/
│   ├── methodology.md
│   ├── reproducibility.md
│   └── metrics.md
├── operations/
│   ├── runbook.md
│   ├── observability.md
│   └── emergency-stop.md
└── ui/
    ├── information-architecture.md
    └── design-tokens.md
```

## 9. Dependency boundary

```text
Flutter UI
  → generated API/WS client
  → FastAPI
  → application use cases
  → domain ports
  → infrastructure adapters/repositories

AI analysts
  → LLMProvider
  → LiteLLM / Ollama

Backtest
  → historical repository
  → Nautilus bridge
  → isolated simulation/reporting

MCP
  → application use cases only
```

Dependency yang tidak boleh terjadi:

```text
Flutter → PocketOptionAPI-v2
LLM → BrokerAdapter
MCP → raw broker client
Backtest → live ExecutionEngine
Repository → UI widget
```

## 10. Phase creation order

1. Root metadata dan contracts.
2. Domain enums/value objects dan application ports.
3. DEMO adapter + recorded fixtures.
4. Market data + health/reconnect.
5. Database/migrations/repositories.
6. Feature/indicator/signal engine.
7. LLM provider, analysts, consensus.
8. MCP facade.
9. Risk + execution + auto trade.
10. Backtest bridge.
11. REST/WebSocket implementation.
12. Flutter screens dan chart.
13. Journal/statistics.
14. Integration/e2e tests.
15. Android/Web release build.

Tidak boleh membuat UI live yang belum memiliki contract backend dan fixture/test yang jelas.
