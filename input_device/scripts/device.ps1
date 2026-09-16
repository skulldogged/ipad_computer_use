param(
    [ValidateSet('setup', 'build', 'flash', 'list')]
    [string]$Action = 'build',
    [ValidateSet('waveshare_rp2040_zero', 'seeed_xiao_rp2040')]
    [string]$Board = 'waveshare_rp2040_zero',
    [string]$BootDrive
)
$ErrorActionPreference = 'Stop'
$component = Split-Path $PSScriptRoot -Parent
$cli = Join-Path $component '.tools/arduino-cli.exe'
if (!(Test-Path -LiteralPath $cli)) { $cli = (Get-Command arduino-cli -ErrorAction Stop).Source }
$env:ARDUINO_DIRECTORIES_DATA = Join-Path $component '.tools/arduino-data'
$env:ARDUINO_DIRECTORIES_DOWNLOADS = Join-Path $component '.tools/downloads'
$env:ARDUINO_DIRECTORIES_USER = Join-Path $component '.tools/sketchbook'
$index = 'https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json'
$output = Join-Path $component "build/$Board"
function Invoke-Arduino {
    & $cli @args
    if ($LASTEXITCODE -ne 0) { throw "Arduino CLI failed ($LASTEXITCODE)." }
}
switch ($Action) {
    'setup' {
        Invoke-Arduino core update-index --additional-urls $index
        Invoke-Arduino core install rp2040:rp2040@6.1.0 --additional-urls $index
        Invoke-Arduino lib install 'Adafruit NeoPixel@1.15.2'
    }
    'list' { Invoke-Arduino board list }
    'build' {
        Push-Location (Split-Path $component -Parent)
        try {
            node -e 'const fs=require("fs");const secret=require("./control_server/config").readInputDeviceSecret();fs.writeFileSync("input_device/firmware/input_tool/GeneratedSecret.h", "#pragma once\n#define INPUT_DEVICE_SECRET "+JSON.stringify(secret)+"\n");'
            if ($LASTEXITCODE -ne 0) { throw 'Failed to generate input-device secret.' }
            Invoke-Arduino compile --libraries "$component/libraries" --fqbn "rp2040:rp2040:${Board}:flash=2097152_65536" --output-dir $output "$component/firmware/input_tool"
        } finally { Pop-Location }
    }
    'flash' {
        $firmware = Join-Path $output 'input_tool.ino.uf2'
        if (!(Test-Path -LiteralPath $firmware)) { throw "Build $Board first." }
        $volumes = @(Get-Volume | Where-Object { $_.FileSystemLabel -eq 'RPI-RP2' -and $_.DriveLetter })
        if ($BootDrive) { $volumes = @($volumes | Where-Object { "$($_.DriveLetter):" -eq $BootDrive.TrimEnd('\') }) }
        if ($volumes.Count -ne 1) { throw 'Connect exactly one RP2040 in BOOT mode, or select -BootDrive E:.' }
        $destination = "$($volumes[0].DriveLetter):\"
        $info = Get-Content -LiteralPath (Join-Path $destination 'INFO_UF2.TXT') -Raw
        if ($info -notmatch 'Board-ID: RPI-RP2') { throw 'Unexpected bootloader board ID.' }
        Copy-Item -LiteralPath $firmware -Destination $destination
        Write-Output "Copied $Board firmware to $destination. Check USB re-enumeration and /status."
    }
}
