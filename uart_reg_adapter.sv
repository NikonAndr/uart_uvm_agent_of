class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)
    
    function new(string name = "uart_reg_adapter");
        super.new(name);

        //Uart Bus Does Not Support Byte Enables 
        supports_byte_enable = 0;
        provides_responses = 1;
    endfunction

    //Convert Register Operation To Uart Transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        uart_tx_item tx;
        tx = uart_tx_item::type_id::create("tx");

        tx.ft = FRAME_CMD;
        tx.data = (rw.kind == UVM_WRITE) ? 8'h01 : 8'h00;

        tx.start_bit = 1'b0;
        tx.parity_bit = ^tx.data;
        tx.stop_bit = 1'b1;

        return tx;
    endfunction : reg2bus

    //Convert Uart Transaction Back To Register Operation
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        uart_tx_item tx;
        if (!$cast(tx, bus_item)) begin
            `uvm_fatal("ADAPTER", "bus_item is not uart_tx_item");
        end

        rw.kind   = (tx.data[0] == 1'b0) ? UVM_READ : UVM_WRITE;
        rw.addr   = tx.data[3:1];
        rw.data   = tx.data[7:4];
        rw.status = UVM_IS_OK;
    endfunction : bus2reg
endclass : uart_reg_adapter