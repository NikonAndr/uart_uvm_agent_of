//Declare analysis_imp suffixes
`uvm_analysis_imp_decl(_a1_tx)
`uvm_analysis_imp_decl(_a1_rx)
`uvm_analysis_imp_decl(_a2_tx)
`uvm_analysis_imp_decl(_a2_rx)

class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    //Import ap from A1 & A2 monitors 
    uvm_analysis_imp_a1_tx #(uart_tx_item, uart_scoreboard) a1_tx_imp;
    uvm_analysis_imp_a1_rx #(uart_tx_item, uart_scoreboard) a1_rx_imp;
    uvm_analysis_imp_a2_tx #(uart_tx_item, uart_scoreboard) a2_tx_imp;
    uvm_analysis_imp_a2_rx #(uart_tx_item, uart_scoreboard) a2_rx_imp;

    //Queues to buffer incoming frames
    uart_tx_item a1_tx_q[$];
    uart_tx_item a1_rx_q[$];
    uart_tx_item a2_tx_q[$];
    uart_tx_item a2_rx_q[$];

    //SB Statistics 
    int total_writes;
    int total_reads;
    int write_verifications;
    int read_verifications;
    int write_match;
    int write_mismatch;
    int read_match;
    int read_mismatch;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        a1_tx_imp = new("a1_tx_imp", this);
        a1_rx_imp = new("a1_rx_imp", this);
        a2_tx_imp = new("a2_tx_imp", this);
        a2_rx_imp = new("a2_rx_imp", this);

        total_writes = 0;
        total_reads = 0;
        write_verifications = 0;
        read_verifications = 0;
        write_match = 0;
        write_mismatch = 0;
        read_match = 0;
        read_mismatch = 0;
    endfunction : build_phase
    
    virtual function void write_a1_tx(uart_tx_item tx);
        a1_tx_q.push_back(tx);
        check_complete_transaction();
    endfunction : write_a1_tx

    virtual function void write_a1_rx(uart_tx_item tx);
        a1_rx_q.push_back(tx);
        check_complete_transaction();
    endfunction : write_a1_rx

    virtual function void write_a2_tx(uart_tx_item tx);
        a2_tx_q.push_back(tx);
        check_complete_transaction();
    endfunction : write_a2_tx

    virtual function void write_a2_rx(uart_tx_item tx);
        a2_rx_q.push_back(tx);
        check_complete_transaction();
    endfunction : write_a2_rx

    function void check_complete_transaction();
        uart_tx_item cmd_frame, addr_frame, data_frame;
        uart_tx_item a1_recieved;
        bit is_write;

        byte addr, data;

        //Check if a1_tx queue % a2_rx queue have 3 items (WRITE cmd)
        if (a1_tx_q.size() >= 3 && a2_rx_q.size() >= 3) begin
            cmd_frame = a1_tx_q[0];
            //Write command 
            if (cmd_frame.data[0] == 1'b1) begin
                cmd_frame = a1_tx_q.pop_front();
                addr_frame = a1_tx_q.pop_front();
                data_frame = a1_tx_q.pop_front();

                addr = addr_frame.data;
                data = data_frame.data;

                verify_write_command(addr, data);

                total_writes++;
            end
        end

        //Check for read command 
        if (a1_tx_q.size() >= 2 && a2_rx_q.size() >= 2
            && a1_rx_q.size() >= 1 && a2_tx_q.size() >= 1) begin
            cmd_frame = a1_tx_q[0];
            //Read command 
            if (cmd_frame.data[0] == 1'b0) begin
                cmd_frame = a1_tx_q.pop_front();
                addr_frame = a1_tx_q.pop_front();

                addr = addr_frame.data;

                a1_recieved = a2_tx_q.pop_front();

                verify_read_command(addr, a1_recieved.data);

                total_reads++;
            end
        end
    endfunction : check_complete_transaction

    function void verify_write_command(byte addr, byte data);
        uart_tx_item cmd_rx, addr_rx, data_rx;
        bit cmd_ok, addr_ok, data_ok;

        write_verifications++;

        cmd_rx = a2_rx_q.pop_front();
        addr_rx = a2_rx_q.pop_front();
        data_rx = a2_rx_q.pop_front();

        cmd_ok = (cmd_rx.data[0] == 1'b1);
        addr_ok = (addr_rx.data == addr);
        data_ok = (data_rx.data == data);

        //SB write log
        if (cmd_ok && addr_ok && data_ok) begin
            `uvm_info("SB", $sformatf("A1.WRITE.0x%0h.0x%0h",
                addr, data), UVM_MEDIUM)
            write_match++;
        end
        else begin
            `uvm_info("SB", $sformatf("WRITE A1->A2 MISMATCH | Expected addr=0x%0h, data =0x%0h | Got cmd =0x%0h, adrr =0x%0h, data = 0x%0h", 
                addr, data, cmd_rx.data, addr_rx.data, data_rx.data), UVM_MEDIUM)
            write_mismatch++;
        end
    endfunction : verify_write_command

    function void verify_read_command(byte addr, byte read_data);
        uart_tx_item cmd_rx, addr_rx;
        bit cmd_ok, addr_ok, data_ok;
        uart_tx_item expected_data_frame;

        read_verifications++;

        cmd_rx = a2_rx_q.pop_front();
        addr_rx = a2_rx_q.pop_front();

        expected_data_frame = a1_rx_q.pop_front();

        cmd_ok = (cmd_rx.data[0] == 1'b0);
        addr_ok = (addr_rx.data == addr);
        data_ok = (expected_data_frame.data == read_data);

        //SB read log
        if (cmd_ok && addr_ok && data_ok) begin
            `uvm_info("SB", $sformatf("A2.READ.0x%0h.0x%0h",
                addr, read_data), UVM_MEDIUM)
            read_match++;
        end
        else begin
            `uvm_info("SB", $sformatf("READ A1->A2->A1 MISMATCH | Expected addr=0x%0h, data =0x%0h | Got cmd =0x%0h, adrr =0x%0h, data = 0x%0h", 
                addr, read_data, cmd_rx.data, addr_rx.data, expected_data_frame.data), UVM_MEDIUM)
            read_mismatch++;
        end
    endfunction : verify_read_command

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCOREBOARD", "--------VERIFICATION SUMMARY--------", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL WRITES: %0d", total_writes), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL READS: %0d", total_reads), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("WRITE VERIFICATIONS: %0d", write_verifications), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("READ VERIFICATIONS: %0d", read_verifications), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("WRITE MATCHES: %0d", write_match), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("READ MATCHES: %0d", read_match), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("WRITE MISMATCHES: %0d", write_mismatch), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("READ MISMATCHES: %0d", read_mismatch), UVM_LOW)

        if (write_mismatch > 0) begin
            `uvm_info("SCOREBOARD", "VERIFICATION FAILED! Write mismatches > 0", UVM_MEDIUM)
        end

        if (read_mismatch > 0) begin
            `uvm_info("SCOREBOARD", "VERIFICATION FAILED! Read mismatches > 0", UVM_MEDIUM)
        end

        if (write_mismatch == 0 && read_mismatch == 0) begin
            `uvm_info("SCOREBOARD", "VERIFICATION PASSED!", UVM_MEDIUM)
        end
    endfunction : report_phase
endclass : uart_scoreboard 


    