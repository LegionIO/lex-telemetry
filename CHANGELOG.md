# Changelog

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
