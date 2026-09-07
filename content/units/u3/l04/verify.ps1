<# Goose Contributor Academy - Lab check: u3-l04 Provider formats + tool-call mapping
   Checks the envelope module (to/from OpenAI tool_calls and Anthropic
   tool_use), round-trip tests, the string-vs-object arguments asymmetry,
   notes, and goose-repo grep evidence.
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

# The echo crate may live directly in LabDir or in LabDir\echo-ext
$crateDir = $LabDir
if (-not (Test-Path (Join-Path $crateDir "Cargo.toml"))) {
    $crateDir = Join-Path $LabDir "echo-ext"
}

$envPath = Join-Path $crateDir "src\envelope.rs"
$libPath = Join-Path $crateDir "src\lib.rs"
$env = if (Test-Path $envPath) { Get-Content $envPath -Raw } else { "" }
$lib = if (Test-Path $libPath) { Get-Content $libPath -Raw } else { "" }

# 1. envelope module exists and is declared
Check "src/envelope.rs exists and is `pub mod`-declared" `
    ((Test-Path $envPath) -and ($lib -match 'pub mod envelope')) `
    "create src/envelope.rs and declare it in lib.rs"

# 2. OpenAI tool_call serializer emits arguments as a JSON STRING
$toOpenAi = if ($env -match 'to_openai_tool_call') {
    $m = [regex]::Matches($env, 'to_openai_tool_call[\s\S]{0,1600}')
    ($m | ForEach-Object { $_.Value }) -join ""
} else { "" }
Check "to_openai_tool_call builds function.arguments as JSON string" `
    ($toOpenAi -match '"function"' -and $toOpenAi -match 'arguments' -and $toOpenAi -match 'to_string') `
    "serialize arguments with serde_json::to_string on the wire"

# 3. OpenAI parser exists and re-parses the arguments string
Check "from_openai_tool_call parses function.arguments" `
    ($env -match 'from_openai_tool_call' -and $env -match 'from_str') `
    "parse the string via serde_json::from_str like openai.rs:777"

# 4. Anthropic tool_use mapping with input-as-object
Check "anthropic tool_use mapping present (type: tool_use + input object)" `
    ($env -match 'tool_use' -and $env -match 'from_anthropic_tool_use') `
    "add to_anthropic_tool_use / from_anthropic_tool_use per Step 3"

# 5. Round-trip + malformed-arguments tests exist
$testFiles = @()
if (Test-Path (Join-Path $crateDir "tests")) {
    $testFiles = Get-ChildItem (Join-Path $crateDir "tests") -Filter *.rs -ErrorAction SilentlyContinue
}
$testText = ""
foreach ($t in $testFiles) { $testText += (Get-Content $t.FullName -Raw) }
if (-not $testText) { $testText = $lib }
$a = $testText -match 'from_openai_tool_call' -or $testText -match 'to_openai_tool_call'
$b = $testText -match 'not json' -or $testText -match 'Err'
Check "tests cover round trips incl. a malformed-arguments Err case" ($a -and $b) "add tests/roundtrip.rs per Step 4"

# 6. Notes document string-vs-object asymmetry + repo greps
$notesPath = Join-Path $LabDir "u3-l04-notes.md"
$notes = if (Test-Path $notesPath) { Get-Content $notesPath -Raw } else { "" }
Check "u3-l04-notes.md records the arguments asymmetry + mapper findings" `
    ($notes -match 'string' -and $notes -match 'argument' -and $notes -match 'response_to_message') `
    "create u3-l04-notes.md per Steps 1, 3, 5"

# 7. Goose-repo evidence: both mappers + TOOL_USE const
$hits = Select-String -Path (Join-Path $GooseRepo "crates\goose-provider-types\src\formats\openai.rs"), (Join-Path $GooseRepo "crates\goose-provider-types\src\formats\anthropic.rs") -Pattern 'TOOL_USE_TYPE|pub fn response_to_message' -ErrorAction SilentlyContinue
Check "goose repo: TOOL_USE_TYPE const + response_to_message both found" ($null -ne $hits) "grep crates/goose-provider-types/src/formats/"

Write-Host ""
if ($fails -eq 0) {
    Write-Host "VERIFY PASSED $passes/$($passes + $fails)"
    exit 0
} else {
    Write-Host "VERIFY FAILED - $fails of $($passes + $fails) checks failed"
    exit 1
}