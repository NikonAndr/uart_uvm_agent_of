class uart_sequencer extends uvm_sequencer #(uart_tx_item);
    `uvm_component_utils(uart_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : uart_sequencer

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    virtual uart_if vif;
    uart_agent_config cfg;
    uart_driver driver;
    uart_monitor monitor;
    uart_sequencer sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //Set Agent as Active
        is_active = UVM_ACTIVE;

        //Retrieve virtual interface from configuration DB
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for an agent")
        end

        //Retrieve configuration object from configuration DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for an agent")
        end

        //Create driver, monitor, sequencer
        driver = uart_driver::type_id::create("driver", this);
        monitor = uart_monitor::type_id::create("monitor", this);
        sequencer = uart_sequencer::type_id::create("sequencer", this);

        //Pass virtual interface to subcomponents
        uvm_config_db#(virtual uart_if)::set(this, "driver", "vif", vif);
        uvm_config_db#(virtual uart_if)::set(this, "monitor", "vif", vif);

        //Pass configuration object to subcomponents
        uvm_config_db#(uart_agent_config)::set(this, "driver", "uart_cfg", cfg);
        uvm_config_db#(uart_agent_config)::set(this, "monitor", "uart_cfg", cfg);

    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //Connect driver to sequencer
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction : connect_phase 
endclass : uart_agent