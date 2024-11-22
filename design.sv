//////////////////////////////////////////////////////////////////////
////                                                              ////
////  wb_lcd.v                                                    ////
////                                                              ////
////  This file is part of:                                       ////
////  WISHBONE/MEM MAPPED CONTROLLER FOR LCD CHARACTER DISPLAYS   ////
////  http://www.opencores.org/projects/wb_lcd/                   ////
////                                                              ////
////  Description                                                 ////
////   -  Wishbone wrapper.                                       ////
////                                                              ////
////  To Do:                                                      ////
////   - nothing really                                           ////
////                                                              ////
////  Author(s):                                                  ////
////   - José Ignacio Villar, jose@dte.us.es , jvillar@gmail.com  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 José Ignacio Villar - jvillar@gmail.com   ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 3 of the License, or (at your option) any     ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.gnu.org/licenses/lgpl.txt                    ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
///
/// LCD Controller defines
///
`define ADDR_WIDTH 7			// Address bus width
`define ADDR_RNG `ADDR_WIDTH-1:0	// Address bus range
`define DAT_WIDTH 8			// data bus width
`define DAT_RNG `DAT_WIDTH-1:0		// Address bus range
`define MEM_LENGTH 67			// Number of LCD memory positions.
`define MEM_ADDR_WIDTH 7		// Memory address bus width
`define MEM_LOW1  `ADDR_WIDTH'h00 //0	// Memory address of the first character at the first line
`define MEM_HIGH1 `ADDR_WIDTH'h0F //21	// Memory address of the last character at the first line
`define MEM_LOW2  `ADDR_WIDTH'h40 //64	// Memory address of the first character at the second line
`define MEM_HIGH2 `ADDR_WIDTH'h4F //85	// Memory address of the last character at the second line

`define INIT_DELAY_COUNTER_WIDTH 20	// Delay cycle counter width for init & main FSM
`define TX_DELAY_COUNTER_WIDTH 11	// Delay cycle counter width for TX FSM
`define _1MS_DELAY_CYCLES 50		// Number of cycles for a 1ms delay

///
/// WB wrapper defines
///

// WB interface
`define WB_DAT_WIDTH 32			// WB data bus width
`define WB_DAT_RNG `WB_DAT_WIDTH-1:0	// WB data bus range
`define WB_ADDR_WIDTH 32		// WB address bus width
`define WB_ADDR_RNG `WB_ADDR_WIDTH-1:0	// WB address bus range
`define WB_BSEL_WIDTH 4			// WB byte sel bus width
`define WB_BSEL_RNG `WB_BSEL_WIDTH-1:0	// WB byte sel bus range
`define ADDRESS_BIT


// Command and status registers address mask
`define SPECIAL_REG_ADDR_MASK 32'h00000080

// LCD characters memory mapping
`define FIRST_LCD_ADDR 0			// Address at where first LCD character is mapped (0)

// Command register and command codes
`define COMMAND_REG_ADDR 32'h00000080		// Address at where command register is mapped (128)
`define COMMAND_NOP_CODE 32'h00000000		// Code for repaint command	
`define COMMAND_REPAINT_CODE 32'h00000001	// Code for repaint command

