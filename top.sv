timeunit 1ns; timeprecision 1ps;
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "uart_if.sv"
`include "uart_tx_item.sv"
`include "uart_agent_config.sv"
`include "uart_sequences.sv"
`include "uart_sequencer.sv"
`include "uart_driver.sv"
`include "uart_monitor.sv"
`include "uart_agent.sv"
`include "uart_test.sv"

module top;
    uart_if vif();
    uart_agent_config cfg;

    initial begin
        //Reset before running program
        vif.rst = 1'b1;
        #50ns;
        vif.rst = 1'b0;
    end

    initial begin
        `uvm_info("SEED", $sformatf("RANDOM SEED: %0d", $get_initial_random_seed()), UVM_NONE)
    end

    initial begin 
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);

        //Create configuration object
        cfg = uart_agent_config::type_id::create("cfg");

        //Set UART bitrate 
        cfg.randomize();
        cfg.calculate_var_ps();
        $display($sformatf("Bitrate: %0d, Var_ps: %0d", cfg.bitrate, cfg.var_ps));

        //Set config objects into UVM config DB
        uvm_config_db#(uart_agent_config)::set(null, "*", "uart_cfg", cfg);
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);

        //Set Test Name Using +UVM_TESTNAME= 
        run_test();
        $finish;
    end
endmodule : top