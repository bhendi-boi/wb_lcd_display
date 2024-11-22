class reset_seq extends uvm_sequence;
    `uvm_object_utils(reset_seq)

    transaction tr;

    function new(string name = "reset_seq");
        super.new(name);
    endfunction

    task body();
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.randomize() with {
            wb_rst_i == 1;
        };
        finish_item(tr);
    endtask

endclass

class valid_rand_seq extends uvm_sequence;
    `uvm_object_utils(valid_rand_seq)

    transaction tr;

    function new(string name = "valid_rand_seq");
        super.new(name);
    endfunction

    task body();
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.randomize() with {
            wb_rst_i == 0;
        };
        finish_item(tr);
    endtask

endclass
