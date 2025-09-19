class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if.monitor vif;
    uart_agent_config cfg;
    //Sends captured transactions to scoreboard or other components
    uvm_analysis_port #(uart_tx_item) analysis_port;

    time half_bit;
         
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Retrieve virtual interface from config DB
        if(!uvm_config_db#(virtual uart_if.monitor)::get(this, "", "vif", vif)) begin 
            `uvm_fatal("NO_VIF", "Virtual interface not set for a monitor")
        end 

        //Retrieve configuration from config DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a monitor")
        end

        //Calculate Half Bit time
        half_bit = (cfg.var_ps * 1ps) / 2;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_line(1);
            monitor_line(0);
        join_none
    endtask : run_phase

    task automatic monitor_line(bit direction);
        uart_tx_item tx;
        string agent_name;
        string sender;

        forever begin 
            if (vif.rst) @(negedge vif.rst);

            if (direction) begin
                wait (vif.tx == 0);
                #0;

                tx = uart_tx_item::type_id::create("tx");
                capture_uart_frame(tx, direction);
            end else begin
                wait (vif.rx == 0);
                #0;

                tx = uart_tx_item::type_id::create("tx");
                capture_uart_frame(tx, direction);
            end

            agent_name = get_parent().get_name();

            tx.direction = direction;

            analysis_port.write(tx);
            
            if (!direction) begin 
                sender = (agent_name == "A1") ? "A2" : "A1";

                `uvm_info("MONITOR",
                    $sformatf("%s.%s", sender, tx.print_tx()), UVM_MEDIUM
                );
            end 
        end
    endtask : monitor_line

    task automatic wait_bit_or_reset(output bit aborted);
        aborted = 0;

        //Pre Check For Reset
        if (vif.rst) begin
            aborted = 1;
            return;
        end

        //Check For Reset During Current Bit 
        fork  
            begin : timer
                #half_bit;
            end 
            begin : reset
                @(posedge vif.rst);
                aborted = 1;
            end 
        join_any 
        disable fork;
    endtask : wait_bit_or_reset

    function logic get_line(bit direction);
        return (direction) ? vif.tx : vif.rx;
    endfunction : get_line

    task automatic capture_uart_frame(uart_tx_item tx/*, int frame_count*/,bit direction);
        bit aborted;
        
        #half_bit
        tx.start_bit = get_line(direction);
        wait_bit_or_reset(aborted);
        if (aborted) return;

        for (int i = 0; i < 8; i++) begin
            #half_bit;
            tx.data[i] = get_line(direction);
            wait_bit_or_reset(aborted);
            if (aborted) return;
        end

        #half_bit;
        tx.parity_bit = get_line(direction);
        wait_bit_or_reset(aborted);
        if (aborted) return;

        #half_bit;
        tx.stop_bit = get_line(direction);

        //Set Frame Type
        /*case (frame_count % 3)
            0: tx.ft = FRAME_CMD;
            1: tx.ft = FRAME_ADDR;
            2: tx.ft = FRAME_DATA;
        endcase
        */
    endtask : capture_uart_frame  
endclass : uart_monitor