# panelMeter

## 3-byte UART protocol

The UART packet used by the firmware is a compact 3-byte command frame:

- Byte 0: header/device selector
  - The top bit is set to `0x80` to mark the start of a packet.
  - The lower 4 bits hold the header/device number (`0` to `15`).
  - Example: `0x80 | header_no`.
- Byte 1: index
  - A 7-bit value (`0` to `127`) that selects the target channel, position, or register.
- Byte 2: value
  - A 7-bit value (`0` to `127`) that carries the payload for that index.

In short, the frame is:

```text
[0x80 | header_no][index][value]
```

Example:

```text
0x80 0x05 0x03
```

This means: send to device/header `0`, set index `5` to value `3`.

A helper script is available at [firmware/sendPacket.py](firmware/sendPacket.py) to send such packets over serial.

Note on special header values:

- `0x8F` is returned as `0x8F` by the parser and effectively ignored by the firmware; it does not change state or trigger an action. See the parser logic in the generated `Communicate` module for details.
