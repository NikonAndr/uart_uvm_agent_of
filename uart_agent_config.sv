
class uart_agent_config extends uvm_object;
    `uvm_object_utils(uart_agent_config)

    //UART transmission speed in bits per second
    int bitrate; 
    //clock period [ns]
    int clk_period_ns; 
    //Number of clock cycles per bit
    int bit_time; 

    function new(string name = "uart_agent_config");
        super.new(name);
    endfunction

    //Calculates bit_time based on bitrate and clock period
    //bit_time = time of 1 bit in clock cycles = (1s /bitrate) / clk_period_ns
    function void calculate_bit_time();
        bit_time = int'(1_000_000_000.0 / bitrate / clk_period_ns);
    endfunction : calculate_bit_time 

endclass : uart_agent_config

