# Control server

Run npm ci at the repository root. Start with npm start --workspace control_server,
or use start-linux.sh / start-windows.ps1 for detached services. Linux services
are transient systemd user units, not boot-time installations.

PORT defaults to 8765; MCP_PORT defaults to 8780. MCP_HOST defaults to loopback.
For a private Tailscale forward on Linux:

    PORT=8875 MCP_PORT=8880 IPAD_TAILNET_SERVE=1 bash control_server/start-linux.sh

The iPad URL is ws://TAILSCALE_IP:8875/device. Only the control listener needs a
Tailscale forward. Stop with systemctl --user stop ipad-control-tailnet ipad-control ipad-mcp.

The state directory stores the input-device secret. Copy the existing secret when
moving servers so it matches the flashed board. Keep .state out of Git.

## CLI
Run node control_server/client.js status, screen, send, stop, or computer_use FILE.
The computer_use JSON contains coordinateSpace and actions. The low-level move,
click and drag CLI commands take absolute coordinates in the 0..32767 HID range.

## MCP
Run npm run mcp --workspace control_server. The endpoint is /mcp and exposes
status, get_screen and issue_actions. No starting pointer is needed for coordinates.
Point click and move_to use the latest full-screen screenshot dimensions; drag
accepts from/to points. Scroll uses signed USB wheel units at the last position.

See [PROTOCOL.md](PROTOCOL.md) for sessions, input limits and request formats.
