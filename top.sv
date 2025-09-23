import uvm_pkg::*;
`include "uvm_macros.svh"

`include "uart_if.sv"
`include "uart_tb_pkg.sv"
import uart_tb_pkg::*;

module top;
    timeunit 1ns; timeprecision 1ps;
    uart_if vif_A1();
    uart_if vif_A2();
    uart_agent_config cfg_a1;
    uart_agent_config cfg_a2;

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
        //Master Agent Config 
        cfg_a1 = uart_agent_config::type_id::create("cfg_a1");
        if (!cfg_a1.randomize()) begin
            `uvm_error("CFG", "Cfg Randomization Failed!")
        end
        cfg_a1.calculate_var_ps();
        cfg_a1.is_master = 1;
        uvm_config_db#(uart_agent_config)::set(null, "uvm_test_top.env.A1", "uart_cfg", cfg_a1);

        //Slave Agent Config
        cfg_a2 = uart_agent_config::type_id::create("cfg_a2");
        //Set A2 bitrate based on A1 bitrate
        cfg_a2.bitrate = cfg_a1.bitrate;
        cfg_a2.calculate_var_ps();
        cfg_a2.is_master = 0;
        uvm_config_db#(uart_agent_config)::set(null, "uvm_test_top.env.A2", "uart_cfg", cfg_a2);

        //Set Vif's for A1 & A2
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.A1", "vif", vif_A1);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.A2", "vif", vif_A2);

        //Set Test Name Using +UVM_TESTNAME= 
        run_test();
        $finish;         
    end
endmodule : top