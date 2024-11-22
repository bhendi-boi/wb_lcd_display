class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)

    transaction   tr;
    virtual wb_if vif;

    function new(string name = "driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wb_if)::get(this, "*", "vif", vif)) begin
            `uvm_fatal("Driver", "Couldn't access interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        tr = transaction::type_id::create("tr");

        forever begin
            seq_item_port.get_next_item(tr);
            drive(tr);
            `uvm_info("Driver", "Drove a transaction", UVM_NONE)
            tr.print();
            seq_item_port.item_done();
        end
    endtask

    task drive(transaction tr);
        if (tr.wb_rst_i) begin
            @(posedge vif.wb_clk_i);
            vif.wb_rst_i <= tr.wb_rst_i;
        end else begin
            if (tr.wb_we_i) begin
                @(posedge vif.wb_clk_i);
                vif.wb_rst_i <= 1'b0;
                vif.wb_we_i  <= tr.wb_we_i;
                vif.wb_stb_i <= 1'b1;
                vif.wb_cyc_i <= 1'b1;
                vif.wb_adr_i <= tr.wb_adr_i;
                vif.wb_dat_i <= tr.wb_dat_i;
                @(posedge vif.wb_ack_o);
                @(posedge vif.wb_clk_i);
                vif.wb_stb_i <= 1'b0;
                vif.wb_cyc_i <= 1'b0;
            end
        end
    endtask

endclass
