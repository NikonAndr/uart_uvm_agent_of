class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if vif;
    uart_agent_config cfg;
    //Sends captured transactions to scoreboard or other components
    uvm_analysis_port #(uart_tx_item) analysis_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Retrieve virtual interface from config DB
        if(!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin 
            `uvm_fatal("NO_VIF", "Virtual interface not set for a monitor")
        end 

        //Retrieve configuration from config DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a monitor")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);

        uart_tx_item tx;

        //Wait for reset before monitoring
        @(negedge vif.rst);
        
        forever begin
            //Wait for a start bit 
            wait (vif.tx == 0);

            tx = uart_tx_item::type_id::create("tx");

            //Read bit values in the middle of bit time 
            repeat (cfg.bit_time / 2) @(posedge vif.clk);
            tx.start_bit = vif.tx;
            repeat (cfg.bit_time / 2) @(posedge vif.clk);

            for (int i = 0; i < 8; i++) begin
                repeat (cfg.bit_time / 2) @(posedge vif.clk);
                tx.data[i] = vif.tx;
                repeat (cfg.bit_time / 2) @(posedge vif.clk);
            end

            repeat (cfg.bit_time / 2) @(posedge vif.clk);
            tx.parity_bit = vif.tx;
            repeat (cfg.bit_time / 2) @(posedge vif.clk);

            repeat (cfg.bit_time / 2) @(posedge vif.clk);
            tx.stop_bit = vif.tx;
            repeat (cfg.bit_time / 2) @(posedge vif.clk);

            //Monitor console log 
            `uvm_info("MONITOR", $sformatf("MONITOR captured %s", tx.print_tx()), UVM_MEDIUM)

            analysis_port.write(tx);
        end
    endtask : run_phase
endclass : uart_monitor