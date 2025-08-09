class uart_driver extends uvm_driver#(uart_tx_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;
    uart_agent_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Retrieve virtual interface from config DB
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a driver")
        end

        //Retrieve configuration object from config DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a driver")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        uart_tx_item tx;

        @(negedge vif.rst);

        //After a reset, the TX signal should be 1
        vif.tx <= 1'b1; 

        forever begin
            //Get next transaction from sequencer
             seq_item_port.get_next_item(tx);

            //Driver sends start_bit
            vif.tx <= tx.start_bit;
            repeat (cfg.bit_time) @(posedge vif.clk);

            //Driver sends 8 bits of data LSB first
            for (int i = 0; i < 8; i++) begin
                vif.tx <= tx.data[i];
                repeat (cfg.bit_time) @(posedge vif.clk);
            end

            //Driver sends parity_bit
            vif.tx <= tx.parity_bit;
            repeat (cfg.bit_time) @(posedge vif.clk);

            //Driver sends stop_bit
            vif.tx <= tx.stop_bit;
            repeat (cfg.bit_time) @(posedge vif.clk);

            //Signal transaction is complete
            seq_item_port.item_done();
        end
    endtask : run_phase
endclass : uart_driver