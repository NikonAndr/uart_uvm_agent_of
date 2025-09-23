typedef enum {FRAME_CMD, FRAME_ADDR, FRAME_DATA} frame_type_e;

class uart_tx_item extends uvm_sequence_item;
    //implemented tx transaction with fields declared random
    rand bit [7:0] data;
    rand bit start_bit;
    rand bit parity_bit;
    rand bit stop_bit;
    rand bit direction;

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

    function string print_tx();
        return $sformatf("%0b %8h %0b %0b",
            start_bit, data, parity_bit, stop_bit);
    endfunction : print_tx

endclass : uart_tx_item