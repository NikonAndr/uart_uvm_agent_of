class uart_monitor_events extends uvm_object;
    `uvm_object_utils(uart_monitor_events)

    uvm_event read_request;

    byte read_addr;

    function new(string name = "uart_monitor_events");
        super.new(name);
        read_request = new("read_request");
    endfunction 

    function void trigger_read_request(byte addr);
        read_addr = addr;
        read_request.trigger();
    endfunction : trigger_read_request
endclass : uart_monitor_events