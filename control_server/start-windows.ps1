$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$state = Join-Path $root '.state'
New-Item -ItemType Directory -Force $state | Out-Null
$node = (Get-Command node -ErrorAction Stop).Source
# App-facing ports are reachable on the private network; controller routes
# enforce loopback in server.js. The MCP listener remains loopback-only.
$services = @(
    @{ Name = 'server'; Script = 'server.js'; Port = 8765; Health = '/status' },
    @{ Name = 'mcp_server'; Script = 'mcp_server.js'; Port = 8780; Health = '/mcp' }
)
foreach ($service in $services) {
    $existing = @(Get-NetTCPConnection -State Listen -LocalPort $service.Port -ErrorAction SilentlyContinue)
    if ($existing.Count) {
        Write-Output "$($service.Name): port $($service.Port) already listening; leaving it untouched."
        continue
    }
    $child = Start-Process -FilePath $node -ArgumentList ('"' + (Join-Path $root $service.Script) + '"') -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $state "$($service.Name).log") -RedirectStandardError (Join-Path $state "$($service.Name).error.log")
    Set-Content -LiteralPath (Join-Path $state "$($service.Name).pid") -Value $child.Id
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        Start-Sleep -Milliseconds 100
        $child.Refresh()
        if ($child.HasExited) { break }
        try {
            $url = "http://127.0.0.1:$($service.Port)$($service.Health)"
            if ($service.Name -eq 'mcp_server') {
                $null = Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Headers @{Accept='application/json, text/event-stream'} -Body '{"jsonrpc":"2.0","id":1,"method":"ping"}' -TimeoutSec 1
            } else { $null = Invoke-RestMethod -Uri $url -TimeoutSec 1 }
            $ready = $true
            break
        } catch {}
    }
    if (!$ready) {
        if (!$child.HasExited) { Stop-Process -Id $child.Id }
        throw "$($service.Name) failed; inspect $state."
    }
    Write-Output "$($service.Name): running (PID $($child.Id), port $($service.Port))."
}
Write-Output 'These processes run for this Windows session; no sign-in startup was installed.'
