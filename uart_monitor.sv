class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if.monitor vif;
    uart_agent_config cfg;
    //Sends captured transactions to scoreboard or other components
    uvm_analysis_port #(uart_tx_item) analysis_port;

    time half_bit;

    typedef enum {WAIT_CMD, WAIT_ADDR, WAIT_DATA} monitor_state_e;
    monitor_state_e state_tx, state_rx;

    bit tx_is_write;
    byte tx_addr;

    bit rx_is_write;
    bit rx_addr;

    bit pending_read_expect_rx;
    bit pending_read_addr_rx;
    bit pending_read_expect_tx;
    bit pending_read_addr_tx;


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

        state_tx = WAIT_CMD;
        state_rx = WAIT_CMD;
        tx_is_write = 1'b0;
        tx_addr = 8'h0;

        pending_read_expect_rx = 1'b0;
        pending_read_addr_rx = 8'h0;
        pending_read_expect_tx = 1'b0;
        pending_read_addr_tx = 8'h0;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_line(1);
            monitor_line(0);
        join_none
    endtask : run_phase

    //Returns Name Of A Parent Agent
    function string who();
        return get_parent().get_name();
    endfunction : who

    function logic get_line(bit direction);
        return (direction) ? vif.tx : vif.rx;
    endfunction : get_line

    function void monitor_log(string cmd, byte addr, byte data);
        `uvm_info("MONITOR", $sformatf("%s.%s.0x%0h.0x%0h",
            who(), cmd, addr, data), UVM_MEDIUM)
    endfunction : monitor_log

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

    task automatic capture_uart_frame(uart_tx_item tx, bit direction);
        bit aborted;

        //1 -> vif.tx, 0 -> vif.rx
        if (direction) begin
            @(negedge vif.tx);
        end 
        else begin
            @(negedge vif.rx);
        end
        
        #half_bit
        tx.start_bit = get_line(direction);

        wait_bit_or_reset(aborted); if (aborted) return;
        
        for (int i = 0; i < 8; i++) begin
            #half_bit;
            tx.data[i] = get_line(direction);
            wait_bit_or_reset(aborted); if (aborted) return;
        end

        #half_bit;
        tx.parity_bit = get_line(direction);
        wait_bit_or_reset(aborted); if (aborted) return;
        
        #half_bit;
        tx.stop_bit = get_line(direction);        
    endtask : capture_uart_frame  

    task automatic monitor_line(bit direction);
        uart_tx_item tx;

        forever begin 
            if (vif.rst) @(negedge vif.rst);

            tx = uart_tx_item::type_id::create("tx");
            capture_uart_frame(tx, direction);
            tx.direction = direction;

            if (direction) begin : on_tx
                case (state_tx)
                    WAIT_CMD: begin
                        tx.ft = FRAME_CMD;
                        tx_is_write = tx.data[0];
                        state_tx = WAIT_ADDR;
                    end
                    WAIT_ADDR: begin
                        tx.ft = FRAME_ADDR;
                        tx_addr = tx.data;
                        if (tx_is_write) begin 
                            state_tx = WAIT_DATA;
                        end 
                        else begin 
                            //READ request from Master
                            pending_read_expect_rx = 1'b1;
                            pending_read_addr_rx = tx_addr;
                            state_tx = WAIT_CMD;
                        end
                    end
                    WAIT_DATA: begin
                        tx.ft = FRAME_DATA;
                        monitor_log("WRITE", tx_addr, tx.data);
                        state_tx = WAIT_CMD;
                    end
                endcase 

                if (pending_read_expect_tx) begin 
                    tx.ft = FRAME_DATA;
                    monitor_log("READ", pending_read_addr_tx, tx.data);
                    pending_read_expect_tx = 1'b0;
                end
            end
            else begin : on_rx
                case (state_rx)
                    WAIT_CMD: begin
                        tx.ft = FRAME_CMD;
                        rx_is_write = tx.data[0];
                        state_rx = WAIT_ADDR;
                    end
                    WAIT_ADDR: begin
                        tx.ft = FRAME_ADDR;
                        rx_addr = tx.data;
                        if (rx_is_write) begin 
                            state_rx = WAIT_DATA;
                        end 
                        else begin 
                            //READ request from Master
                            pending_read_expect_tx = 1'b1;
                            pending_read_addr_tx = rx_addr;
                            state_rx = WAIT_CMD;
                        end
                    end
                    default : state_rx = WAIT_CMD;
                endcase 

                if (pending_read_expect_rx) begin
                    tx.ft = FRAME_DATA;
                    monitor_log("READ", pending_read_addr_rx, tx.data);
                    pending_read_expect_rx = 1'b0;
                end
            end

            analysis_port.write(tx);              
        end
    endtask : monitor_line
endclass : uart_monitor