# Dump the hilog buffer and keep only the bench lines.
# Usage: powershell -ExecutionPolicy Bypass -File collect.ps1 -Hdc "C:\path\hdc.exe" -Out bench-log.txt
param(
  [string]$Hdc = "hdc",
  [string]$Out = "bench-log.txt"
)

$lines = & $Hdc shell "hilog -x" 2>$null
$kept = $lines | Where-Object { $_ -match 'BenchD' }
$kept | Set-Content -Path $Out -Encoding ASCII
Write-Output ("kept " + @($kept).Count + " lines -> " + $Out)
