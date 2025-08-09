class uart_test extends uvm_test;
    `uvm_component_utils(uart_test)

    virtual uart_if vif;
    uart_agent agent;

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
        uvm_config_db#(virtual uart_if)::set(this, "agent", "vif", vif);

        agent = uart_agent::type_id::create("agent", this);
        
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

        seq1 = uart_tx_seq1::type_id::create("seq1");
        seq2 = uart_tx_seq2::type_id::create("seq2");

        //Raise objection to keep simulation running 
        phase.raise_objection(this);

        //Start seq1, sends 10 transactions without errors
        seq1.start(agent.sequencer);

        //10 us pause beetween seq1 and seq2
        #(10000)
        $display("SEQ1 finished, starting SEQ2");

        //Start seq2, sends 10 transactions with random generated errors
        seq2.start(agent.sequencer);

        //Wait for monitor to capture last transaction
        #(100000);


        //Drop objection to allow simulation to finish
        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_seq1_seq2_test