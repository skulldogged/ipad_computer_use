#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
root="$PWD"
node_bin="$(command -v node)"
export PORT="${PORT:-8765}"
export MCP_PORT="${MCP_PORT:-8780}"
export CONTROL_SERVER_STATE_DIR="${CONTROL_SERVER_STATE_DIR:-$root/.state}"
if [[ "${IPAD_TAILNET_SERVE:-0}" == 1 ]]; then
  export HOST=127.0.0.1
fi
mkdir -p "$CONTROL_SERVER_STATE_DIR"
chmod 700 "$CONTROL_SERVER_STATE_DIR"
start() {
  local unit="$1" entry="$2"
  if systemctl --user is-active --quiet "$unit"; then
    echo "$unit already running; leaving it untouched"
    return
  fi
  systemd-run --user --collect --unit="$unit" \
    --description="iPad Computer Use: $entry" \
    --working-directory="$root" --property=Restart=on-failure \
    --property=RestartSec=2 --property=UMask=0077 \
    --setenv="PORT=$PORT" \
    --setenv="MCP_PORT=$MCP_PORT" --setenv=MCP_HOST=127.0.0.1 \
    --setenv="HOST=${HOST:-0.0.0.0}" \
    --setenv="CONTROL_SERVER_STATE_DIR=$CONTROL_SERVER_STATE_DIR" \
    "$node_bin" "$root/$entry"
}
start ipad-control.service server.js
start ipad-mcp.service mcp_server.js
if [[ "${IPAD_TAILNET_SERVE:-0}" == 1 ]]; then
  tailscale_bin="$(command -v tailscale)"
  for service in control; do
    unit="ipad-$service-tailnet.service"
    port="$PORT"
    if ! systemctl --user is-active --quiet "$unit"; then
      systemd-run --user --collect --unit="$unit" --property=Restart=on-failure \
        --property=RestartSec=2 "$tailscale_bin" serve --tcp="$port" "tcp://127.0.0.1:$port"
    fi
  done
fi
echo "Started transient user services; no boot-time startup was installed."
echo "Control: $PORT; MCP: 127.0.0.1:$MCP_PORT"
