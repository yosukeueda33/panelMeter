#!/usr/bin/env python3

import argparse
import serial
import sys


def parse_int(s: str) -> int:
    # "10", "0x0a", "0b1010" などを受け付ける
    return int(s, 0)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Send UART daisy-chain meter protocol packet"
    )

    parser.add_argument(
        "port",
        help="serial port, e.g. /dev/ttyUSB0 or /dev/ttyACM0",
    )
    parser.add_argument(
        "header_no",
        type=parse_int,
        help="header number: 0..15",
    )
    parser.add_argument(
        "index",
        type=parse_int,
        help="PWM/index: 0..127",
    )
    parser.add_argument(
        "value",
        type=parse_int,
        help="PWM value: 0..127",
    )
    parser.add_argument(
        "--baud",
        type=int,
        default=9600,
        help="baud rate, default 9600",
    )

    args = parser.parse_args()

    header_no = args.header_no
    index = args.index
    value = args.value

    if not (0 <= header_no <= 15):
        print("error: header_no must be 0..15", file=sys.stderr)
        return 1

    if not (0 <= index <= 127):
        print("error: index must be 0..127", file=sys.stderr)
        return 1

    if not (0 <= value <= 127):
        print("error: value must be 0..127", file=sys.stderr)
        return 1

    packet = bytes([
        0x80 | header_no,
        index,
        value,
    ])

    print("send:", " ".join(f"0x{b:02X}" for b in packet))

    with serial.Serial(args.port, args.baud, timeout=1) as ser:
        ser.write(packet)
        ser.flush()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())