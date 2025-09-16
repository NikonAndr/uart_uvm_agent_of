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
        uart_op_item it;
        it = uart_op_item::type_id::create("op");

        it.is_read = (rw.kind == UVM_READ);
        it.addr = rw.addr[7:0];
        it.data = rw.data[7:0];

        return it;
    endfunction : reg2bus

    //Convert Uart Transaction Back To Register Operation
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        rw.status = UVM_IS_OK;
    endfunction : bus2reg
endclass : uart_reg_adapter