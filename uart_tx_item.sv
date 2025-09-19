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

    //Decode Transaction 
    function string print_tx();
        return $sformatf("%s.0x%0h.0x%0h",
            (data[0]) ? "WRITE" : "READ",
            data[3:1],
            data[7:4],        
        );
    endfunction : print_tx
endclass : uart_tx_item