class uart_test_2_2 extends uvm_test;
    `uvm_component_utils(uart_test_2_2)

    uart_env_2_2 env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        env = uart_env_2_2::type_id::create("env", this);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A1", "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A2", "is_active", UVM_ACTIVE);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        uart_3x3_seq seqA1 = uart_3x3_seq::type_id::create("seqA1");
        uart_3x3_seq seqA2 = uart_3x3_seq::type_id::create("seqA2");

        phase.raise_objection(this);

        fork
            seqA1.start(env.A1.sequencer);
            seqA2.start(env.A2.sequencer);
        join

        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_test_2_2
