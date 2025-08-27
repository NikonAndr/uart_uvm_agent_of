interface uart_if();
    timeunit 1ns; timeprecision 1ps;

    logic tx;
    logic rst;

    modport driver (input rst, output tx);
    modport monitor (input rst, input tx);
endinterface : uart_if