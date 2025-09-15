class uart_test extends uvm_test;
    `uvm_component_utils(uart_test)

    virtual uart_if vif;
    uart_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Retrieve virtual interface from config DB
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a test")
        end

        //Pass virtual interface to agent
        uvm_config_db#(virtual uart_if)::set(this, "env.agent", "vif", vif);

        //Set Agent as Active
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.agent", "is_active", UVM_ACTIVE);
        env = uart_env::type_id::create("env", this);        

    endfunction : build_phase
endclass : uart_test

class uart_seq1_seq2_test extends uart_test;
    `uvm_component_utils(uart_seq1_seq2_test)

    uart_tx_seq1 seq1;
    uart_tx_seq2 seq2;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_tx_seq1 seq1 = uart_tx_seq1::type_id::create("seq1");
        uart_tx_seq2 seq2 = uart_tx_seq2::type_id::create("seq2");

        //Raise objection to keep simulation running 
        phase.raise_objection(this);

        //Start seq1, sends 10 transactions without errors
        seq1.start(env.agent.sequencer);

        //10 us pause beetween seq1 and seq2
        #10us;
        `uvm_info("SEQUENCE", "SEQ1 finished, Starting SEQ2!", UVM_MEDIUM)

        //Start seq2, sends 10 transactions with random generated errors
        seq2.start(env.agent.sequencer);

        //Drop objection, allow simulation to finish
        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_seq1_seq2_test

class uart_reg_test extends uart_test;
    `uvm_component_utils(uart_reg_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uvm_status_e   status;
        uvm_reg_data_t value;
        phase.raise_objection(this);

        //Reset Register Model 
        env.reg_block.reset();
        
        //Write Random Value Into R1, Check If Mirror Value == Written Value
        value = $urandom_range(0, 15);
        `uvm_info("REG TEST", $sformatf("Writing %0h to R1", value), UVM_MEDIUM)

        env.reg_block.R1.write(status, value);

        if (env.reg_block.R1.get_mirrored_value() != value) begin
            `uvm_error("MIRROR", $sformatf("Mismatch! Mirror=%0h Expected=%0h",
                    env.reg_block.R1.get_mirrored_value(), value))
        end else begin
            `uvm_info("MIRROR", $sformatf("OK: Mirror=%0h", value), UVM_LOW)
        end

        //Write Random Value to R2
        //Expect: Transaction Goes Out On Uart Tx, Mirror Remains Unchainged
        value = $urandom_range(0, 15);
        `uvm_info("REG TEST", $sformatf("Writing %0h to R2", value), UVM_MEDIUM)

        env.reg_block.R2.write(status, value);

        `uvm_info("MIRROR", $sformatf("R2 unchanged as R0: Mirror=%0h", env.reg_block.R2.get_mirrored_value()), UVM_LOW)

        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_reg_test
