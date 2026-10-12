# FactorioIRLab

A real-life lab for [Factorio](https://factorio.com): an STM32 board lights up in the colour of the science pack being researched in the game, in real time, using a modified version of the [Disco Science](https://mods.factorio.com/mod/DiscoScience) mod.

Inspired by this r/factorio post: [3D printed lab with Disco Science realtime game sync](https://www.reddit.com/r/factorio/comments/1v4dpid/3d_printed_lab_with_disco_science_realtime_game/). The approach here is different: no WLED, MQTT or Home Assistant, just a **bare-metal STM32** fed directly over a serial link from the PC.

## About this project

This is my first embedded project. Everything runs **bare metal**: no HAL, no CMSIS, no libc. Peripherals are configured by writing to registers directly, which I learned by reading the STM32F103 reference manual (RM0008) and datasheet. The firmware and the Python script are written by hand, with no AI-generated code.

## How it works

```
 Factorio ──Modified Disco Science mod──> disco_science_color.txt
                                              │  read every 10 ms
                                              ▼
                                          uart.py  (PC)
                                              │  1 ASCII byte, 115200 baud, 8N1
                                              ▼
                                  STM32F103: USART2 (PA3 = RX)
                                              │
                                  GPIO PA8 / PA9 / PA10
                                              ▼
                                            LEDs
```

1. A modified version of the Disco Science mod writes the colour of the science currently being researched (`1`, `2` or `3`) to `script-output/disco_science_color.txt`.
2. `uart.py` reads that file and, when the value changes, sends it to the board over a serial port.
3. The firmware polls USART2 and turns on the matching output.


## Protocol

Single ASCII byte, 115200 baud, 8 data bits, no parity, 1 stop bit.

| Byte | Effect                          |
| ---- | ------------------------------- |
| `1`  | PA8 high, PA9 and PA10 low      |
| `2`  | PA9 high, PA8 and PA10 low      |
| `3`  | PA10 high, PA8 and PA9 low      |
| any other | ignored (state is kept)    |

Only one output is on at a time. All outputs are off at boot.

## Hardware

- MCU: STM32F103 (`xB` variant, Cortex-M3, Flash at `0x08000000`)
- A serial link between the PC and the board's USART2
- LEDs on PA8, PA9, PA10

| Pin  | Function                                  | Command | Colour |
| ---- | ----------------------------------------- | ------- | ------ |
| PA2  | USART2 TX (configured, not used yet)      |         |        |
| PA3  | USART2 RX                                 |         |        |
| PA8  | GPIO output, push-pull, 2 MHz             | `1`     | Red    |
| PA9  | GPIO output, push-pull, 2 MHz             | `2`     | Green  |
| PA10 | GPIO output, push-pull, 2 MHz             | `3`     | Black  |

The baud rate is computed for the default 8 MHz internal clock (no PLL is configured in `main.c`): `USARTDIV = 8 MHz / (16 × 115200) ≈ 4.34`, set as `4.3125` in `USART2_BRR` (about 0.6 % error).

## Files

| File                    | Role                                           |
| ----------------------- | ---------------------------------------------- |
| `main.c`                | Firmware: clocks, GPIO, USART2, main loop      |
| `startup_stm32f103xb.s` | Startup code and vector table                  |
| `script.ld`             | Linker script                                  |
| `Makefile`              | Build and flash                                |
| `uart.py`               | PC side: watches the colour file, sends to UART |

## Build and flash

Requirements: `arm-none-eabi-gcc`, `make`, and [stlink tools](https://github.com/stlink-org/stlink) (`st-flash`) with an ST-Link.

```sh
make          # builds firmware.elf and firmware.bin
make flash    # writes firmware.bin to 0x08000000 with st-flash
make re       # clean rebuild
```

## Run

```sh
pip install pyserial
```

1. Edit `PORT` and `DATA_FILE` at the top of `uart.py` for your machine.
2. Run `python uart.py`.
3. Start Factorio with the modified Disco Science mod enabled (or any mod that writes the colour to the file).

## Credits

- [Disco Science](https://mods.factorio.com/mod/DiscoScience) by Daniel Brauer ([source](https://github.com/danielbrauer/DiscoScience), MIT license): the Factorio mod this project builds on.
- [3D printed lab with Disco Science realtime game sync](https://www.reddit.com/r/factorio/comments/1v4dpid/3d_printed_lab_with_disco_science_realtime_game/): the r/factorio post that inspired this project.

## License

No license yet for this repo's own code. The original Disco Science mod is MIT-licensed by its author.