# iPad app

Native SwiftUI setup, ReplayKit screen capture, session lifecycle and forwarding
to the RP2040 absolute-pointer input tool. Setup consists of connecting the tool
and entering the server URL. Then Start Session and approve Apple's broadcast.
End Session revokes input and stops the broadcast. The server URL can be edited
on the main screen. Tailscale should be active when using a Tailscale server address.

## Build/install
Use Xcode with the ipad_computer_use scheme, or scripts/build.sh and scripts/install.sh.
Personal DEVELOPMENT_TEAM and KEY_RELAY_BUNDLE_ID values belong in the ignored
.signing.env file. Enable Developer Mode on the iPad. Signing may require running
the build in the logged-in macOS desktop session rather than an SSH keychain context.

The app and broadcast extension allow local USB networking and the Tailscale
100.64.0.0/10 range. The latter uses Tailscale's encrypted transport. Rotate captured
landscape frames before sending to the server. The input tool must advertise
absolutePointer:true. The screen broadcast is user-controlled and cannot be
started remotely without Apple's confirmation.

Optional Live Activity push support is described in
[LIVE_ACTIVITY.md](../control_server/LIVE_ACTIVITY.md).
