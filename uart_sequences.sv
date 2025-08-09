//seq1 Randomly sends 10 transactions
class uart_tx_seq1 extends uvm_sequence #(uart_tx_item);
    `uvm_object_utils(uart_tx_seq1)

    function new(string name = "uart_tx_seq1");
        super.new(name);
    endfunction

    virtual task body();
        repeat (10) begin
            `uvm_create(req)

            start_item(req);

            //Randomize fields in transcation, in case randomization failed raise error 
            if (!req.randomize()) begin
                `uvm_error("RAND", "[seq1] Randomization failed")
            end
            finish_item(req);
            //get_response(tx);
        end
    endtask : body
endclass : uart_tx_seq1

//seq2 Sends 10 transactions with random errors in the parity, start, and stop bits
class uart_tx_seq2 extends uvm_sequence #(uart_tx_item);
    `uvm_object_utils(uart_tx_seq2)

    function new(string name = "uart_tx_seq2");
        super.new(name);
    endfunction

    virtual task body();
        repeat (10) begin
            `uvm_create(req)

            start_item(req);
            //Turn off constraints for tx item
            req.valid_bits.constraint_mode(0);

            //Randomize method with dist, error injecrion
            if (!req.randomize() with {
                start_bit dist {1'b1 := 25, 1'b0 := 75};
                stop_bit dist {1'b0 := 25, 1'b1 := 75};

                solve data before parity_bit;
                parity_bit dist {~(^data) := 25, ^data := 75};
            }) begin
                `uvm_error("RAND", "[seq2] Randomization failed")
            end

            //Turn on constraints 
            req.valid_bits.constraint_mode(1);
            finish_item(req);
            //No need for response, driver is not providing response, nothing's in the queue
            //get_response(tx);
        end
    endtask : body
endclass : uart_tx_seq2