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
    int no_of_tr;

    function new(string name = "valid_rand_seq");
        super.new(name);
    endfunction

    function void set_no_of_tr(int no_of_tr);
        this.no_of_tr = no_of_tr;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");
        repeat (no_of_tr) begin
            start_item(tr);
            tr.randomize() with {
                wb_rst_i == 0;
                wb_adr_i <= 7'd66;
            };
            finish_item(tr);
        end
    endtask

endclass
