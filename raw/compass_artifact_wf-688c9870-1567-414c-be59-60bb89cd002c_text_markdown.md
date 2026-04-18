# Building a self-hosted event monitoring system: a complete technical blueprint

**The optimal stack for a 2–3 user self-hosted monitoring system combines n8n as the workflow orchestrator, Changedetection.io for web change detection, Miniflux for RSS aggregation, FastAPI as the Python backend, and React-Admin for the dashboard — all deployable via Docker Compose on a $10–20/month VPS with 4 GB RAM.** This architecture covers news, e-commerce prices, financial data, and government announcements while delivering alerts through Telegram and a web UI. The total recurring cost for external services can stay under $5/month by leveraging generous free API tiers and GPT-4o-mini for content classification at $0.05/day.

---

## The open-source monitoring toolkit already exists — you just need to assemble it

Four mature open-source projects cover the core monitoring use cases. None solves the full problem alone, but together they form a powerful foundation.

### Changedetection.io — the backbone of web monitoring

**Changedetection.io** (github.com/dgtlmoon/changedetection.io, **~30,400 stars**) is the clear leader for self-hosted web change detection. It monitors any webpage, extracts specific elements via CSS/XPath/JSONPath selectors, and triggers alerts when content changes. Key capabilities include conditional triggers (e.g., "alert only when price drops below $X"), PDF change tracking, form interaction via Browser Steps, and support for **90+ notification channels** through the Apprise library — including Telegram, Slack, Discord, email, and webhooks.

Playwright support comes via a sidecar Docker container (`dgtlmoon/sockpuppetbrowser`), enabling JavaScript-rendered page monitoring. The full REST API allows programmatic management of watches, making integration with n8n straightforward. The main limitation is that it's essentially **single-user** — there's no built-in multi-user or team collaboration. For 2–3 users, this is workable: everyone shares the same instance, and tag-based organization keeps watches separated.

Resource usage is modest: **~256 MB RAM** without Playwright, rising to **~1–1.5 GB** with the Playwright sidecar.

### Miniflux — the API-first RSS aggregator

For RSS and news feed monitoring, **Miniflux** (github.com/miniflux/v2, **~7,500 stars**) stands out as the best choice for programmatic integration. Written in Go as a single binary, it delivers a clean REST API with Python and Go client libraries, native webhook support that fires on new entries, and runs on as little as **~80 MB RAM** plus PostgreSQL. It supports 25+ third-party integrations including Telegram, Discord, and Ntfy.

The comparison with alternatives is decisive: **FreshRSS** (~10,500 stars) has a richer extension ecosystem (30+ extensions including an OpenAI/Ollama article summarizer) and multi-user support, but lacks a dedicated REST API — it relies on Google Reader and Fever APIs designed for mobile clients. **Tiny Tiny RSS** (~9,000 stars) has the strongest built-in article filtering and scoring system, but its documentation is scattered and its maintainer is notoriously difficult. For a system where feeds need to be processed programmatically, Miniflux's webhooks and API make it the clear winner.

### Huginn — persistent monitoring agents

**Huginn** (github.com/huginn/huginn, **~48,800 stars**) provides 60+ agent types that create and consume events in directed acyclic graphs. Its WebsiteAgent, RssAgent, IMAPFolderAgent, and ChangeDetectorAgent are directly relevant. Unlike n8n, Huginn agents maintain **persistent state** between runs, making them better suited for long-running monitoring where context matters.

Huginn complements rather than replaces n8n. Use Huginn for persistent scraping and monitoring agents, then feed their events into n8n for complex workflow orchestration and integrations. The tradeoff: Huginn requires **512 MB–1 GB RAM**, uses a Ruby/Rails stack, has no visual workflow editor, and runs on a rolling-release model with no formal versioning.

### PriceBuddy — dedicated price tracking

