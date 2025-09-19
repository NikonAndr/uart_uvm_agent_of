import uvm_pkg::*;
`include "uvm_macros.svh"

`include "uart_if.sv"
`include "uart_tb_pkg.sv"
import uart_tb_pkg::*;

module top;
    timeunit 1ns; timeprecision 1ps;
    uart_if vif_A1();
    uart_if vif_A2();
    uart_agent_config cfg;
    bit rst;

    initial begin
        //Reset before running program
        rst = 1'b1;
        #50ns;
        rst = 1'b0;
    end

    assign vif_A1.rst = rst;
    assign vif_A2.rst = rst;

    assign vif_A1.rx = vif_A2.tx;
    assign vif_A2.rx = vif_A1.tx;


    initial begin 
        //Set Vif's for A1 & A2
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.A1", "vif", vif_A1);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.A2", "vif", vif_A2);

        //Create configuration object
        cfg = uart_agent_config::type_id::create("cfg");

        //Set UART bitrate 
        if (!cfg.randomize()) begin
            `uvm_error("RANDOMIZE", "Randomize failed!")
        end
        cfg.calculate_var_ps();
        `uvm_info("BITRATE", $sformatf("Bitrate: %0d, Var_ps: %0d", cfg.bitrate, cfg.var_ps), UVM_NONE);

        //Set config objects into UVM config DB
        uvm_config_db#(uart_agent_config)::set(null, "*", "uart_cfg", cfg);

        //Set Test Name Using +UVM_TESTNAME= 
        run_test();
        $finish;
    end
endmodule : top