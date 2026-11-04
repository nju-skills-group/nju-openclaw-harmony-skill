# Summarize bench-log.txt: median / P95 / success rate per group+mode.
# Usage: powershell -ExecutionPolicy Bypass -File stats.ps1 -In bench-log.txt
param(
  [string]$InFile = "bench-log.txt"
)

function Pct([int[]]$arr, [double]$p) {
  if ($arr.Count -eq 0) { return 0 }
  $s = @($arr | Sort-Object)
  $idx = [int][Math]::Ceiling($p / 100.0 * $s.Count) - 1
  if ($idx -lt 0) { $idx = 0 }
  if ($idx -ge $s.Count) { $idx = $s.Count - 1 }
  return $s[$idx]
}

$rows = @()
foreach ($line in (Get-Content -LiteralPath $InFile)) {
  $i = $line.IndexOf('SAMPLE|')
  if ($i -lt 0) { continue }
  $p = $line.Substring($i).Split('|')
  if ($p.Count -lt 10) { continue }
  $h = @{}
  for ($k = 3; $k -lt $p.Count; $k++) {
    $kv = $p[$k].Split('=')
    if ($kv.Count -eq 2) { $h[$kv[0]] = $kv[1] }
  }
  $rows += [pscustomobject]@{
    group    = $p[1]
    mode     = $p[2]
    seq      = [int]$h['seq']
    total    = [int]$h['total']
    biz      = [int]$h['biz']
    bridge   = [int]$h['bridge']
    load     = [int]$h['load']
    checksum = $h['checksum']
    ok       = [int]$h['ok']
  }
}

if ($rows.Count -eq 0) {
  Write-Output "no SAMPLE lines found in $InFile"
  exit 1
}

$summary = $rows |
  Group-Object group, mode |
  ForEach-Object {
    $g = $_.Group
    $totals = [int[]]@($g | Where-Object { $_.ok -eq 1 } | ForEach-Object { $_.total })
    $bizs = [int[]]@($g | Where-Object { $_.ok -eq 1 -and $_.biz -ge 0 } | ForEach-Object { $_.biz })
    $bridges = [int[]]@($g | Where-Object { $_.ok -eq 1 -and $_.bridge -ge 0 } | ForEach-Object { $_.bridge })
    [pscustomobject]@{
      group    = $g[0].group
      mode     = $g[0].mode
      n        = $g.Count
      ok_rate  = [Math]::Round((@($g | Where-Object { $_.ok -eq 1 }).Count / $g.Count) * 100, 1)
      total_med = Pct $totals 50
      total_p95 = Pct $totals 95
      biz_med   = Pct $bizs 50
      bridge_med = Pct $bridges 50
      load_med  = Pct ([int[]]@($g | Where-Object { $_.load -gt 0 } | ForEach-Object { $_.load })) 50
      checksum  = (@($g | ForEach-Object { $_.checksum } | Sort-Object -Unique) -join '/')
    }
  }

$summary | Format-Table -AutoSize

$uniqueChecksums = @($rows | ForEach-Object { $_.group + '=' + $_.checksum } | Sort-Object -Unique)
Write-Output ""
Write-Output "checksums (should be one value per group):"
$uniqueChecksums | ForEach-Object { Write-Output ("  " + $_) }
