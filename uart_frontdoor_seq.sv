class uart_frontdoor_seq extends uvm_reg_frontdoor;
    `uvm_object_utils(uart_frontdoor_seq)

    function new(string name = "uart_frontdoor_seq");
        super.new(name);
    endfunction

    task send_byte(frame_type_e ft, byte b);
        uart_tx_item tx;
        tx = uart_tx_item::type_id::create("tx");

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

        //CMD : bit0 RW
        cmd = (rw_info.kind == UVM_WRITE) ? 8'h01 : 8'h00;
        send_byte(FRAME_CMD, cmd);

        //ADDR
        send_byte(FRAME_ADDR, byte'(rw_info.offset));
        `uvm_info("FD_DBG", $sformatf("FD %s offset=0x%0h",
            (rw_info.kind==UVM_WRITE)?"W":"R", byte'(rw_info.offset)), UVM_LOW)

        
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