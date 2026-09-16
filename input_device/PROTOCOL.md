# USB input protocol

USB NCM address: http://172.31.254.1. The iPad receives an address by DHCP without
changing its internet gateway. GET /status reports hidReady, absolutePointer,
running, state and completed report count. POST /input and POST /stop require
X-Input-Device-Secret. The secret is embedded at build time and never returned.

Input bodies are hexadecimal five-byte records:

| Action | Bytes |
| --- | --- |
| Key | 01 modifiers key 00 00 |
| Wait | 03 millisecondsLow millisecondsHigh 00 00 |
| Absolute pointer | (0x10 OR buttons) xLow xHigh yLow yHigh |
| Wheel at last position | 18 wheel 00 00 00 |

X/Y are unsigned little-endian values 0..32767 spanning the display. Buttons are
left=1,right=2,middle=4. Wheel is signed -127..127. Keys use Arduino keyboard
encoding; modifiers are Ctrl=1,Shift=2,Alt=4,Command=8. The codec handles key names.
Relative mouse records are rejected. Click and drag preserve absolute coordinates
while pressing/releasing. This is USB mouse input, not native multitouch.

At most 512 records, 10 seconds total waits and no unreleased buttons at batch end.
Only one batch runs at a time. HTTP handling pauses while keys/buttons are held;
stop is not instantaneous. Firmware stops on USB suspend/unmount or a 70-second
deadline. Poll status until running:false and state:done; never retry uncertain input blindly.
