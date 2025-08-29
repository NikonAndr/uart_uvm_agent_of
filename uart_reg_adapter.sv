class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)
    
    function new(string name = "uart_reg_adapter");
        super.new(name);

        //Uart Bus Does Not Support Byte Enables Or Responses
        supports_byte_enable = 0;
        provides_responses = 0;
    endfunction

    //Convert Register Operation To Uart Transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        uart_tx_item tx;
        tx = uart_tx_item::type_id::create("tx");

        //Operation Type Write/Read
        tx.data[0] = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
        //Register Address
        tx.data[3:1] = rw.addr[2:0];
        //Data Payload
        tx.data[7:4] = rw.data[3:0];
        //Add Uart Frame Fields
        tx.start_bit = 1'b0;
        tx.parity_bit = ^tx.data;
        tx.stop_bit = 1'b1;

        //Print Uart Transaction
        `uvm_info("ADAPTER",
            $sformatf("UART pkt: op=%s addr=0x%0h data 0x%0h byte 0x%02h",
                (rw.kind == UVM_WRITE) ? "W" : "R", rw.addr[2:0], rw.data[3:0], tx.data), UVM_MEDIUM)
        return tx;
    endfunction : reg2bus

    //Convert Uart Transaction Back To Register Operation
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        uart_tx_item tx;

        //Ensure Proper Type Cast
        if (!$cast(tx, bus_item)) begin
            `uvm_fatal("ADAPTER", "Casting bus to uart_tx_item failed!")
        end

        //Decode Operation, Address and Data
        rw.kind = (tx.data[0] == 1'b1) ? UVM_WRITE : UVM_READ;
        rw.addr = tx.data[3:1];
        rw.data = tx.data[7:4];
        rw.status = UVM_IS_OK;
    endfunction : bus2reg
endclass : uart_reg_adapter