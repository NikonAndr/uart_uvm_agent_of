class uart_env_2_2 extends uvm_env;
    `uvm_component_utils(uart_env_2_2)

    uart_agent A1;
    uart_agent A2;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        A1 = uart_agent::type_id::create("A1", this);
        A2 = uart_agent::type_id::create("A2", this);
    endfunction : build_phase
endclass : uart_env_2_2

