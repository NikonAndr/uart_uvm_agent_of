import uvm_pkg::*;
`include "uvm_macros.svh"

`include "uart_if.sv"
`include "uart_tx_item.sv"
`include "uart_agent_config.sv"
`include "uart_sequences.sv"
`include "uart_driver.sv"
`include "uart_monitor.sv"
`include "uart_agent.sv"
`include "uart_test.sv"

module top;
    bit clk = 1'b0;

    //Clock period 10 ns
    always #5 clk = ~clk;

    uart_if vif(clk);

    initial begin
        //Reset before running program
        vif.rst = 1'b1;
        #50;
        vif.rst = 1'b0;
    end

    initial begin
        `uvm_info("SEED", $sformatf("RANDOM SEED: %0d", $get_initial_random_seed()), UVM_NONE)
    end

    initial begin 
        //Create configuration object
        automatic uart_agent_config cfg = uart_agent_config::type_id::create("cfg");
        
        //Set UART bitrate and clock period
        cfg.bitrate = 115200;
        cfg.clk_period_ns = 10;
        cfg.calculate_bit_time();
        $display($sformatf("BITRATE: %0d, CLOCK PERIOD %0d, BIT TIME %0d", cfg.bitrate, cfg.clk_period_ns, cfg.bit_time));

        //Set config objects into UVM config DB
        uvm_config_db#(uart_agent_config)::set(null, "*", "uart_cfg", cfg);
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);

        run_test("uart_seq1_seq2_test");
    end
endmodule : top