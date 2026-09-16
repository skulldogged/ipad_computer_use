# iPad Computer Use — personal build

Control an iPad with a Waveshare RP2040-Zero USB keyboard and absolute mouse.
The native app shares its screen through ReplayKit and forwards input over USB
networking. The control server can run on another machine over Tailscale.

Pointer coordinates map directly to USB absolute positions. No movement-speed
profile, starting pointer position, calibration screen, or second server is needed.

## Components
- [Input device](input_device/README.md): firmware, USB networking, keyboard and absolute mouse.
- [Control server](control_server/README.md): sessions, screenshots, input API and MCP.
- [iPad app](ipad_app/README.md): setup, broadcast consent and input forwarding.

## Setup
Run npm ci at the repository root. Build and flash the firmware with
input_device/scripts/device.ps1 on Windows, selecting waveshare_rp2040_zero.
The build embeds the secret from control_server/.state/input_device_secret.
Keep that same secret with the deployed server; do not commit it.

On Linux, start the transient services with:

    PORT=8875 MCP_PORT=8880 IPAD_TAILNET_SERVE=1 bash control_server/start-linux.sh

On Windows, use control_server/start-windows.ps1 (ports 8765 and 8780).
Build/install the signed app with Xcode using the scripts in ipad_app/scripts.
Connect the board to the iPad with a data cable, enter the server URL, then
Start Session and approve Start Broadcast. Setup has two steps: input tool and server.

## Input
Use the latest full-screen screenshot dimensions as coordinateSpace:

    {"coordinateSpace":{"width":1280,"height":890},"actions":[{"type":"click","x":500,"y":300}]}

Send this to POST /computer-use/actions, or the MCP issue_actions tool.
See [the protocol](control_server/PROTOCOL.md).

## Deployment and security
The iPad connects outward to the server. Use a trusted private network/Tailscale;
do not publish the raw listener. Controller HTTP routes and MCP are loopback-only
by default. Each broadcast requires a user-started session. Mutating board requests
require the embedded device secret. No automatic boot startup is installed by the launchers.

Verified on an iPad 10th generation: six absolute clicks landed within 0.03 UIKit
points of their requested positions in landscape. Portrait and dragging have not
yet been physically verified. Keyboard input and upright screen capture also work.