// Status register and status codes
`define STATUS_REG_ADDR 32'h00000080		// Address at where status register is mapped (129)
`define STATUS_IDDLE_CODE 32'h00000000		// Code for iddle status
`define STATUS_BUSY_CODE 32'h00000001		// Code for busy status

module delay_counter #(
    parameter counter_width = 32
) (
    input clk,
    input reset,

    input [counter_width-1:0] count,
    input load,
    output done
);



    reg [counter_width-1:0] counter;

    always @(posedge clk)
        if (load) counter <= count;
        else  //if (!done)
            counter <= counter - 1'b1;


    assign done = (counter == 0);


endmodule

module lcd (
    input clk,
    input reset,

    input [`DAT_WIDTH-1:0] dat,
    input [`ADDR_WIDTH-1:0] addr,
    input we,

    input repaint,
    output busy,
    output [3:0] SF_D,
    output LCD_E,
    output LCD_RS,
    output LCD_RW
);

    //
    // TX sub FSM
    //
    parameter tx_state_high_setup = 3'b000;
    parameter tx_state_high_hold = 3'b001;
    parameter tx_state_oneus = 3'b010;
    parameter tx_state_low_setup = 3'b011;
    parameter tx_state_low_hold = 3'b100;
    parameter tx_state_fortyus = 3'b101;
    parameter tx_state_done = 3'b110;

    reg [2:0] tx_state = tx_state_done;  // Current tx fsm state
    reg [7:0] tx_byte;  // transmitting byte
    wire tx_init;  // init transmission
    reg tx_done = 0;


    //
    // MAIN FSM
    //
    parameter display_state_init = 5'b00000;
    parameter init_state_fifteenms = 5'b00001;
    parameter init_state_one = 5'b00010;
    parameter init_state_two = 5'b00011;
    parameter init_state_three = 5'b00100;
    parameter init_state_four = 5'b00101;
    parameter init_state_five = 5'b00110;
    parameter init_state_six = 5'b00111;
    parameter init_state_seven = 5'b01000;
    parameter init_state_eight = 5'b01001;
    parameter display_state_function_set = 5'b11000;
    parameter display_state_entry_set = 5'b11001;
    parameter display_state_set_display = 5'b11010;
    parameter display_state_clr_display = 5'b11011;
    parameter display_state_pause_setup = 5'b10000;
    parameter display_state_pause = 5'b10001;
    parameter display_state_set_addr1 = 5'b11100;
    parameter display_state_char_write1 = 5'b11101;
    parameter display_state_set_addr2 = 5'b11110;
    parameter display_state_char_write2 = 5'b11111;
    parameter display_state_done = 5'b10010;

    reg [4:0] display_state = display_state_init;  // current main fsm state
    integer pos = `MEM_LOW1;  // current drawing position




    //
    // RAM Interface
    //
    reg [`DAT_WIDTH-1:0] ram[0:`MEM_LENGTH-1];  // memory contents
    assign busy = (display_state != display_state_done);

    always @(posedge clk) if (we) ram[addr] <= dat;

    ///
    /// FSM and councurrent assignments definitions for LCD driving
    /// 
    reg  [3:0] SF_D0 = 4'b0000;
    reg  [3:0] SF_D1 = 4'b0000;
    reg        LCD_E0 = 1'b0;
    reg        LCD_E1 = 1'b0;
    wire       output_selector;

    assign output_selector = display_state[4];

    assign SF_D = (output_selector == 1'b1) ?	SF_D0 : //transmit
						SF_D1;  //initialize

    assign LCD_E = (output_selector == 1'b1) ?	LCD_E0 ://transmit
						LCD_E1; //initialize

    assign LCD_RW = 1'b0;  // write only

    //when to transmit a command/data and when not to
    assign tx_init = !tx_done & display_state[4] & display_state[3];

    // register select
    assign LCD_RS =	(display_state == display_state_function_set) ? 1'b0 :
                (display_state == display_state_entry_set)    ? 1'b0 :
                (display_state == display_state_set_display)  ? 1'b0 :
                (display_state == display_state_clr_display)  ? 1'b0 :
                (display_state == display_state_set_addr1)    ? 1'b0 :
                (display_state == display_state_set_addr2)    ? 1'b0 :
                                                                1'b1;


    reg [`INIT_DELAY_COUNTER_WIDTH-1:0] main_delay_value = 0;
    reg [`INIT_DELAY_COUNTER_WIDTH-1:0] tx_delay_value = 0;

    wire delay_done;

    reg main_delay_load = 0;
    reg tx_delay_load = 0;



    delay_counter #(
        .counter_width(`INIT_DELAY_COUNTER_WIDTH)
    ) delay_counter (
        .clk  (clk),
        .reset(reset),
        .count((main_delay_load) ? main_delay_value : tx_delay_value),
        .load (main_delay_load | tx_delay_load),
        .done (delay_done)
    );




    // main (display) state machine
    always @(posedge clk, posedge reset) begin
        if (reset == 1'b1) begin
            display_state <= display_state_init;
            main_delay_load <= 0;
            main_delay_value <= 0;
        end else begin
            main_delay_load  <= 0;
            main_delay_value <= 0;

            case (display_state)
                //refer to intialize state machine below
                display_state_init: begin
                    tx_byte <= 8'b00000000;
                    display_state <= init_state_fifteenms;
                    main_delay_load <= 1'b1;
                    main_delay_value <= 750000;
                end

                init_state_fifteenms: begin
                    main_delay_load <= 1'b0;
                    if (delay_done) begin
                        display_state <= init_state_one;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 11;
                    end
                end

                init_state_one: begin
                    main_delay_load <= 1'b0;
                    SF_D1 <= 4'b0011;
                    LCD_E1 <= 1'b1;
                    if (delay_done) begin
                        display_state <= init_state_two;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 205000;
                    end
                end

                init_state_two: begin
                    main_delay_load <= 1'b0;
                    LCD_E1 <= 1'b0;
                    if (delay_done) begin
                        display_state <= init_state_three;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 11;
                    end
                end

                init_state_three: begin
                    main_delay_load <= 1'b0;
                    SF_D1 <= 4'b0011;
                    LCD_E1 <= 1'b1;
                    if (delay_done) begin
                        display_state <= init_state_four;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 5000;
                    end
                end

                init_state_four: begin
                    main_delay_load <= 1'b0;
                    LCD_E1 <= 1'b0;
                    if (delay_done) begin
                        display_state <= init_state_five;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 11;
                    end
                end

                init_state_five: begin
                    main_delay_load <= 1'b0;
                    SF_D1 <= 4'b0011;
                    LCD_E1 <= 1'b1;
                    if (delay_done) begin
                        display_state <= init_state_six;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 2000;
                    end
                end

                init_state_six: begin
                    main_delay_load <= 1'b0;
                    LCD_E1 <= 1'b0;
                    if (delay_done) begin
                        display_state <= init_state_seven;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 11;
                    end
                end

                init_state_seven: begin
                    main_delay_load <= 1'b0;
                    SF_D1 <= 4'b0010;
                    LCD_E1 <= 1'b1;
                    if (delay_done) begin
                        display_state <= init_state_eight;
                        main_delay_load <= 1'b1;
                        main_delay_value <= 2000;
                    end
                end

                init_state_eight: begin
                    main_delay_load <= 1'b0;
                    LCD_E1 <= 1'b0;
                    if (delay_done) begin
                        display_state <= display_state_function_set;
                    end
                end

                //every other state but pause uses the transmit state machine
                display_state_function_set: begin
                    tx_byte <= 8'b00101000;
                    if (tx_done) display_state <= display_state_entry_set;
                end

                display_state_entry_set: begin
                    tx_byte <= 8'b00000110;
                    if (tx_done) display_state <= display_state_set_display;
                end

                display_state_set_display: begin
                    tx_byte <= 8'b00001100;
                    if (tx_done) display_state <= display_state_clr_display;
                end

                display_state_clr_display: begin
                    tx_byte <= 8'b00000001;
                    if (tx_done) begin
                        display_state <= display_state_pause_setup;
                        main_delay_load <= 1;
                        main_delay_value <= 82000;
                    end
                end

                display_state_pause_setup: begin
                    display_state <= display_state_pause;
                end

                display_state_pause: begin
                    tx_byte <= 8'b00000000;
                    if (delay_done) display_state <= display_state_set_addr1;
                end

                display_state_set_addr1: begin
                    tx_byte <= 8'b10000000;
                    if (tx_done) begin
                        display_state <= display_state_char_write1;
                        pos <= `MEM_LOW1;
                    end
                end

                display_state_char_write1: begin
                    tx_byte <= ram[pos] & 8'b11111111;
                    if (tx_done)
                        if (pos == `MEM_HIGH1)
                            display_state <= display_state_set_addr2;
                        else pos <= pos + 1;
                end

                display_state_set_addr2: begin
                    tx_byte <= 8'b11000000;
                    if (tx_done) begin
                        display_state <= display_state_char_write2;
                        pos <= `MEM_LOW2;
                    end
                end

                display_state_char_write2: begin
                    tx_byte <= ram[pos] & 8'b11111111;
                    if (tx_done)
                        if (pos == `MEM_HIGH2) begin
                            display_state <= display_state_done;
                        end else pos <= pos + 1;
                end

                display_state_done: begin
                    tx_byte <= 8'b00000000;
                    if (repaint) display_state <= display_state_function_set;
                    else display_state <= display_state_done;
                end
            endcase
        end
    end


    // transmit (tx) state machine, specified by datasheet
    always @(posedge clk, posedge reset) begin
        if (reset == 1'b1) tx_state <= tx_state_done;
        else begin
            case (tx_state)
                tx_state_high_setup: // 40 ns
			begin
                    LCD_E0 <= 1'b0;
                    SF_D0 <= tx_byte[7 : 4];
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_high_hold;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 12;
                    end
                end

                tx_state_high_hold: // 230 ns
			begin
                    LCD_E0 <= 1'b1;
                    SF_D0 <= tx_byte[7 : 4];
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_oneus;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 50;
                    end
                end

                tx_state_oneus: begin
                    LCD_E0 <= 1'b0;
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_low_setup;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 2;
                    end
                end

                tx_state_low_setup: // 40 ns
			begin
                    LCD_E0 <= 1'b0;
                    SF_D0 <= tx_byte[3 : 0];
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_low_hold;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 12;
                    end
                end

                tx_state_low_hold: // 230 ns
			begin
                    LCD_E0 <= 1'b1;
                    SF_D0 <= tx_byte[3 : 0];
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_fortyus;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 2000;
                    end
                end

                tx_state_fortyus: begin
                    LCD_E0 <= 1'b0;
                    tx_delay_load <= 1'b0;
                    if (delay_done) begin
                        tx_state <= tx_state_done;
                        tx_done  <= 1'b1;
                    end
                end

                tx_state_done: begin
                    LCD_E0 <= 1'b0;
                    tx_done <= 1'b0;
                    tx_delay_load <= 1'b0;
                    if (tx_init == 1'b1) begin
                        tx_state <= tx_state_high_setup;
                        tx_delay_load <= 1'b1;
                        tx_delay_value <= 2;
                    end
                end
            endcase
        end
    end
endmodule

module wb_lcd (
    //
    // I/O Ports
    //
    input wb_clk_i,
    input wb_rst_i,

    //
    // WB slave interface
    //
    input [`WB_DAT_RNG] wb_dat_i,
    output reg [`WB_DAT_RNG] wb_dat_o,
    input [`WB_ADDR_RNG] wb_adr_i,
    input [`WB_BSEL_RNG] wb_sel_i,
    input wb_we_i,
    input wb_cyc_i,
    input wb_stb_i,
    output reg wb_ack_o,
    output wb_err_o,

    //
    // LCD interface
    //
    output [3:0] SF_D,
    output LCD_E,
    output LCD_RS,
    output LCD_RW
);


    assign wb_err_o = 0;

    wire cs = wb_cyc_i & wb_stb_i;
    wire we = cs & wb_we_i;
    wire re = cs & !wb_we_i;
    wire special_address = (`SPECIAL_REG_ADDR_MASK == (`SPECIAL_REG_ADDR_MASK & wb_adr_i));

    wire lcd_busy;
    wire lcd_we = !special_address & we;
    wire [`ADDR_WIDTH-1:0] lcd_addr = wb_adr_i[`ADDR_WIDTH-1:0];

    wire repaint_req =  we & (wb_adr_i == `COMMAND_REG_ADDR) & (wb_dat_i == `COMMAND_REPAINT_CODE);
    wire status = lcd_busy ? `STATUS_BUSY_CODE : `STATUS_IDDLE_CODE;


    // wb_ack management: two clk cycles per WB access to avoid long combinational paths.
    always @(posedge wb_clk_i) begin
        if (wb_rst_i) wb_ack_o <= 1'b0;
        else begin
            if (cs) wb_ack_o <= ~wb_ack_o;
            else wb_ack_o <= 1'b0;
        end
    end

    // Status register (only checks if lcd is busy)
    always @(posedge wb_clk_i) // wb_dat_o always outputs the status register not depending on what address is being accessed
        wb_dat_o = status;

    // Command register (only issues repaint commands)
    reg lcd_repaint = 0;
    always @(posedge wb_clk_i) begin
        if (repaint_req & !lcd_busy) lcd_repaint <= 1;
        else lcd_repaint <= 0;
    end

    //----------------------------------------------------------------------------
    // Memory mapped LCD display controller
    //----------------------------------------------------------------------------

    lcd lcd (
        .clk  (wb_clk_i),
        .reset(wb_rst_i),

        .dat(wb_dat_i[`DAT_RNG]),
        .addr(lcd_addr),
        .we(lcd_we),
        .repaint(lcd_repaint),

        .busy  (lcd_busy),
        .SF_D  (SF_D),
        .LCD_E (LCD_E),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW)
    );



endmodule