For e-commerce price monitoring specifically, **PriceBuddy** (github.com/jez500/pricebuddy, **~850 stars**) offers price history charts, multi-retailer tracking, target price alerts, and universal store support via configurable CSS selectors. Built on Laravel + Filament with Docker Compose deployment. Alternatively, Changedetection.io itself can handle price monitoring through conditional triggers and JSON/XPath filtering — simpler if you don't need historical price charts.

---

## n8n serves as a capable orchestration layer with some key limitations

n8n provides the glue connecting all components. Its built-in node library covers most integration needs, and its AI capabilities are surprisingly deep.

### Built-in nodes that matter for monitoring

The **Schedule Trigger** node supports cron expressions with seconds-level precision. The **RSS Feed Trigger** polls feeds at configurable intervals (minimum one minute) and detects new entries. The **HTTP Request** node supports all authentication methods including OAuth2/PKCE and can import cURL commands directly. The **Webhook** node creates custom HTTP endpoints with response streaming, JWT authentication, and IP whitelisting. The **IMAP Email Trigger** monitors mailboxes using IMAP IDLE for near-real-time detection, though community reports note **reliability issues** that require configuring forced reconnection intervals.

For Telegram, n8n offers **22 operations** including sending messages with inline keyboards, editing messages, sending media, and handling callback queries. The Telegram Trigger node listens for incoming messages, commands, and callback queries via webhooks.

The **AI node ecosystem**, built on LangChain, natively supports OpenAI, Anthropic, Google Gemini, Ollama, Mistral, HuggingFace, and Cohere. The dedicated **Text Classifier** node accepts category definitions and routes content through a connected LLM — purpose-built for the content classification use case. Vector store nodes (Pinecone, Qdrant, Chroma) enable RAG pipelines if needed.

### What n8n lacks — and how to work around it

**No native browser automation.** Community nodes fill this gap: `n8n-nodes-playwright` (github.com/toema/n8n-playwright) provides multi-browser headless automation with custom script support, though it requires **~1 GB disk** for browser binaries. Alternatively, run Browserless alongside n8n and call it via HTTP Request nodes.

**No native change detection.** Implement it with `$getWorkflowStaticData('global')` to store previous page state, compare with current content using Code nodes, and trigger alerts on changes. Or simply use Changedetection.io's webhooks to trigger n8n workflows.

**No negative monitoring.** Implement a heartbeat/watchdog pattern: Workflow A writes a timestamp on successful completion; Workflow B runs on a separate schedule, checks the timestamp, and alerts if it's older than expected. External services like Healthchecks.io can also serve this purpose — have n8n ping them on success, and they alert on missed pings.

**n8n has native MCP support** via the MCP Server Trigger and MCP Client Tool nodes. The MCP Client can connect to external MCP servers like Microsoft's Playwright MCP (github.com/microsoft/playwright-mcp, **27,100 stars**), enabling AI agents within n8n to drive browser automation through the Model Context Protocol.

### Deployment sizing for a small team

A production n8n instance with PostgreSQL requires a minimum of **2 vCPU and 4 GB RAM**. n8n itself consumes 300–500 MB at idle, spiking to 1–2 GB during complex executions. PostgreSQL adds ~512 MB. For 2–3 users with dozens of workflows, a single instance in regular mode (not queue mode) is sufficient. Queue mode — which splits the workload across a main instance, Redis, and worker processes — is only needed beyond ~100,000 executions/month.

Custom n8n nodes are written in **TypeScript** using the `INodeType` interface. Scaffold new nodes with `npm create @n8n/node`, develop with hot reload via `npm run dev`, and publish to npm. Declarative-style nodes (for REST API wrappers) can be built in a few hours; programmatic nodes with complex logic take longer.

---

## Three tiers of LLM classification from $0.05/day to free

Content classification — determining whether a news article, price change, or government announcement is relevant — can be approached at three cost/complexity tiers.

### Cloud APIs: cheapest and fastest to implement

