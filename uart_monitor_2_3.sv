class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if.monitor vif;
    uart_agent_config cfg;
    uart_monitor_events events;

    //Sends captured transactions to scoreboard or other components
    uvm_analysis_port #(uart_tx_item) analysis_port;

    time half_bit;
    bit is_master;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.monitor)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a monitor")
        end

        if(!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a monitor")
        end

        if(!uvm_config_db#(uart_monitor_events)::get(this, "", "monitor_events", events)) begin
            `uvm_fatal("NO_EVENTS", "Monitor events not set")
        end 

        half_bit = (cfg.var_ps * 1ps) / 2;
        is_master = cfg.is_master;
    endfunction : build_phase 

    virtual task run_phase(uvm_phase phase);
        if (is_master) begin
            monitor_master();
        end 
        else begin
            monitor_slave();
        end
    endtask : run_phase 

    function string sender();
        string parent_name = get_parent().get_name();
        if (parent_name == "A1")
            return "A2";
        else 
            return "A1";
    endfunction 

    task monitor_master();
        byte data;
        byte addr;

        forever begin
            if (vif.rst) @(negedge vif.rst);

            //Wait For Read Request 
            events.read_request.wait_on();
            addr = events.read_addr;
            events.read_request.reset();

            capture_frame_on_rx(data);
            
            //Monitor Log -> Read cmd
            `uvm_info("MONITOR", $sformatf("%s.READ.0x%0h.0x%0h",
                sender(), addr, data), UVM_MEDIUM)
        end
    endtask : monitor_master

    task monitor_slave();
        byte cmd;
        byte addr;
        byte data;
        bit is_write;
        
        forever begin
            if (vif.rst) @(negedge vif.rst);

            //Capture Cmd
            capture_frame_on_rx(cmd);
            is_write = cmd[0];

            //Capture Addr
            capture_frame_on_rx(addr);

            if (is_write) begin
                //Capture Data
                capture_frame_on_rx(data);

                //Monitor Log -> Write cmd 
                `uvm_info("MONITOR", $sformatf("%s.WRITE.0x%0h.0x%0h",
                    sender(), addr, data), UVM_MEDIUM)
            end 
            else begin
                events.trigger_read_request(addr);
            end
        end
    endtask : monitor_slave

    task capture_frame_on_rx(output byte data);
        bit aborted;

        @(negedge vif.rx);
        
        //Start Bit (Ignore)
        #half_bit;
        
        for (int i = 0; i < 8; i++) begin
            wait_half_bit_or_reset(aborted); if (aborted) return;
            #half_bit;
            data[i] = vif.rx;
        end

        //Parity Bit (Ignore)
        wait_half_bit_or_reset(aborted); if (aborted) return;
        #half_bit;

        //Stop Bit (Ignore)
        wait_half_bit_or_reset(aborted); if (aborted) return;
    endtask : capture_frame_on_rx
        
    task wait_half_bit_or_reset(output bit aborted);
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
    endtask : wait_half_bit_or_reset
endclass : uart_monitor




