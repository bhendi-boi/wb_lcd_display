class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    transaction tr;
    virtual wb_if vif;
    uvm_analysis_port #(transaction) monitor_port;

    function new(string name = "monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_port = new("monitor_port", this);
        if (!uvm_config_db#(virtual wb_if)::get(this, "*", "vif", vif)) begin
            `uvm_fatal("Monitor", "Couldn't get the interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        tr = transaction::type_id::create("tr");
        @(posedge vif.wb_clk_i);
        // the above line ensures monitor and driver are in sync
        forever begin
            capture(tr);
            `uvm_info("Monitor", "Sampled a transaction", UVM_NONE)
            tr.print();
            monitor_port.write(tr);
        end
    endtask

    task capture(transaction tr);
        @(posedge vif.wb_clk_i);
        tr.wb_rst_i = vif.wb_rst_i;
        if (tr.wb_rst_i) begin
            /* `uvm_info("Monitor", "Reset detected", UVM_NONE) */
            return;
        end
        @(posedge vif.wb_ack_o);
        tr.wb_we_i   = vif.wb_we_i;
        tr.wb_addr_i = vif.wb_addr_i;
        tr.wb_data_i = vif.wb_data_i;
        tr.wb_data_o = vif.wb_data_o;
        @(posedge vif.wb_clk_i);
        // waiting for strb to go low
    endtask

endclass
