import uvm_pkg::*;

`include "uvm_macros.svh"
`include "interface.sv"
`include "seq_item.sv"
`include "sequence.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "agent.sv"
// `include "scoreboard.sv"
`include "environment.sv"
`include "rand_test.sv"


module top ();

    logic clk;
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    wb_if intf (.wb_clk_i(clk));

    wb_lcd dut (
        .wb_clk_i(intf.wb_clk_i),
        .wb_rst_i(intf.wb_rst_i),
        .wb_data_i(intf.wb_data_i),
        .wb_data_o(intf.wb_data_o),
        .wb_addr_i(intf.wb_addr_i),
        .wb_sel_i(intf.wb_sel_i),
        .wb_we_i(intf.wb_we_i),
        .wb_cyc_i(intf.wb_cyc_i),
        .wb_stb_i(intf.wb_stb_i),
        .wb_ack_o(intf.wb_ack_o),
        .wb_err_o(intf.wb_err_o),
        .SF_D(intf.SF_D),
        .LCD_E(intf.LCD_E),
        .LCD_RS(intf.LCD_RS),
        .LCD_RW(intf.LCD_RW)
    );

    initial begin
        uvm_config_db#(virtual wb_if)::set(null, "*", "vif", intf);
        run_test("random_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
    end

endmodule
