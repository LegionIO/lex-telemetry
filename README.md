# lex-telemetry

Session log analytics pipeline for LegionIO. Ingests AI tool session logs (Claude Code JSONL),
normalizes events, scrubs sensitive content, computes local stats, and publishes operational
telemetry to AMQP for central consumption.

## Features

- **Parsers**: Claude Code JSONL (extensible to Codex, legion-chat)
- **Scrubber**: Whitelist per tool, 3 levels (minimal/standard/paranoid), PII detection
- **EventStore**: In-memory buffer (10k cap) with pending queue
- **Stats**: Per-session and cross-session analytics
- **AMQP Publishing**: Telemetry events to `telemetry.sessions` exchange
- **Collector**: Auto-discovers session files in `~/.claude/projects/`

## CLI

```bash
legion telemetry stats              # Aggregate stats across sessions
legion telemetry stats <session_id> # Per-session breakdown
legion telemetry ingest <path>      # Manual file ingestion
legion telemetry status             # Buffer health and publisher state
```

## Installation

Add to your Gemfile:

```ruby
gem 'lex-telemetry'
```

## Development

```bash
bundle install
bundle exec rspec     # 60 specs
bundle exec rubocop   # 0 offenses
```

## License

MIT
