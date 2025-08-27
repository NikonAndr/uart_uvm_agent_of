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
        //Added vif == null error handle
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif) || vif == null) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a driver")
        end

        //Retrieve configuration object from config DB
        //Added cfg == null error handle 
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a driver")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        uart_tx_item tx;

        //Before Reset tx Value Should Be X
        vif.tx <= 1'bx;

        forever begin
            if (vif.rst) begin 
                drive_idle_during_reset();
                continue;
            end
            
            seq_item_port.get_next_item(tx);
            send_uart_frame(tx);
            seq_item_port.item_done();
        end 
    endtask : run_phase

    task drive_idle_during_reset();
        vif.tx <= 1'b1;
        @(negedge vif.rst);
        //Run Idle until start bit
        vif.tx <= 1'b1;
    endtask : drive_idle_during_reset

    task automatic wait_bit_or_reset(output bit aborted);
        aborted = 0;

        //Pre Check For Reset
        if (vif.rst) begin
            aborted = 1;
            return;
        end

        //Check For Reset During Current Bit 
        fork : waiters 
            begin : timer
                #(cfg.var_ps * 1ps);
            end 
            begin : reset
                @(posedge vif.rst);
                aborted = 1;
            end 
        join_any 
        disable waiters;
    endtask : wait_bit_or_reset

    task automatic drive_bit_and_wait(bit val, output bit aborted);
        //Pre Check For Reset
        if (vif.rst) begin
            aborted = 1;
            return;
        end

        vif.tx <= val;
        wait_bit_or_reset(aborted);
    endtask : drive_bit_and_wait

    task send_uart_frame(uart_tx_item tx);
        bit aborted;

        drive_bit_and_wait(tx.start_bit, aborted);
        if (aborted) return;

        for (int i = 0; i < 8; i++) begin
            drive_bit_and_wait(tx.data[i], aborted);
            if (aborted) return;
        end

        drive_bit_and_wait(tx.parity_bit, aborted);
        if (aborted) return;

        drive_bit_and_wait(tx.stop_bit, aborted);
        if (aborted) return;

        //After Stop Bit Return To idle 
        vif.tx <= 1'b1;

    endtask : send_uart_frame   
endclass : uart_driver