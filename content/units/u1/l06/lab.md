# Lab 1.6 — Read one full provider and answer "where would streaming break"

Timebox: 40-50 min. PowerShell 5.1, goose checkout at `$env:GOOSE_REPO`.

Goal: prove you can read a production provider end-to-end and identify the
stream-fragmentation failure modes with citations.

## Step 1 — The trait contract (10 min)

Open `crates/goose-provider-types/src/base.rs`. In `l06-provider-notes.md`:

1. Copy the signature of `stream` (line ~477) and `complete` (~485).
2. List the default-provided methods (the ones with bodies in the trait):
   `complete`, `get_context_limit`, `retry_config`, `fetch_supported_models`.
   For each, one line: who overrides it and why (search implementors with
   `rg "fn get_context_limit" crates\goose-providers crates\goose\src`).
3. What does `get_context_limit` fall back to (trace into
   `crates/goose-provider-types/src/context_limit.rs:9`'s resolver — find the
   default value the resolver returns for an unknown provider).

## Step 2 — Read OpenAI's stream() (15 min)

Open `crates/goose-providers/src/openai.rs`. Around line 787 find `async fn
stream`. Answer in your notes with line evidence:

1. What two payload flavors does `stream_for_model` choose between?
2. Where in the chunk-processing loop does a tool-call delta get accumulated —
   and how is the *split arguments* case handled (arguments spread over
   multiple deltas)?
3. Where does `ProviderUsage` get attached to the final message? Which request
   option turns usage on?

## Step 3 — The envelope layer (10 min)

Open `crates/goose-provider-types/src/formats/openai.rs:201` (`format_messages`):

1. Which goose block kinds does it map into OpenAI `messages` array items?
2. Find `merge_split_tool_call_messages` (line ~566). What input shape is it
   repairing, and what would the model receive if the repair didn't exist?

## Step 4 — Usage + cost layers (10 min)

1. `crates/goose-provider-types/src/conversation/token_usage.rs:93` — list the
   fields of `Usage`. What do the two cache-token fields count?
2. `crates/goose/src/providers/canonical_cost.rs:37` — read `estimate_model_cost`.
   Write the lookup order: where does it get prices, and what happens for an
   unknown model?
3. `crates/goose/src/token_counter.rs:215` — what is `create_token_counter`
   loading, and which callers use it (grep the call)?

## Step 5 — "Where would streaming break" (10 min)

Write the answer paragraph in `l06-provider-notes.md`: pick three failure modes
for THIS provider's stream path (e.g. tool-call args split across chunk
boundaries at a retry, usage arriving after the final chunk, an assistants-API
message that returns two messages for one request). For each: what breaks
(behaviorally), where in openai.rs/formats the code would need to change, and
what test you would write. Keep each to 3 sentences.

## Verification

```powershell
powershell -File verify.ps1 -GooseRepo $env:GOOSE_REPO
```

Expect `VERIFY PASSED`.

## Homework

- Grep `impl Provider for` across `crates/goose-providers/src` — count the
  implementations. Pick the smallest and write one sentence on what it does
  *not* implement (inherits from defaults).
- Find `provider_session_id`/`resume` usage in agent.rs (l04 setup). One
  sentence: why do providers need to resume a *server-side* session?