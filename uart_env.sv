class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent agent;
    uart_reg_block reg_block;
    uart_reg_adapter reg_adapter;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = uart_agent::type_id::create("agent", this);

        reg_block = uart_reg_block::type_id::create("reg_block", this);
        reg_block.build();

        reg_adapter = uart_reg_adapter::type_id::create("reg_adapter");
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        reg_block.default_map.set_sequencer(agent.sequencer, reg_adapter);
    endfunction : connect_phase

endclass : uart_env


