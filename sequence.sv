class reset_seq extends uvm_sequence;
    `uvm_object_utils(reset_seq)

    transaction tr;

    function new(string name = "reset_seq");
        super.new(name);
    endfunction

    task body();
        tr = transaction::type_id::create("tr");
        `uvm_do_with(tr, {wb_rst_i == 1;});
    endtask

endclass
