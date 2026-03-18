# lex-telemetry: Session Log Analytics for LegionIO

**Repository Level 3 Documentation**
- **Parent (Level 2)**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Parent (Level 1)**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Core Legion Extension that ingests AI tool session logs (Claude Code JSONL), normalizes events into a common TelemetryEvent shape, scrubs sensitive content, buffers in memory, computes local stats, and publishes operational telemetry to AMQP for central service consumption.

**GitHub**: https://github.com/LegionIO/lex-telemetry
**License**: MIT
**Version**: 0.1.1

## Architecture

```
Legion::Extensions::Telemetry
├── Helpers/
│   ├── TelemetryEvent     # Event shape builder with 5-type validation
│   ├── Scrubber           # Whitelist-based scrubbing (3 levels) + PII regex
│   ├── EventStore         # In-memory buffer (10k cap) + pending queue for AMQP
│   ├── Stats              # session_summary + aggregate_stats computation
│   └── HighWaterMark      # Per-file byte offset tracking for incremental ingestion
├── Parsers/
│   ├── Base               # Parser interface (source_name, can_parse?, parse)
│   └── ClaudeCode         # Claude Code JSONL parser with incremental byte-offset reads
├── Runners/
│   └── Telemetry          # ingest_session, session_stats, aggregate_stats, telemetry_status,
│                          #   publish_pending, collect
├── Actors/
│   ├── Publisher           # Every 60s: flushes pending events to AMQP
│   └── Collector           # Every 300s: scans session directories for new JSONL files
└── Transport/
    ├── Exchanges/Sessions         # telemetry.sessions topic exchange
    ├── Queues/SessionsProcess     # telemetry.sessions.process durable queue
    └── Messages/TelemetryMessage  # Routing key: telemetry.{source}.{event_type}
```

## TelemetryEvent Shape

```ruby
{
  event_type:    :tool_call,      # :tool_call, :llm_request, :error, :session_start, :session_end
  session_id:    "uuid",
  source:        :claude_code,    # :claude_code, :codex, :legion_chat, etc.
  timestamp:     Time,
  tool_name:     "Read",          # nil for non-tool events
  tool_input:    { file_path: "/path/to/file.rb" },  # scrubbed
  duration_ms:   1000,            # computed from tool_use -> tool_result gap
  tokens:        { input: 100, output: 50, cache_read: 200, cache_write: 0 },
  error:         nil,
  metadata:      {}
}
```

## Scrub Levels

| Level | Behavior |
|-------|----------|
| `:minimal` | PII regex only, keeps all tool inputs |
| `:standard` (default) | Whitelist per tool + PII regex |
| `:paranoid` | Strips everything except event_type, tool_name, timestamps, tokens |

## Tool Whitelist (Standard Level)

| Tool | Allowed Keys |
|------|-------------|
| Read | file_path, offset, limit |
| Write | file_path |
| Edit | file_path |
| Glob | pattern, path |
| Grep | pattern, path, include |
| Bash | description, timeout |
| Agent | description, subagent_type |

Unknown tools: all input stripped at standard level.

## Runner Methods

| Method | Purpose |
|--------|---------|
| `ingest_session(file_path:, scrub_level:)` | Parse + scrub + store, returns summary |
| `session_stats(session_id:)` | Per-session breakdown (tool counts, tokens, files, errors) |
| `aggregate_stats` | Cross-session totals (frequencies, error rate, most-read files) |
| `telemetry_status` | Buffer size, pending count, session count, parser list |
| `publish_pending` | Flush pending events to AMQP (called by Publisher actor) |
| `collect` | Scan SCAN_DIRS for new session files (called by Collector actor) |

## Actors

| Actor | Interval | Runner Method |
|-------|----------|--------------|
| Publisher | 60s | publish_pending |
| Collector | 300s | collect |

## Integration Points

- **legion-transport** (optional): AMQP exchange/queue/message for telemetry publishing. If unavailable, events buffer in pending queue.
- **LegionIO CLI**: `legion telemetry stats/ingest/status` subcommands
- **lex-privatecore**: Scrubber carries own PII regex patterns (no hard dependency)

## Design Doc

`docs/plans/2026-03-15-session-log-analytics-design.md`

## Development

```bash
bundle install
bundle exec rspec     # 60 specs
bundle exec rubocop   # 0 offenses
```

---

**Maintained By**: Matthew Iverson (@Esity)
