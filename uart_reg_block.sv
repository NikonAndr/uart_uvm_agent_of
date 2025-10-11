class uart_reg_block extends uvm_reg_block;
    r1_reg R1;
    r2_reg R2;
    uvm_reg_map default_map;

    `uvm_object_utils(uart_reg_block)

    function new(string name = "reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //Create & Build R1 Reg
        R1 = r1_reg::type_id::create("R1");
        R1.configure(this, null, "");
        R1.build();

        //Create & Build R2 Reg
        R2 = r2_reg::type_id::create("R2");
        R2.configure(this, null, "");
        R2.build();

        //Create Default Register Map Starting At Base 0x0, Bus Witdh 1 Byte
        default_map = create_map("default_map", 'h0, 1, UVM_LITTLE_ENDIAN);
        
        //Add Registers To The Map With Address Offsets
        default_map.add_reg(R1, 'h0, "RW");
        default_map.add_reg(R2, 'h1, "RO");

        //Lock The Model After Construction 
        lock_model();
    endfunction : build
endclass : uart_reg_block