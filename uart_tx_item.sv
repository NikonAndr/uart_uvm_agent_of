typedef enum {FRAME_CMD, FRAME_ADDR, FRAME_DATA} frame_type_e;

class uart_tx_item extends uvm_sequence_item;
    //implemented tx transaction with fields declared random
    rand bit [7:0] data;
    rand bit start_bit;
    rand bit parity_bit;
    rand bit stop_bit;

    frame_type_e ft;

    //implemented constraints for start_bit, stop_bit, parity_bit
    constraint valid_bits {
        start_bit == 1'b0;
        parity_bit == ^data;
        stop_bit == 1'b1;
    }

    `uvm_object_utils(uart_tx_item)

    function new(string name = "uart_tx_item");
        super.new(name);
    endfunction

    //print_tx function: start_bit data parity_bit stop_bit
    function string print_tx();
        return $sformatf("[%s] TX TRANSACTION: %0b %08b %0b %0b", ft.name(), start_bit, data, parity_bit, stop_bit);
    endfunction : print_tx
endclass : uart_tx_item