class r1_reg extends uvm_reg;
    `uvm_object_utils(r1_reg)
    uvm_reg_field R1;

    function new(string name = "r1_reg");
        super.new(name, 4, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        R1 = uvm_reg_field::type_id::create("R1");
        R1.configure(this, 4, 0, "RW", 1, 4'h0, 1, 0, 0);
    endfunction : build
endclass : r1_reg

class r2_reg extends uvm_reg;
    `uvm_object_utils(r2_reg)
    uvm_reg_field R2;

    function new(string name = "r2_reg");
        super.new(name, 4, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        R2 = uvm_reg_field::type_id::create("R2");
        R2.configure(this, 4, 0, "RO", 1, 4'ha, 1, 0, 0);
    endfunction : build
endclass : r2_reg

class uart_reg_block extends uvm_reg_block;
    r1_reg R1;
    r2_reg R2;
    uvm_reg_map default_map;

    `uvm_object_utils(uart_reg_block)

    function new(string name = "reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        R1 = r1_reg::type_id::create("R1");
        R1.build();

        R2 = r2_reg::type_id::create("R2");
        R2.build();

        default_map = create_map("default_map", 'h0, 1, UVM_LITTLE_ENDIAN);

        R1.configure(this, null, "R1");
        R2.configure(this, null, "R2");

        default_map.add_reg(R1, 'h0, "RW");
        default_map.add_reg(R2, 'h1, "RO");

        lock_model();
    endfunction : build
endclass : uart_reg_block

class uart_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(uart_reg_adapter)
    
    function new(string name = "uart_reg_adapter");
        super.new(name);

        supports_byte_enable = 0;
        provides_responses = 0;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        uart_tx_item tx;
        tx = uart_tx_item::type_id::create("tx");

        tx.data[0] = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
        tx.data[3:1] = rw.addr[2:0];
        tx.data[7:4] = rw.data[3:0];
        return tx;
    endfunction : reg2bus

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        uart_tx_item tx;

        if (!$cast(tx, bus_item)) begin
            `uvm_fatal("ADAPTER", "Casting bus to uart_tx_item failed!")
        end

        rw.kind = (tx.data[0] == 1'b1) ? UVM_WRITE : UVM_READ;
        rw.addr = tx.data[3:1];
        rw.data = tx.data[7:4];
        rw.status = UVM_IS_OK;
    endfunction : bus2reg
endclass : uart_reg_adapter

