class uart_driver extends uvm_driver#(uart_tx_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if.driver vif;
    uart_agent_config cfg;
    uart_reg_block reg_block;

    time full_bit;
    time half_bit; 

    typedef enum {WAIT_CMD, WAIT_ADDR, WAIT_DATA_WRITE} slave_state_e;
    slave_state_e slave_state;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_config_db#(uart_reg_block)::get(this, "", "reg_block", reg_block);

        if(!uvm_config_db#(virtual uart_if.driver)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "VIF not set for a Driver")
        end

        if(!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "Configuration object not set for a Driver")
        end 

        full_bit = (cfg.var_ps * 1ps);
        half_bit = (cfg.var_ps * 1ps) / 2;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        fork
            reset_thread();
            if (cfg.is_master) begin
                master_thread();
            end 
            else begin
                slave_thread();
            end
        join_none
    endtask : run_phase

    task reset_thread();
        forever begin
            @(posedge vif.rst);

            vif.tx <= 1'b1;

            @(negedge vif.rst);
            vif.tx <= 1'b1;
        end 
    endtask : reset_thread
    
    task master_thread();
        uart_tx_item tx;
        uart_tx_item rx;
        bit got_item;
        bit is_write;
        byte addr;
        bit aborted;

        vif.tx <= 1'bx;

        forever begin 
            wait (vif.rst == 0);
            
            next_item_or_reset(tx, got_item);
            if (!got_item) continue;

            if (tx.ft != FRAME_CMD) begin
                `uvm_error("DRIVER_MASTER", $sformatf("Error: Expected FRAME_CMD got %s",
                    tx.ft.name()))
                seq_item_port.item_done();
                continue;
            end

            //CMD
            send_uart_frame(tx);
            is_write = tx.data[0];
            seq_item_port.item_done();

            next_item_or_reset(tx, got_item);
            if (!got_item) continue;

            if (tx.ft != FRAME_ADDR) begin
                `uvm_error("DRIVER_MASTER", $sformatf("Error: Expected FRAME_ADDR got %s",
                    tx.ft.name()))
                seq_item_port.item_done();
                continue;
            end

            //ADDR 
            send_uart_frame(tx);
            `uvm_info("DRIVER_MASTER", $sformatf("SENT ADDRESS %s", tx.print_tx()), UVM_MEDIUM)
            addr = tx.data;
            seq_item_port.item_done();

            //IF WRITE
            if (is_write) begin
                next_item_or_reset(tx, got_item);
                if (!got_item) continue;

                if (tx.ft != FRAME_DATA) begin
                    `uvm_error("DRIVER_MASTER", $sformatf("Error: Expected FRAME_DATA got %s",
                        tx.ft.name()))
                    seq_item_port.item_done();
                    continue;
                end

                //DATA
                send_uart_frame(tx);
                seq_item_port.item_done();
            end
            //IF READ
            else begin
                get_uart_frame(rx);
                rx.ft = FRAME_DATA;

                rx.set_id_info(tx);
                seq_item_port.put_response(rx);
            end
        end
    endtask : master_thread

    task slave_thread();
        uart_tx_item tx;
        uart_tx_item rx;
        bit is_write;
        byte addr;

        slave_state = WAIT_CMD;
        vif.tx <= 1'b1;

        forever begin
            wait (vif.rst == 0);

            case (slave_state)
                WAIT_CMD : begin
                    get_uart_frame(rx);
                    is_write = rx.data[0];
                    slave_state = WAIT_ADDR;
                end
                WAIT_ADDR : begin
                    get_uart_frame(rx);
                    `uvm_info("DRIVER_SLAVE", $sformatf("GOT ADDRESS %s", rx.print_tx()), UVM_MEDIUM)
                    addr = rx.data;

                    if (is_write) begin 
                        slave_state = WAIT_DATA_WRITE;
                    end 
                    //READ COMMAND
                    else begin
                        tx = uart_tx_item::type_id::create("tx");

                        tx.ft = FRAME_DATA;
                        tx.start_bit = 1'b0;

                        if (addr == 8'h0) begin
                            tx.data = reg_block.R1.get_mirrored_value();
                        end
                        else if (addr == 8'h1) begin
                            tx.data = reg_block.R2.get_mirrored_value();
                        end 
                        else begin
                            tx.data = 8'hff;
                            `uvm_error("DRIVER_SLAVE", "Unknown Address")
                        end

                        tx.parity_bit = ^tx.data;
                        tx.stop_bit = 1'b1;

                        send_uart_frame(tx);
                        slave_state = WAIT_CMD;
                    end
                end
                WAIT_DATA_WRITE : begin
                    get_uart_frame(rx);
                    
                    if (!(addr inside {8'h0, 8'h1})) begin
                        `uvm_error("DRIVER_SLAVE", "Unknown Address")
                    end

                    slave_state = WAIT_CMD;
                end
            endcase
        end
    endtask : slave_thread

    task next_item_or_reset(output uart_tx_item tx, output bit got_item);
        process p_get;
        process p_rst;
        tx = null;
        got_item = 1'b0;

        fork
            begin : get_item
                p_get = process::self();
                seq_item_port.get_next_item(tx);
                got_item = 1'b1;
            end
            begin : rst
                p_rst = process::self();
                @(posedge vif.rst);
            end
        join_any
        disable fork;

        if (p_get != null && p_get.status==process::RUNNING) p_get.kill();
        if (p_rst != null && p_rst.status==process::RUNNING) p_rst.kill();
    endtask : next_item_or_reset

    task automatic wait_bit_or_reset(time wait_time, output bit aborted);
        aborted = 1'b0;

        if (vif.rst) begin
            aborted = 1'b1; return;
        end 

        fork
            begin : timer
                #wait_time;
            end
            begin : rst 
                @(posedge vif.rst);
                aborted = 1'b1;
            end
        join_any
        disable fork;
    endtask : wait_bit_or_reset

    task drive_bit_and_wait(bit val, time wait_time, output bit aborted);
        aborted = 1'b0;

        if (vif.rst) begin
            aborted = 1'b1;
            return;
        end 

        vif.tx <= val;
        wait_bit_or_reset(wait_time, aborted);
    endtask : drive_bit_and_wait

    task send_uart_frame(uart_tx_item tx);
        bit aborted;

        drive_bit_and_wait(tx.start_bit, full_bit, aborted);
        if (aborted) return;

        for (int i = 0; i < 8; i++) begin
            drive_bit_and_wait(tx.data[i], full_bit, aborted);
            if (aborted) return;
        end

        drive_bit_and_wait(tx.parity_bit, full_bit, aborted);
        if (aborted) return;

        drive_bit_and_wait(tx.stop_bit, full_bit, aborted);
        if (aborted) return;

        //After Stop Bit Return To idle 
        vif.tx <= 1'b1;
    endtask : send_uart_frame 

    task get_uart_frame(output uart_tx_item rx);
        bit aborted;
        rx =uart_tx_item::type_id::create("rx");

        @(negedge vif.rx);

        wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        rx.start_bit = vif.rx;
        wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        
        for (int i = 0; i < 8; i++) begin
            wait_bit_or_reset(half_bit, aborted); if (aborted) return;
            rx.data[i] = vif.rx;
            wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        end

        wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        rx.parity_bit = vif.rx;
        wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        
        wait_bit_or_reset(half_bit, aborted); if (aborted) return;
        rx.stop_bit = vif.rx;
    endtask : get_uart_frame 
endclass : uart_driver
    

        


