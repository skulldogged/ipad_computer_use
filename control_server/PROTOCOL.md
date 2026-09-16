# Control protocol

POST /session/start accepts {deviceID} and returns {sessionID,state}.
POST /session/end accepts {deviceID,sessionID}. GET /device-status/UUID reports
connection and session state. The app connects to WS /device and sends hello with
name, deviceID, sessionID, capabilities:["input","screen"], absolutePointer:true.
The server replies ready with the inputDeviceSecret. A session permit is single-use,
device-bound, expires after 120 seconds, and requires user-started broadcasting.

## Loopback controller routes
- GET /status: connection, capabilities, absolutePointer and pending command.
- GET /screen: fresh JPEG, dimensions, frameID and timestamps.
- POST /computer-use/actions: screenshot-coordinate actions.
- POST /actions: low-level HID-coordinate actions.
- POST /run: {sequence:"hello{ENTER}",delay:1}.
- POST /stop: cancel pending input.

Example computer-use request:

    {"coordinateSpace":{"width":1280,"height":890},"actions":[{"type":"click","x":500,"y":300}]}

Actions: type_text with text; press with keys:{key,modifiers}; move_to and click
with x,y; drag with from:{x,y},to:{x,y}; scroll with dy; wait with ms.
Button is left (default), right or middle. Chord modifiers: ctrl,shift,alt,cmd.
Coordinate dimensions describe the full display, in screen_pixels (default) or
ui_points. Positions map directly to 0..32767; no current-pointer argument is used.

Low-level actions use keys with sequence; move/click with x,y in 0..32767; drag
with from/to in that range; scroll with wheel; wait with ms. Scroll is performed
at the last absolute position. Delays are encoded as wait records.

At most 128 actions/512 records and 10 seconds total waits per batch. Batches
release their buttons. One input request and one screenshot may be pending.
App sends accepted then completed/failed with the command ID. Completion confirms
report delivery; inspect the screenshot to verify the intended app effect.
Do not replay unknown outcomes after timeout/disconnection automatically.

Browser Origin requests are rejected. Administrative routes require loopback.
Use a trusted network or private Tailscale transport for app-facing routes.
