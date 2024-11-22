class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)

    // inputs
    rand logic wb_rst_i;
    rand logic [7:0] wb_data_i;
    rand logic [7:0] wb_dat_o;
    rand logic [6:0] wb_adr_i;
    rand logic [3:0] wb_sel_i;
    rand logic wb_we_i;
    rand logic wb_cyc_i;
    rand logic wb_stb_i;

    // outputs
    logic wb_ack_o;
    logic wb_err_o;

    function new(string name = "transaction");
        super.new(name);
    endfunction


    function void do_print(uvm_printer printer);
        super.do_print(printer);
        printer.print_field_int("Reset", wb_rst_i, 1, UVM_HEX);
        printer.print_field_int("Write/Read", wb_we_i, 1, UVM_HEX);
        printer.print_field_int("Address", wb_adr_i, 7, UVM_HEX);
        printer.print_field_int("Byte select", wb_sel_i, 4, UVM_HEX);
        printer.print_field_int("Write Data", wb_data_i, 8, UVM_HEX);
        printer.print_field_int("Read Data", wb_dat_o, 8, UVM_HEX);
    endfunction

endclass
