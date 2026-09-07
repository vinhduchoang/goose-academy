# Lab 1.11 — Diagnose a seeded production-style incident

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: given a realistic incident log (seeded below), find root cause using the
three altitudes (logs, spans, gen_ai fields) and file the answer with code
evidence.

## Step 1 — Set the scene (5 min)

Read `crates/goose/src/logging.rs:116` (`prepare_log_directory`) and write in
`l11-incident-report.md` the exact directory layout goose uses on this machine
(component + date subdir + file names). This is where you'd go first in a real
incident.

## Step 2 — Load the seeded incident (5 min)

Create the incident log file with:

```powershell
@'
2026-09-08T09:31:05.001Z  INFO goose::agents::agent: reply_stream started session.id=abc123 gen_ai.operation.name="invoke_agent" gen_ai.request.model=claude-sonnet-4-5
2026-09-08T09:31:05.142Z  INFO goose::providers::base: provider resolved name=anthropic
2026-09-08T09:31:07.830Z  WARN goose::otel::otlp: goose otel: OTEL_EXPORTER_OTLP_PROTOCOL is set to a gRPC
2026-09-08T09:31:07.833Z ERROR goose::providers: provider error kind=TimeoutError message="request timed out after 60s" toolspan=developer__shell
2026-09-08T09:31:07.834Z  INFO goose::agents::doctor: ensure_working_provider trying next model
2026-09-08T09:31:08.001Z  INFO goose::agents::doctor: try_other_providers ok=google
'@ | Out-File l11-incident.log -Encoding utf8
```

## Step 3 — Root-cause with code evidence (20 min)

Write answers in `l11-incident-report.md`:

1. Which line is the *smoking gun* — and which code warns exactly like that
   (cite `crates/goose/src/otel/otlp.rs:29`)?
2. What protocol does the exporter expect instead (copy the exact env var and
   value pattern from `otlp.rs` around lines 193-210 and 245-262)?
3. Trace the failure sequence: timeouts → doctor. Open
   `crates/goose/src/doctor.rs:14` — what does `run` do after
   `ensure_working_provider` fails, and how does `try_other_providers` decide
   "ok"? (Copy the relevant condition.)
4. `gen_ai_telemetry.rs:52` (`record_usage`) — why did the ERROR line carry no
   usage fields? (When does the span get usage written?)
5. Was the user's session (abc123) *recoverable* — which module would the user
   click to gather and send support data (cite
   `crates/goose/src/session/diagnostics.rs:153`)?

## Step 4 — The fix + prevention (5 min)

Two parts in the report:

1. The one-command environment fix for the user (PowerShell syntax to set the
   correct exporter protocol for this collector).
2. A 2-line code suggestion: where (file:line region) would you strengthen the
   warning/fallback so misconfigured OTLP never costs a 60s timeout? (Read
   `otlp.rs`'s warning vicinity; propose auto-fallback or a louder log.)
   Describe only — no build required.

## Step 5 — The three altitudes table (5 min)

Close the report with the table: for THIS incident, what did each altitude
contribute to the diagnosis (Logs / Spans / gen_ai fields), one row each with
the concrete line from the log.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- `crates/goose/src/tracing/langfuse_layer.rs:155` — one sentence: under what
  condition does the Langfuse observer come into existence?
- Grep `CAPTURE_MESSAGE_CONTENT_ENV` — write the exact env name and why a
  production deployment might set it to false.