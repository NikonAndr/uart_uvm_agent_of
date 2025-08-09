interface uart_if(input bit clk);
    logic tx;
    initial tx = 1'bx; //sets value tx to be x before the reset
    logic rst;
endinterface : uart_if