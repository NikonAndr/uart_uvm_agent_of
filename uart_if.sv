interface uart_if();
    timeunit 1ns; timeprecision 1ps;

    logic tx;
    logic rst;
    logic rx;

    modport driver (input rst, input rx, output tx);
    modport monitor (input rst, input tx, input rx);
endinterface : uart_if