class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent A1; //Master Agent
    uart_agent A2; //Slave Agent
    uart_reg_block reg_block;
    uart_reg_adapter reg_adapter;
    uart_frontdoor_seq fd1;
    uart_frontdoor_seq fd2;
    uart_monitor_events events;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        A1 = uart_agent::type_id::create("A1", this);
        A2 = uart_agent::type_id::create("A2", this);

        events = uart_monitor_events::type_id::create("events");

        //Create & Build Register Model (Block With R1/R2)
        reg_block = uart_reg_block::type_id::create("reg_block");
        reg_block.configure(null, "");
        reg_block.build();

        //Automaticly Refresh Mirror Value 
        reg_block.default_map.set_auto_predict(1);

        reg_block.lock_model();
        reg_block.reset();

        //Create Adapter For Reg<->Bus Conversion
        reg_adapter = uart_reg_adapter::type_id::create("reg_adapter");

        //Pass RB to A2.driver
        uvm_config_db#(uart_reg_block)::set(this, "A2.driver", "reg_block", reg_block);

        //Pass Events to Both A1 & A2 monitors 
        uvm_config_db#(uart_monitor_events)::set(this, "A1.monitor", "monitor_events", events);
        uvm_config_db#(uart_monitor_events)::set(this, "A2.monitor", "monitor_events", events);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //Pass The Sequencer And Adapter To Reg Block
        reg_block.default_map.set_sequencer(A1.sequencer, reg_adapter);

        //Attach Custom Frontdoor to each Agent
        fd1 = uart_frontdoor_seq::type_id::create("fd1");
        fd2 = uart_frontdoor_seq::type_id::create("fd2");

        reg_block.R1.set_frontdoor(fd1, reg_block.default_map);
        reg_block.R2.set_frontdoor(fd2, reg_block.default_map);
    endfunction : connect_phase

endclass : uart_env


