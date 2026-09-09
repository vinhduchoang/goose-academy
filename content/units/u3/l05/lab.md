# Lab 3.5 — Register, configure, secret-manage a provider

Timebox: 40-50 min. PowerShell 5.1, your goose checkout (`$env:GOOSE_REPO`).

```powershell
$env:LAB05 = Join-Path (Get-Location) "goose-labs\u3-l05"
```

## Step 1 — Read the registry and secrets code (10 min)

Read and note (in `u3-l05-notes.md`):

1. `crates/goose/src/providers/provider_registry.rs:12` and `:26` — what does a
   `ProviderConstructor` take, and what does `ProviderEntry` bundle besides the
   constructor?
2. `crates/goose/src/providers/provider_secrets.rs:32` — which two fields let
   the UI answer "configured but no secret stored"?
3. `crates/goose/src/providers/oauth.rs:25` — quote the exact rule about
   which endpoints may not be HTTPS.

## Step 2 — A registration crate (15 min)

Create `echo-reg` (a library crate) that **path-depends on the goose core
crate** and registers your echo:

```powershell
New-Item -ItemType Directory -Force -Path $env:LAB05 | Out-Null
Set-Location $env:LAB05
cargo new --lib echo-reg
Set-Location echo-reg
```

`Cargo.toml`:

```toml
[package]
name = "echo-reg"
version = "0.1.0"
edition = "2021"

[dependencies]
anyhow = "1"
async-trait = "0.1"
futures = "0.3"
goose = { path = "C:/Users/admin/projects/goose/crates/goose" }
goose-providers = { path = "C:/Users/admin/projects/goose/crates/goose-providers" }
```

`src/lib.rs` — implement the registration layer, borrowing shapes from
`crates/goose/src/providers/base.rs:31` and its `ProviderDef` doc:

```rust
use futures::future::BoxFuture;
use goose::providers::base::{ConfigKey, Provider, ProviderDef, ProviderMetadata};
// (adjust import paths to what exists; the traits are goose::providers::base)

pub struct EchoConcierge;

impl goose::providers::base::ProviderDescriptor for EchoConcierge {
    fn metadata() -> ProviderMetadata {
        ProviderMetadata::new(
            "echo",
            "Echo Provider",
            "Answers with the last user message (lab provider)",
            "echo-v1",
            vec!["echo-v1"],
            "https://example.invalid/echo", // model doc link
            vec![ConfigKey::new("ECHO_API_KEY", true, true, None, true)], // env key, required, secret, default=None, primary
        )
    }
}

impl ProviderDef for EchoConcierge {
    type Provider = EchoProvider;

    fn from_env(
        _extensions: Vec<goose::config::ExtensionConfig>,
        _tls: Option<goose::providers::api_client::TlsConfig>,
    ) -> BoxFuture<'static, anyhow::Result<Self::Provider>> {
        Box::pin(async move {
            let api_key = std::env::var("ECHO_API_KEY")
                .map_err(|_| anyhow::anyhow!("ECHO_API_KEY env var is required"))?;
            Ok(EchoProvider { name: "echo".into(), _api_key: api_key })
        })
    }
}
```

Answer in notes (do not guess — check `ProviderMetadata::new` in
`crates/goose-provider-types/src/base.rs`): what does the fifth argument (the
model doc link) get used for in the UI layer?

## Step 3 — Secret management model (10 min)

Map your `ECHO_API_KEY` onto the real secret model. Write a short
`u3-l05-secrets.md`:

- storage choice for an env-var API key (why `ProviderSecretStorage::ProviderCache`
  is wrong for OAuth tokens and env keys usually aren't goose-managed secrets)
- `status`: Unknown — because no `expires_at` is known
- `configured: true`, `has_secret: true`, `can_delete: true` — and one sentence
  per field explaining what a stale value would do in the UI

Cite the enum at `crates/goose/src/providers/provider_secrets.rs:18` and the
struct at line 32.

## Step 4 — OAuth threat-model notes (10 min)

Skim `crates/goose/src/providers/oauth.rs` (first 100 lines suffice) and
`crates/goose/src/providers/oauth_device_flow.rs:1-80`, then answer in
`u3-l05-oauth.md`:

1. Why does `endpoint_transport` reject plain-HTTP non-loopback endpoints?
2. What does the `OAUTH_MUTEX` serialize, and what user-visible bug would
   lack-of-it cause?
3. One sentence: for a *streamable_http extension*, where does goose complete
   the OAuth handshake? (`crates/goose/src/agents/extension_manager.rs:1105`)

## Verification

```powershell
powershell -File verify.ps1 -LabDir $env:LAB05 -GooseRepo $env:GOOSE_REPO
```

## Homework

- `crates/goose/src/providers/provider_registry.rs` — find where `inventory`
  resolvers come from and note what "supports_inventory_refresh" gates.
- Look at `crates/goose/src/providers/private_file.rs` (`write_private_file`) —
  one sentence on how goose writes secret material to disk.