**GPT-4o-mini** at **$0.15/MTok input and $0.60/MTok output** is the cost leader. Processing 500 articles/day (estimating ~500 input tokens + ~50 output tokens per article) costs approximately **$0.05/day — about $1.50/month**. Latency is **0.3–1.0 seconds** per classification. Integration is trivial via n8n's built-in Text Classifier node connected to the OpenAI Chat Model node.

**Claude Haiku 4.5** costs more at $1.00/$5.00 per MTok but delivers higher quality for nuanced classification. The same 500-article workload runs **~$0.38/day**. Anthropic's Batch API cuts this by 50%, and prompt caching reduces cached input tokens by 90%.

OpenAI's newer **GPT-5 nano** ($0.05/$0.40 per MTok) pushes costs even lower at ~$0.03/day for 500 articles, though quality data is still emerging.

### Local LLMs via Ollama: zero recurring cost

For teams wanting full data privacy or zero API costs, **Qwen 3.5** models (0.8B to 9B parameters, Apache 2.0 license) are the current best option for local deployment. The **4B model fits in ~3.5 GB RAM** at Q4 quantization and delivers 8–15 tokens/second on CPU — enough for a **2–5 second classification latency**. The "non-thinking" mode provides fast, deterministic outputs ideal for classification tasks.

**Llama 3.2 3B** and **Phi-4 Mini 3.8B** are strong alternatives. All run on a server with **16–32 GB RAM and no GPU** via Ollama, which exposes an OpenAI-compatible API that n8n's Ollama node connects to natively. At 500 articles/day with 5-second average processing, total classification time is ~42 minutes — easily handled in 2–3 batch runs.

### Fine-tuned BERT models: fastest and most accurate

Research consistently shows that **fine-tuned encoder models outperform zero-shot LLMs** for text classification tasks. **ModernBERT** (huggingface.co/answerdotai/ModernBERT-base) brings an updated architecture with 8,192-token context and achieves **10–200ms inference on CPU** with ~400 MB memory. **DistilBERT** with ONNX quantization has been demonstrated at **under 10ms per classification** in production.

The tradeoff: fine-tuning requires **200+ labeled examples** and ML engineering effort. But the result is a model that processes **100+ classifications per second** on CPU — three orders of magnitude faster than generative LLMs — at zero ongoing cost. For a monitoring system that will process thousands of items daily for months, this investment pays off quickly.

| Approach | Latency | Daily cost (500 items) | Setup effort |
|----------|---------|----------------------|--------------|
| GPT-4o-mini API | 0.3–1.0s | ~$0.05 | Minutes via n8n |
| Claude Haiku 4.5 | 0.5–1.5s | ~$0.38 | Minutes via n8n |
| Qwen 3.5 4B (Ollama) | 2–5s on CPU | $0 | ~1 hour |
| Fine-tuned ModernBERT | 10–200ms | $0 | Days (needs training data) |

**All approaches achieve sub-10-second response times**, satisfying time-critical monitoring requirements. The pragmatic path: start with GPT-4o-mini for immediate functionality, then migrate to a local model or fine-tuned BERT once classification patterns stabilize.

---

## Data sources offer surprising depth on free tiers

### News APIs: Currents API leads on free access

**Currents API** (currentsapi.services) provides the most generous free tier: **1,000 requests/day** with real-time news from 17,000+ sources across 70+ countries — no credit card required. **TheNewsAPI** (thenewsapi.com) offers the best affordable paid tier at **$19/month** for 2,500 requests/day with 40,000+ sources. **NewsAPI.org**, despite its popularity, restricts free-tier articles to a 24-hour delay and prohibits production use — its useful Business plan starts at **$449/month**, making it impractical for this budget.

For financial news specifically, **Finlight.me** offers 5,000–10,000 free requests/month. **NewsData.io** provides 200 credits/day across 87,000+ sources with commercial use allowed on the free tier.

### Financial APIs: FRED and Finnhub are exceptionally generous

**FRED API** (Federal Reserve Economic Data) is completely free with **120 requests/minute** across 800,000+ economic time series — GDP, inflation, unemployment, interest rates, and more. The Python `fredapi` library wraps it with pandas DataFrames.

