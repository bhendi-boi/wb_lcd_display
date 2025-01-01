class rand_test extends uvm_test;
    `uvm_component_utils(rand_test)

    environment env;

    reset_seq rs;
    valid_rand_seq vs;

    function new(string name = "rand_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = environment::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);

        rs = reset_seq::type_id::create("rs");
        vs = valid_rand_seq::type_id::create("vs");
        vs.set_no_of_tr(1);

        rs.start(env.agnt.seqr);
        vs.start(env.agnt.seqr);

        #10000;
        phase.drop_objection(this);
    endtask

endclass
