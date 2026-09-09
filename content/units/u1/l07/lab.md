# Lab 1.7 — Instrument a tool call through rejection and auto-approve

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: walk one tool call (here: `platform__shell`) through every checkpoint,
then prove you can predict the bucket it lands in under three different
postures — including a security finding.

## Step 1 — Read the pipeline modules (15 min)

Open these in order and write a 1-line role for each into `l07-tool-trace.md`:

1. `crates/goose-provider-types/src/goose_mode.rs:22` — copy the four variants
   with their `strum` messages (the messages are the UI truth).
2. `crates/goose/src/tool_inspection.rs:57` — which inspectors does
   `ToolInspectionManager` hold, and what does `inspect_tools` return per
   request?
3. `crates/goose/src/permission/permission_judge.rs:189` — copy the
   `PermissionCheckResult` struct fields verbatim.
4. `crates/goose/src/security/security_inspector.rs:57` — the `ToolInspector`
   impl: what does a *finding* look like (type + severity)?

## Step 2 — The mode gate (5 min)

`crates/goose/src/agents/agent.rs:2817`. In your notes: what happens to every
tool request in Chat mode, copied from the code. Is the security inspector
still consulted in Chat mode? (Trace it — the answer is in the branch
structure.)

## Step 3 — Predict the buckets (15 min)

For the same tool call (`developer__shell`, `args: ["ls", "-la"]`), fill this
table in `l07-tool-trace.md`; every cell needs the deciding code evidence:

| Mode | Inspection outcome (who returns what) | Bucket | Next stop |
|------|----------------------------------------|--------|-----------|
| Auto | | | dispatch |
| Approve | | needs_approval | confirmation UI |
| SmartApprove (no findings) | | | |
| SmartApprove (security finding on args) | | | |
| Chat | (gate hits first) | skipped | synthetic skip |

For the security-finding row: open `crates/goose/src/security/patterns.rs`
(signature/pattern definitions) and name one real pattern class that
`SecurityInspector` would flag if the args were adversarial instead of `ls`.

## Step 4 — Rejection and the model (10 min)

1. `crates/goose/src/agents/tool_execution.rs:135` — copy `DECLINED_RESPONSE`
   and `CHAT_MODE_TOOL_SKIPPED_RESPONSE` text.
2. Trace where a *denied/declined* result re-enters the conversation (search
   for the decline handling in `tool_confirmation_coordinator.rs` /
   `ops_toolcalling.rs`). In your notes: what role and block type the rejection
   becomes, and why the model must receive it (not silently drop).
3. File the equivalent state-machine path: `ops_toolcalling.rs`'s
   `ToolApprovalOperation` (find it in `state_machine/`): one paragraph mapping
   judge/buckets/confirmation into that path — the parity check.

## Step 5 — The one-paragraph verdict (5 min)

In `l07-tool-trace.md`: "Which posture do you recommend to an admin deploying
an untrusted-extension environment, and which single inspector would you
strengthen?" Cite the module you'd change.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Open `crates/goose/src/config/permission.rs`. Write the JSON/YAML shape of an
  auto-approve rule for one tool in your notes (read the `PermissionConfig`
  struct fields first).
- Grep `ActionRequiredData::ToolConfirmation` in `crates/goose/src` — one
  sentence on where the in-conversation confirmation block (l07 theory
  "where it's heading") is constructed today.