class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)
    
    function new(string name = "uart_reg_adapter");
        super.new(name);

        //Uart Bus Does Not Support Byte Enables 
        supports_byte_enable = 0;
        provides_responses = 1;
    endfunction

    //Reg2Bus & Bus2Reg functions are not used in this TB,
    //however they have to be implemented
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        return null;
    endfunction : reg2bus

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        rw.status = UVM_IS_OK;
    endfunction : bus2reg
    
endclass : uart_reg_adapter