**Finnhub** stands out with **60 API calls/minute** on its free tier, WebSocket support for real-time data on 50 symbols, and unique alternative datasets including **congressional trading data, Senate lobbying records, and insider sentiment scores**. **Alpha Vantage** is more restrictive at only 25 requests/day on its free tier. **Polygon.io** offers institutional-grade data quality but limits free access to 5 calls/minute with end-of-day data only.

### Government data: entirely free, no authentication needed

The **Federal Register API** (federalregister.gov/developers) provides all US regulatory documents since 1994 — proposed and final regulations, executive orders, presidential documents — with **no API key required**, full-text search, and JSON/CSV output. **Congress.gov API** covers bills, amendments, committee reports, and Congressional Record with a free api.data.gov key. **Regulations.gov API** adds federal regulatory comments and dockets. UK's **data.gov.uk** offers 47,000+ datasets without authentication. The **EU Open Data Portal** (data.europa.eu) similarly requires no auth.

### Web scraping with Playwright: stealth is essential

The **playwright-stealth** Python package patches headless browser fingerprints — disabling `navigator.webdriver`, removing "HeadlessChrome" from User-Agent, and mocking browser plugins. However, it **does not fix TLS/JA3 fingerprinting** or IP reputation issues. For sites with aggressive anti-bot measures (Cloudflare, DataDome), self-hosted scraping requires residential proxies or a service like **Browserless.io**, which offers **1,000 free units/month** with CAPTCHA solving and residential proxies, scaling to $25/month for 20,000 units.

Practical polling frequencies: news sites every 15–30 minutes, government notices every 1–4 hours, price monitoring every 1–6 hours. Always add **±20–30% jitter** to request intervals and implement exponential backoff on 429/403 responses.

### Email monitoring: imap_tools simplifies everything

