# WB LCD Character Display Controller

## Overview

LCD character display controller with Wishbone and memory mapped interfaces.

It is compatible with the following parts: Sitronix ST7066U, Samsung S6A0069X or KS0066U, Hitachi HD44780 and SMOS SED1278.

It's commonly used to drive several character displays integrated in popular Xilinx development boards such as Spartan 3E Starter Kit from Digilent.

## RTL source

- [open cores](http://www.opencores.org/projects/wb_lcd/)

## Spec

- Has 3 modules: `delay_counter`, `lcd`, `wb_lcd`

### Delay counter

- Parameterised delay counter with default counter width set to 32 bits.

#### Signal description

| Signal  | Description                           |
| ------- | ------------------------------------- |
| `clk`   | clk input                             |
| `reset` | Not used                              |
| `count` | No. of cycles to count                |
| `load`  | count is sampled iff load is asserted |
| `done`  | Asserted when count is done           |

### LCD

#### Signal description

| Signal    | Description                  |
| --------- | ---------------------------- |
| `clk`     | clk input                    |
| `reset`   | Active high sync reset       |
| `dat`     | 8 bit data input             |
| `addr`    | 7 bit addr input             |
| `we`      | Wishbone write enable signal |
| `repaint` | Repaint input                |
| `busy`    | Busy                         |
| `SF_D`    | 4 bit output                 |
| `LCD_E`   |                              |
| `LCD_RS`  |                              |
| `LCD_RW`  |                              |

### WB LCD

#### Signal description

| Signal      | Description                     |
| ----------- | ------------------------------- |
| `wb_clk_i`  | wishbone clk                    |
| `wb_rst_i`  | wishbone rst (active high sync) |
| `wb_dat_i`  | 8 bit data wishbone input       |
| `wb_dat_o`  | 8 bit data wishbone output      |
| `wb_addr_i` | 7 bit addr wishbone input       |
| `wb_sel_i`  | 4 bit byte select               |
| `wb_we_i`   | wishbone write enable           |
| `wb_cyc_i`  | wishbone write enable           |
| `wb_stb_i`  | wishbone strobe                 |
| `wb_ack_o ` | wishbone acknowledgement        |
| `wb_err_o ` | wishbone error                  |
| `SF_D`      | Same as LCD                     |
| `LCD_E`     | Same as LCD                     |
| `LCD_RS`    | Same as LCD                     |
| `LCD_RW`    | Same as LCD                     |

- lcd ram has only 66:0 words. So wb_addr_i should be less than 67
