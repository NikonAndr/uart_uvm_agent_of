package uart_tb_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    

    `include "uart_tx_item.sv"
    `include "uart_agent_config.sv"
    
    `include "uart_reg_model.sv"
    typedef uvm_sequencer#(uart_tx_item) uart_sequencer;
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"

    `include "uart_sequences.sv"
    `include "uart_env.sv"
    `include "uart_test.sv"
endpackage : uart_tb_pkg