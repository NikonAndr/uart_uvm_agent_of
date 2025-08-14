import uvm_pkg::*;
`include "uvm_macros.svh"

class driver_test extends uvm_test;
    `uvm_component_utils(driver_test)

    virtual uart_if vif;
    uart_sequencer sequencer;
    uart_driver driver;
    uart_agent_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Retrieve virtual interface from config DB
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a test")
        end
        //Retrieve cfg from DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a driver_test")
        end
        
        sequencer = uart_sequencer::type_id::create("sequencer", this);
        driver = uart_driver::type_id::create("driver", this);
        
        uvm_config_db#(virtual uart_if)    ::set(this, "driver", "vif",      vif);
        uvm_config_db#(uart_agent_config)  ::set(this, "driver", "uart_cfg", cfg);

    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction : connect_phase

    virtual task run_phase(uvm_phase phase);
        uart_tx_seq1 seq1 = uart_tx_seq1::type_id::create("seq1");
        uart_tx_seq2 seq2 = uart_tx_seq2::type_id::create("seq2");

        //Raise objection to keep simulation running 
        phase.raise_objection(this);

        //test waveform
        #10ns;
        //Start seq1, sends 10 transactions without errors
        seq1.start(sequencer);

        //10 us pause beetween seq1 and seq2
        #10us;
        $display("SEQ1 finished, starting SEQ2");

        //reset test 
        vif.rst <= 1;
        #1ms;
        vif.rst <= 0;

        //Start seq2, sends 10 transactions with random generated errors
        seq2.start(sequencer);

        //Wait for monitor to capture last transaction
        #100us

        //Drop objection to allow simulation to finish
        phase.drop_objection(this);
    endtask : run_phase 

endclass : driver_test 

