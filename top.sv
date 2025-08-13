import uvm_pkg::*;
`include "uvm_macros.svh"

`include "uart_if.sv"
//`include "uart_tx_item.sv"
`include "uart_agent_config.sv"
/*`include "uart_sequences.sv"
`include "uart_driver.sv"
`include "uart_monitor.sv"
`include "uart_agent.sv"
`include "uart_test.sv"
*/

module top;
    //Create Virtual interface
    uart_if vif();

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
        
        //Set UART bitrate 
        cfg.randomize();
        cfg.calculate_var_ps();
        $display($sformatf("Bitrate: %0d, Var_ps: %0d", cfg.bitrate, cfg.var_ps));
    end
endmodule : top