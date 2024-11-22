interface wb_if (
    input logic wb_clk_i
);
    logic wb_rst_i;
    logic [7:0] wb_data_i;
    logic [7:0] wb_dat_o;
    logic [6:0] wb_adr_i;
    logic [3:0] wb_sel_i;
    logic wb_we_i;
    logic wb_cyc_i;
    logic wb_stb_i;
    logic wb_ack_o;
    logic wb_err_o;

    logic [3:0] SF_D;
    logic LCD_E;
    logic LCD_RS;
    logic LCD_RW;

endinterface
