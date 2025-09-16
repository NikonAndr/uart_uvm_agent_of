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
        byte cmd;
        byte data_b;

        //CMD : bit0 RW
        cmd = (rw_info.kind == UVM_WRITE) ? 8'h01 : 8'h00;
        send_byte(FRAME_CMD, cmd);

        //ADDR
        send_byte(FRAME_ADDR, byte'(rw_info.offset));

       

        if (rw_info.kind == UVM_WRITE) begin
            data_b = byte'(rw_info.value[0]);
        end else begin
            //Placeholder For Read
            data_b = 8'h00;
        end
        send_byte(FRAME_DATA, data_b);

        rw_info.status = UVM_IS_OK;
    endtask : body
endclass : uart_frontdoor_seq