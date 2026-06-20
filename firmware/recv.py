#!/usr/bin/env python3
import sys
import serial


def main() -> int:
    dev = sys.argv[1] if len(sys.argv) >= 2 else "/dev/ttyUSB0"
    baud = int(sys.argv[2]) if len(sys.argv) >= 3 else 9600

    with serial.Serial(
        port=dev,
        baudrate=baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=None,
    ) as ser:
        print(f"RX hex from {dev} at {baud} bps. Ctrl-C to stop.", file=sys.stderr)

        while True:
            b = ser.read(1)
            if b:
                print(f"{b[0]:02x}", flush=True)


if __name__ == "__main__":
    raise SystemExit(main())
