class uart_driver extends uvm_driver#(uart_tx_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if.driver vif;
    uart_agent_config cfg;
    uart_reg_block reg_block;
    
    time half_bit;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_config_db#(uart_reg_block)::get(this, "", "reg_block", reg_block);

        //Retrieve virtual interface from config DB
        if (!uvm_config_db#(virtual uart_if.driver)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for a driver")
        end

        //Retrieve configuration object from config DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for a driver")
        end

        half_bit = (cfg.var_ps * 1ps) / 2;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        if (cfg.is_master) begin
            run_master(phase);
        end 
        else begin
            run_slave(phase);
        end
    endtask : run_phase

    task run_master(uvm_phase phase);
        uart_tx_item tx;
        uart_tx_item rx;
        byte addr;

        //Before Reset tx Value Should Be X
        vif.tx <= 1'bx;

        forever begin
            bit got_reset;
            process p_get;
            process p_rst;
            
            got_reset = 0;

            if (vif.rst) begin 
                drive_idle_during_reset();
                continue;
            end

            fork
                begin : get_item
                    p_get = process::self();
                    //Get CMD
                    seq_item_port.get_next_item(tx);

                    if (tx.ft == FRAME_CMD && tx.data[0] == 1'b0) begin
                        //READ Request 
                        //Send CMD
                        send_uart_frame(tx); 
                        `uvm_info("DRIVER MASTER", $sformatf("Driver sent %s %s", tx.print_tx(), tx.ft.name()), UVM_MEDIUM)
                        seq_item_port.item_done();
                        
                        //Send ADDR
                        seq_item_port.get_next_item(tx);
                        send_uart_frame(tx);
                        `uvm_info("DRIVER MASTER", $sformatf("Driver sent %s %s", tx.print_tx(), tx.ft.name()), UVM_MEDIUM)
                        addr = tx.data;
                        seq_item_port.item_done();

                        //Get Response From Slave
                        get_uart_frame(rx);
                        rx.ft = FRAME_DATA;
                        `uvm_info("DRIVER MASTER", $sformatf("Driver got %s %s", rx.print_tx(), rx.ft.name()), UVM_MEDIUM)
                        
                        rx.set_id_info(tx);

                        seq_item_port.put_response(rx);
                        
                        /*`uvm_info("MASTER", $sformatf("[%s] got READ response: addr=%0h data=%0h",
                            get_parent().get_name(), addr, rx.data), UVM_MEDIUM)*/
                    end 
                    else if (tx.ft == FRAME_CMD && tx.data[0] == 1'b1) begin
                        //WRITE Request
                        //Send CMD
                        send_uart_frame(tx); 
                        `uvm_info("DRIVER MASTER", $sformatf("Driver sent %s %s", tx.print_tx(), tx.ft.name()), UVM_MEDIUM)
                        seq_item_port.item_done();

                        //Send ADDR
                        seq_item_port.get_next_item(tx);
                        send_uart_frame(tx);
                        `uvm_info("DRIVER MASTER", $sformatf("Driver sent %s %s", tx.print_tx(), tx.ft.name()), UVM_MEDIUM)
                        addr = tx.data;
                        seq_item_port.item_done();

                        //Send DATA
                        seq_item_port.get_next_item(tx);
                        send_uart_frame(tx);
                        `uvm_info("DRIVER MASTER", $sformatf("Driver sent %s %s", tx.print_tx(), tx.ft.name()), UVM_MEDIUM)
                        seq_item_port.item_done();

                        /*`uvm_info("MASTER", $sformatf("[%s] sent WRITE addr=%0h",
                            get_parent().get_name(), addr), UVM_MEDIUM)*/
                    end
                end
                begin : wait_rst
                    p_rst = process::self();
                    @(posedge vif.rst);
                    got_reset = 1;
                end
            join_any

            if (p_get != null && p_get.status==process::RUNNING) p_get.kill();
            if (p_rst != null && p_rst.status==process::RUNNING) p_rst.kill();

            if (got_reset) begin
                drive_idle_during_reset();
                continue;
            end
        end 
    endtask : run_master

    task run_slave(uvm_phase phase);
        uart_tx_item tx;
        uart_tx_item rx;
        bit is_read;
        byte addr;

        forever begin
            get_uart_frame(rx);

            is_read = (rx.data[0] == 1'b0) ? 1'b1 : 1'b0;

            get_uart_frame(rx);
            `uvm_info("DRIVER SLAVE", $sformatf("DRIVER GOT %s", rx.ft.name()), UVM_MEDIUM)
            

            if (rx.ft != FRAME_ADDR) begin
                `uvm_error("UART_SLAVE", $sformatf("Expected ADDR, got %s", rx.ft.name()));
                continue;
            end

            addr = rx.data;

            if (is_read) begin
                byte mirror_val;
                if (addr == 8'h0) begin
                    mirror_val = reg_block.R1.get_mirrored_value();
                end
                else if (addr == 8'h1) begin
                    mirror_val = reg_block.R2.get_mirrored_value();
                end 
                else begin
                    //Uknown Address
                    mirror_val = 8'hFF;
                end 
                
                tx = uart_tx_item::type_id::create("tx");
                tx.ft = FRAME_DATA;
                tx.start_bit = 1'b0;
                tx.data = mirror_val;
                tx.parity_bit = ^mirror_val;
                tx.stop_bit = 1'b1;

                send_uart_frame(tx);
                `uvm_info("UART_SLAVE", $sformatf("[%s] sent READ response: addr=%0h data=%0h",
                    get_parent().get_name(), addr, mirror_val), UVM_MEDIUM)
            end else begin
                get_uart_frame(rx);

                if (addr == 8'h0) begin
                    reg_block.R1.predict(rx.data);
                end 
                else if (addr == 8'h1) begin
                    reg_block.R2.predict(rx.data);
                end

                `uvm_info("UART_SLAVE", $sformatf("[%s] WRITE addr=%0h data=%0h",
                    get_parent().get_name(), addr, rx.data), UVM_MEDIUM)
            end
        end
    endtask : run_slave

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
        fork
            begin : timer
                #(cfg.var_ps * 1ps);
            end 
            begin : reset
                @(posedge vif.rst);
                aborted = 1;
            end 
        join_any 
        disable fork;
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

    task get_uart_frame(output uart_tx_item rx);
        bit aborted;

        rx = uart_tx_item::type_id::create("rx");

        @(negedge vif.rx);
        
        #half_bit
        rx.start_bit = vif.rx;
        wait_bit_or_reset(aborted);
        if (aborted) return;

        for (int i = 0; i < 8; i++) begin
            rx.data[i] = vif.rx;
            wait_bit_or_reset(aborted);
            if (aborted) return;
        end

        rx.parity_bit = vif.rx;
        wait_bit_or_reset(aborted);
        if (aborted) return;

        rx.stop_bit = vif.rx;

    endtask : get_uart_frame
endclass : uart_driver