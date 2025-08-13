import uvm_pkg::*;
`include "uvm_macros.svh"

interface uart_if();
    logic tx;
    logic rst;
endinterface : uart_if