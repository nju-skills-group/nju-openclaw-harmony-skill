param([string]$DevEcoRoot = 'D:\software\DevEco-Studio')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not (Test-Path -LiteralPath 'build-profile.json5')) {
    Copy-Item -LiteralPath 'build-profile.example.json5' -Destination 'build-profile.json5'
}
if (-not (Test-Path -LiteralPath 'local.properties')) {
    $sdkProperty = 'sdk.dir=' + (Join-Path $DevEcoRoot 'sdk').Replace('\', '/')
    Set-Content -LiteralPath 'local.properties' -Value $sdkProperty -Encoding utf8
}
$env:JAVA_HOME = Join-Path $DevEcoRoot 'jbr'
$env:NODE_HOME = Join-Path $DevEcoRoot 'tools\node'
$env:DEVECO_SDK_HOME = Join-Path $DevEcoRoot 'sdk'
$env:PATH = "$env:NODE_HOME;$env:JAVA_HOME\bin;" + $env:PATH
New-Item -ItemType Directory -Path '.local\logs' -Force | Out-Null
$buildStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$buildLog = Join-Path $PSScriptRoot ".local\logs\build-$buildStamp.log"
Start-Transcript -LiteralPath $buildLog | Out-Null
try {
    & "$DevEcoRoot\tools\ohpm\bin\ohpm.bat" install
    if ($LASTEXITCODE -ne 0) { throw "ohpm failed: $LASTEXITCODE" }
    & "$DevEcoRoot\tools\hvigor\bin\hvigorw.bat" --mode module -p product=default -p module=entry@default -p requiredDeviceType=2in1 assembleHap --no-daemon
    if ($LASTEXITCODE -ne 0) { throw "Hvigor failed: $LASTEXITCODE" }
} finally {
    Stop-Transcript | Out-Null
    Write-Output "Build transcript: $buildLog"
}
