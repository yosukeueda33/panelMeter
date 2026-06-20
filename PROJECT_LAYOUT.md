# Project layout

This repository is split into three parts:

- `ivory-gen/`
  - Stack project for Ivory.
  - Uses `lts-14.27`.
  - Generates C code from Ivory.

- `copilot-gen/`
  - Stack project for Copilot.
  - Uses `lts-22.44`.
  - Generates C99 code from Copilot.

- `firmware/`
  - AVR/C integration layer.
  - Includes generated C/H files from `ivory-gen/generated` and `copilot-gen/generated`.
