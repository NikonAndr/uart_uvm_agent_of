class uart_op_item extends uvm_sequence_item;
    `uvm_object_utils(uart_op_item)

    bit is_read;
    bit [7:0] addr;
    bit [7:0] data;

    function new(string name = "uart_op_item");
        super.new(name);
    endfunction

endclass : uart_op_item