For IMAP email monitoring in Python, **imap_tools** (`pip install imap-tools`) provides the cleanest interface — auto-parsing attachments, HTML, and plain text with built-in search criteria. For newsletter content extraction, chain **readability-lxml** (Mozilla's Readability algorithm) to extract main content, then **trafilatura** for metadata and clean text output. n8n's IMAP Trigger uses IMAP IDLE for near-real-time detection but has known reliability issues; the forced reconnection interval parameter is essential.

---

## Architecture: PostgreSQL at the center, SSE for real-time

The recommended architecture uses **Docker Compose** with five services: PostgreSQL (shared by n8n and FastAPI), n8n, FastAPI, the React-Admin frontend, and optionally Redis (only if n8n queue mode is needed later).

### Communication patterns

**n8n → FastAPI**: n8n's HTTP Request node calls FastAPI endpoints on the internal Docker network (`http://fastapi-service:8000/endpoint`). **FastAPI → n8n**: POST to n8n's Webhook Trigger nodes. The n8n REST API (`POST /api/v1/workflows/{id}/run`) exists but **cannot pass custom input data** — use webhooks for runtime parameters.

For full Python capability (ML models, complex scraping logic, external libraries), wrap everything in FastAPI endpoints. n8n's native Python support in Code nodes is restricted to the standard library and allowlisted packages.

### Database and real-time delivery

**PostgreSQL** is the only viable choice — n8n requires it for production, and sharing it with FastAPI eliminates an extra dependency. At 100 monitored sources with 5-minute check intervals, expect **~28,800 rows/day** of check results. With 30-day retention, that's ~860,000 rows — trivial for PostgreSQL.

For pushing alerts to the web UI, **Server-Sent Events (SSE)** beats WebSockets. The monitoring dashboard is fundamentally unidirectional (server pushes alerts to clients); user actions like "acknowledge" or "snooze" are occasional REST API calls. SSE auto-reconnects natively in browsers, works over standard HTTP, requires no special proxy configuration, and FastAPI supports it easily with `StreamingResponse`.

A message queue is **unnecessary for 2–3 users**. FastAPI's built-in `BackgroundTasks` handles async processing. Add Redis only if you later need n8n queue mode for horizontal scaling.

### Resource requirements

| Component | RAM | Notes |
|-----------|-----|-------|
| PostgreSQL | ~256 MB | Shared by n8n and FastAPI |
| n8n | 512 MB–1 GB | Spikes during complex executions |
| FastAPI | ~128 MB | Lightweight |
| Frontend | ~128 MB | Static build served by nginx |
| Ollama (optional) | 2–6 GB | Only if running local LLM |
| Changedetection.io | 256 MB–1.5 GB | Higher with Playwright sidecar |

**Without local LLM**: a **4 GB RAM, 2 vCPU VPS** ($10–20/month on Hetzner or Contabo) handles everything comfortably. **With Ollama**: bump to 8–16 GB RAM.

---

## Frontend and Telegram: start simple, evolve as needed

### React-Admin is the sweet spot

**React-Admin** (github.com/marmelab/react-admin) connects directly to FastAPI REST endpoints and provides CRUD operations, filters, pagination, real-time updates, and 230+ components out of the box. A basic admin interface takes **~11 lines of configuration code**. Time to functional MVP: **3–5 days** for a developer with React experience.

For a faster prototype, **Streamlit** gets a read-only dashboard running in **1–2 days** with pure Python. It handles data visualization and PostgreSQL queries well but struggles with real-time updates (no native SSE/WebSocket support) and is poorly suited for CRUD-heavy admin panels. Use Streamlit for quick data exploration; build the production dashboard in React-Admin.

### Telegram: a hybrid approach works best

**Start with n8n's Telegram nodes** for outbound alerts. The Telegram node supports HTML formatting, inline keyboards with callback buttons (Acknowledge, Snooze, Open Dashboard), media attachments, and typing indicators — all configured visually without code.

For inbound command handling (configuring monitoring rules via chat, multi-step conversations), graduate to **python-telegram-bot** (github.com/python-telegram-bot/python-telegram-bot, v22.7) running as a separate FastAPI-adjacent service. It provides ConversationHandler for stateful dialogs, a built-in rate limiter, and a JobQueue for scheduled tasks. Choose it over aiogram for its superior documentation and larger community — performance differences are irrelevant at 2–3 users.

**Alert formatting best practices**: Use HTML parse mode over MarkdownV2 to avoid escaping headaches. Structure alerts with emoji indicators (🚨 for critical, ⚠️ for warnings, ✅ for resolved), bold key fields, and inline keyboard buttons for one-tap actions. Telegram's **4,096-character message limit** means long content should link to the web dashboard rather than being included in full.

---

## Conclusion: the practical implementation path

The core insight from this research is that **every component of this system already exists as a mature open-source tool** — the engineering challenge is integration, not invention. The recommended implementation order:

1. **Week 1**: Deploy n8n + PostgreSQL + Changedetection.io via Docker Compose. Configure Changedetection.io watches for target pages, connect notifications to n8n via webhooks, and set up n8n's Telegram node for alerts. This alone delivers a functional monitoring system.

2. **Week 2**: Add Miniflux for RSS feed monitoring with webhooks feeding into n8n. Integrate GPT-4o-mini via n8n's Text Classifier node to filter relevant content. Connect Currents API and FRED API for news and financial data monitoring.

3. **Week 3**: Build the FastAPI backend for custom monitoring rules storage and the React-Admin dashboard. Implement SSE for real-time alert delivery to the web UI.

4. **Future**: Migrate classification to a local model (Qwen 3.5 via Ollama) or fine-tuned ModernBERT once classification patterns are established. Add Playwright-based scraping for JavaScript-heavy targets that Changedetection.io's basic fetcher can't handle.

The total stack — Changedetection.io, Miniflux, n8n, FastAPI, React-Admin, PostgreSQL — runs on a **single 4 GB VPS** at roughly **$15/month** including the VPS, Currents API (free), and GPT-4o-mini (~$1.50/month). Every component is open-source, self-hosted, and replaceable without architectural changes.