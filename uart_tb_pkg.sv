package uart_tb_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_tx_item.sv"
    //`include "uart_op_item.sv"
    `include "uart_agent_config.sv"

    `include "uart_regs.sv"
    `include "uart_reg_block.sv"
    `include "uart_reg_adapter.sv"
    `include "uart_frontdoor_seq.sv"
    
    typedef uvm_sequencer#(uart_tx_item) uart_sequencer;
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"

    `include "uart_sequences.sv"
    `include "uart_env.sv"
    `include "uart_test_2_3.sv"
    //`include "uart_test.sv"
    //`include "uart_env_2_2.sv"
    //`include "uart_test_2_2.sv"
endpackage : uart_tb_pkg