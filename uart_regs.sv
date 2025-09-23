class r1_reg extends uvm_reg;
    `uvm_object_utils(r1_reg)
    uvm_reg_field R1;

    function new(string name = "r1_reg");
        super.new(name, 8, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //Build & Configure R1 (Size 4, access "RW", has_reset 1, Value After Reset 0x0)
        R1 = uvm_reg_field::type_id::create("R1");
        R1.configure(this, 8, 0, "RW", 0, 8'h00, 1, 0, 0);
    endfunction : build
endclass : r1_reg

class r2_reg extends uvm_reg;
    `uvm_object_utils(r2_reg)
    uvm_reg_field R2;

    function new(string name = "r2_reg");
        super.new(name, 8, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //Build & Configure R2 (Size 4, access "RO", has_reset 1, Value After Reset 0xA)
        R2 = uvm_reg_field::type_id::create("R2");
        R2.configure(this, 8, 0, "RO", 0, 8'h0a, 1, 0, 0);
    endfunction : build
endclass : r2_reg