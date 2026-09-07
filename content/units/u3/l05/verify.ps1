<# Goose Contributor Academy - Lab check: u3-l05 Registration & auth
   Checks the echo-reg crate (ProviderDef + config_keys + secret env key),
   the secrets model doc, the OAuth notes, and goose-repo grep evidence.
#>
param(
    [string]$GooseRepo = $env:GOOSE_REPO,
    [string]$LabDir = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$fails = 0
$passes = 0

if (-not $GooseRepo) {
    $GooseRepo = "C:\Users\admin\projects\goose"
    Write-Host "[INFO]  GOOSE_REPO not set; trying default: $GooseRepo"
}

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) {
        Write-Host "[PASS]  $Name"
        $script:passes++
    } else {
        Write-Host "[FAIL]  $Name - $Detail"
        $script:fails++
    }
}

# The registration crate may live directly in LabDir or in LabDir\echo-reg
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "echo-reg"
}

$cargoPath = Join-Path $crateDir "Cargo.toml"
$libPath = Join-Path $crateDir "src\lib.rs"
$cargo = if (Test-Path $cargoPath) { Get-Content $cargoPath -Raw } else { "" }
$lib = if (Test-Path $libPath) { Get-Content $libPath -Raw } else { "" }

# 1. Crate depends on the goose core crate (path dependency)
Check "echo-reg Cargo.toml path-depends on goose" `
    ($cargo -match '\[package\]' -and $cargo -match 'goose\s*=\s*\{') `
    "scaffold echo-reg with a path dependency on crates/goose"

# 2. ProviderDef implemented with from_env
Check "src/lib.rs implements ProviderDef with from_env" `
    ($lib -match 'impl\s+ProviderDef\s+for' -and $lib -match 'fn\s+from_env') `
    "implement ProviderDef per providers/base.rs:31"

# 3. metadata() declares a secret config key
Check "metadata() declares a secret config key (ECHO_API_KEY)" `
    ($lib -match 'ConfigKey' -and $lib -match 'ECHO_API_KEY' -and $lib -match 'true,\s*true') `
    "add ConfigKey::new with required+secret flags per Step 2"

# 4. from_env reads the secret from the environment (no literals)
Check "from_env reads ECHO_API_KEY via std::env::var" `
    ($lib -match 'env::var\("ECHO_API_KEY"\)') `
    "read the credential from the environment"

# 5. Secrets model doc exists with storage/status reasoning
$secretsPath = Join-Path $LabDir "u3-l05-secrets.md"
$secrets = if (Test-Path $secretsPath) { Get-Content $secretsPath -Raw } else { "" }
Check "u3-l05-secrets.md maps the key onto ProviderSecret (storage/status/configured)" `
    ($secrets -match 'status' -and $secrets -match 'configured' -and $secrets -match 'has_secret') `
    "create the secrets model doc from Step 3"

# 6. OAuth notes capture endpoint rules
$oauthPath = Join-Path $LabDir "u3-l05-oauth.md"
$oauth = if (Test-Path $oauthPath) { Get-Content $oauthPath -Raw } else { "" }
Check "u3-l05-oauth.md records HTTPS/loopback rule + OAUTH_MUTEX + streamable_http handshake" `
    ($oauth -match 'loopback' -and $oauth -match 'OAUTH_MUTEX' -and $oauth -match 'streamable_http') `
    "create u3-l05-oauth.md per Step 4"

# 7. Goose-repo evidence: loopback policy + secrets prefix
$hits = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\providers\oauth.rs") -Pattern 'loopback' -ErrorAction SilentlyContinue
$hits2 = Select-String -Path (Join-Path $GooseRepo "crates\goose\src\providers\provider_secrets.rs") -Pattern 'SECRET_STORE_ID_PREFIX' -ErrorAction SilentlyContinue
Check "goose repo: oauth loopback policy + SECRET_STORE_ID_PREFIX found" (($null -ne $hits) -and ($null -ne $hits2)) "grep crates/goose/src/providers/oauth.rs and provider_secrets.rs"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}