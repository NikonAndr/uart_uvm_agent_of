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
        //Retrieve virtual interface from configuration DB
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not set for an agent")
        end

        //Retrieve configuration object from configuration DB
        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "uart_agent_config not set for an agent")
        end

        //Retrieve Agent Status from configuration DB
        if(!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
            `uvm_fatal("AGENT_STATUS", "Agent Status not set")
        end
        `uvm_info("AGENT", $sformatf("configured as %s",(get_is_active()==UVM_ACTIVE) ? "ACTIVE" : "PASSIVE"), UVM_LOW)
        
        if (get_is_active() == UVM_ACTIVE) begin
            driver = uart_driver::type_id::create("driver", this);
            sequencer = uart_sequencer::type_id::create("sequencer", this);

            uvm_config_db#(virtual uart_if)::set(this, "driver", "vif", vif);
            uvm_config_db#(uart_agent_config)::set(this, "driver", "uart_cfg", cfg);
        end
        
        monitor = uart_monitor::type_id::create("monitor", this);
        uvm_config_db#(virtual uart_if)::set(this, "monitor", "vif", vif);
        uvm_config_db#(uart_agent_config)::set(this, "monitor", "uart_cfg", cfg);

    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            //Connect driver to sequencer
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction : connect_phase 
endclass : uart_agent