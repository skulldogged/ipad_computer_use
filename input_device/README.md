# Input device

Firmware for the **Seeed Studio XIAO RP2040** and **Waveshare RP2040-Zero**. It enumerates as USB networking
(NCM), keyboard, mouse, and a serial diagnostics interface. The host sends HTTP
commands over USB; the board emits HID reports back to that same host.

This component contains no agent, screen capture, control server, or Apple APIs.
It can be used independently with curl. The physical LEDs report idle, queued,
executing, completed, and error states. The external LED-matrix experiment is
not included.

## Layout

- `firmware/input_tool/`: firmware, bounded input parser, DHCP, onboard LEDs, diagnostics.
- `libraries/tusb-ncm/`: required TinyUSB NCM implementation, with upstream notices.
- `protocol/`: JavaScript action encoder exported as `ipad_input_device/actions`.
- `scripts/`: setup, build, flash, validation, and serial diagnostics.
- `test/`: protocol and host-compiled firmware tests.

## Build and flash

Install Arduino CLI, then run from the repository root:

```sh
bash input_device/scripts/setup.sh
bash input_device/scripts/build.sh
bash input_device/scripts/arduino.sh board list
bash input_device/scripts/flash.sh /dev/cu.YOUR_XIAO_PORT
```

The setup script installs the pinned Arduino-Pico **6.1.0** core. Toolchain files
stay in this component's ignored `.tools/` directory; output goes to `build/`.
On another OS, pass the serial port reported by Arduino CLI. For BOOT mode, copy
the generated UF2 to the board's `RPI-RP2` volume instead.

### RP2040-Zero on Windows

The Bash commands above build for the XIAO. For the Zero, use native PowerShell:

```powershell
./input_device/scripts/device.ps1 setup
./input_device/scripts/device.ps1 build
./input_device/scripts/device.ps1 flash
```

Install Arduino CLI on PATH or put `arduino-cli.exe` in `input_device/.tools/`
first. Setup pins Arduino-Pico 6.1.0 and Adafruit NeoPixel 1.15.2. The latter
drives the Zero's WS2812 LED on GPIO16 at low brightness; XIAO keeps its
original active-low RGB LED behavior. `-Board seeed_xiao_rp2040` selects XIAO.
Outputs are separated under `build/<board>/`. Never flash a XIAO build to a Zero.

For flashing, connect the Zero to the PC, hold BOOT, press and release RESET,
then release BOOT. The script requires exactly one `RPI-RP2` volume and checks
its bootloader ID. Use `-BootDrive E:` if multiple boards are attached. UF2's
RP2 bootloader ID does not identify the board model: select the actual board.
After flashing, move the board to the iPad; it is the iPad's USB network and
keyboard/mouse device, while the PC runs the control server over Wi-Fi/Tailscale.

The first Zero build enumerated keyboard, mouse, and serial on Windows 11,
but the Windows UsbNcm driver reported Code 10. On a physical 10th-generation
iPad running iPadOS 27, the app successfully read USB HTTP status and confirmed
HID readiness. Physical verification also passed keyboard text and shortcuts,
absolute mouse input (six targets, maximum error 0.03 UIKit points).

## Direct HTTP example

The board is **172.31.254.1**; the host normally receives **172.31.254.2** by DHCP.
These commands run on the host physically connected to the board, not on a
remote control server. They type `abc` into the focused field after one second:

```sh
curl -fsS http://172.31.254.1/input \
  -H "X-Input-Device-Secret: $INPUT_DEVICE_SECRET" -H 'Content-Type: text/plain' \
  --data-binary "$(node input_device/scripts/encode_actions.js '[
    {"type":"wait","ms":1000},
    {"type":"keys","sequence":"abc"}
  ]')"
```

To move to the center of the display:

```sh
curl -fsS http://172.31.254.1/input \
  -H "X-Input-Device-Secret: $INPUT_DEVICE_SECRET" -H 'Content-Type: text/plain' \
  --data-binary "$(node input_device/scripts/encode_actions.js '[{"type":"move","x":16384,"y":16384}]')"
```

This is a mouse report, **not** a touch/trackpad gesture ; coordinates are normalized 0..32767.
The firmware accepts encoded reports rather than an English command language.
See [PROTOCOL.md](PROTOCOL.md) for the complete format and limits.

## Encode structured actions

After root `npm ci`:

```sh
node input_device/scripts/encode_actions.js '[
  {"type":"keys","sequence":"abc"},
  {"type":"move","x":16384,"y":16384},
  {"type":"click","x":16384,"y":16384,"button":"left"}
]'
```

The wrapper only prints hex; it does not make network requests. Firmware owns
validation and playback.

## Test and troubleshoot

```sh
npm test --workspace input_device
bash input_device/scripts/test.sh
python3 input_device/scripts/check_device.py
```

The last command requires the attached board. It tests validation/cancellation
without intentionally pressing keys; avoid running it during another session.
On iPad, an empty Ethernet address means DHCP did not complete. Replug first.
For diagnosis, use manual address 172.31.254.2 and mask 255.255.255.248, with no
router or DNS. VPN routing can prevent access to this USB-only subnet.
