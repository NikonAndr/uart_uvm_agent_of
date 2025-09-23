class uart_test_2_3 extends uvm_test;
    `uvm_component_utils(uart_test_2_3)

    uart_env env;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A1", "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A2", "is_active", UVM_ACTIVE);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        uvm_status_e status;
        uvm_reg_data_t w0, w1, r0, r1;

        phase.raise_objection(this);

        w0 = $urandom_range(0, 255);
        w1 = $urandom_range(0, 255);

        env.reg_block.R1.write(status, w0);
        env.reg_block.R2.write(status, w1);

        env.reg_block.R1.read(status, r0);
        env.reg_block.R2.read(status, r1);

        `uvm_info("TEST", $sformatf("Write %00h to R1, %00h to R2, Read %00h R1, %00h R2",
            w0, w1, r0, r1), UVM_MEDIUM)

        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_test_2_3
