class uart_agent_config extends uvm_object;
    `uvm_object_utils(uart_agent_config)

    //UART transmission speed in bits per second
    rand int bitrate; 

    //Set Agent As Master/Slave
    bit is_master;
    //Constraint for bitrate
    constraint bitrate_c {bitrate inside {19200, 115200};}
    
    longint unsigned var_ps;

    function new(string name = "uart_agent_config");
        super.new(name);
    endfunction

    //Calculate var_ps
    function void calculate_var_ps();
        if (bitrate == 0) begin
            `uvm_fatal(get_type_name(), "bitrate == 0")
        end

        var_ps = longint'($rtoi((1.0e12/ bitrate) + 0.5));
    endfunction : calculate_var_ps

endclass : uart_agent_config

