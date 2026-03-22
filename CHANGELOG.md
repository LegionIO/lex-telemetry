# Changelog

## [0.1.3] - 2026-03-21

### Added
- `region_metrics` runner method: reports current region, primary, failover, peers, affinity, and is_primary status
- `RegionReporter` actor: publishes region metrics every 120 seconds

## [0.1.2] - 2026-03-20

### Added
- Enterprise privacy mode: `publish_pending` suppresses AMQP publishing when `enterprise_data_privacy` is enabled
- `privacy_mode?` helper checks `Legion::Settings.enterprise_privacy?` with `LEGION_ENTERPRISE_PRIVACY` env fallback

## [0.1.1] - 2026-03-17

### Changed
- Renamed `module Actors` to `module Actor` (singular) in collector and publisher actors
- Updated specs to reference `Actor::Collector` and `Actor::Publisher` accordingly

## [0.1.0] - 2026-03-15

### Added
- TelemetryEvent normalized event shape with 5 event types (tool_call, llm_request, error, session_start, session_end)
- Scrubber with whitelist per tool, 3 levels (minimal/standard/paranoid), PII regex patterns
- Claude Code JSONL parser with incremental byte-offset reads
- Parser base interface for future tool adapters (Codex, legion-chat)
- EventStore: in-memory buffer (10k cap) with pending queue for AMQP
- Stats: session_summary and aggregate_stats computation
- Runner: ingest_session, session_stats, aggregate_stats, telemetry_status, publish_pending, collect
- Publisher actor (Every 60s): flushes pending events to telemetry.sessions AMQP exchange
- Collector actor (Every 300s): scans ~/.claude/projects for session JSONL files
- HighWaterMark: per-file byte offset tracking for incremental ingestion
- AMQP transport: telemetry.sessions exchange (topic), telemetry.sessions.process queue (durable)
