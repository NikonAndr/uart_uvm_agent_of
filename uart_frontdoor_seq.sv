class uart_frontdoor_seq extends uvm_reg_frontdoor;
    `uvm_object_utils(uart_frontdoor_seq)

    function new(string name = "uart_frontdoor_seq");
        super.new(name);
    endfunction

    task send_byte(frame_type_e ft, byte b);
        uart_tx_item tx;
        tx = uart_tx_item::type_id::create($sformatf("tx"));

        tx.ft = ft;
        tx.data = b;
        tx.start_bit = 1'b0;
        tx.parity_bit = ^b;
        tx.stop_bit = 1'b1;

        start_item(tx);
        finish_item(tx);
    endtask : send_byte

    virtual task body();
        uvm_sequence_item base_rsp;
        uart_tx_item rsp;
        byte cmd;
        uvm_reg_addr_t addr;

        //Get addr from reg_model 
        uvm_reg_field field;
        uvm_reg register;

        if($cast(field, rw_info.element)) begin
            register = field.get_parent();
            addr = register.get_address(rw_info.map);
        end
        else if ($cast(register, rw_info.element)) begin
            addr = register.get_address(rw_info.map);
        end
        else begin
            `uvm_fatal("FD_ADDR", "Cannot get address from rw_info.element")
        end

        //CMD : bit0 RW
        cmd = (rw_info.kind == UVM_WRITE) ? 8'h01 : 8'h00;
        send_byte(FRAME_CMD, cmd);

        //ADDR
        send_byte(FRAME_ADDR, byte'(addr));
        
        if (rw_info.kind == UVM_WRITE) begin
            send_byte(FRAME_DATA, byte'(rw_info.value[0]));
        end else begin
            get_response(base_rsp);
            if(!$cast(rsp, base_rsp)) begin
                `uvm_fatal("FD_SEQ", "Response is not a tx item")
            end
            rw_info.value[0] = rsp.data;
        end
        rw_info.status = UVM_IS_OK;
    endtask : body
endclass : uart_frontdoor_seq