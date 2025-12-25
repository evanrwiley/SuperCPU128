`timescale 1ns / 1ps

module tb_reu();

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    reg         clk_sys;
    reg         rst_n;
    
    // Register Interface
    reg         cs_reu;
    reg [3:0]   reg_addr;
    reg         we;
    reg [7:0]   data_in;
    wire [7:0]  data_out;
    reg         ff00_write;
    
    // DMA Interface
    reg         c64_phi2;
    wire        c64_ba;
    reg         c64_dma_ack;
    wire [15:0] c64_addr_out;
    wire [7:0]  c64_data_out;
    reg [7:0]   c64_data_in;
    wire        c64_rw_out;
    
    // Memory Interface
    wire [23:0] mem_addr;
    wire [7:0]  mem_wdata;
    reg [7:0]   mem_rdata;
    wire        mem_we;
    wire        mem_req;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    reu_emulation dut (
        .clk_sys(clk_sys),
        .rst_n(rst_n),
        
        .cs_reu(cs_reu),
        .reg_addr(reg_addr),
        .we(we),
        .data_in(data_in),
        .data_out(data_out),
        .ff00_write(ff00_write),
        
        .c64_phi2(c64_phi2),
        .c64_ba(c64_ba),
        .c64_dma_ack(c64_dma_ack),
        .c64_addr_out(c64_addr_out),
        .c64_data_out(c64_data_out),
        .c64_data_in(c64_data_in),
        .c64_rw_out(c64_rw_out),
        
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_req(mem_req)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk_sys = 0;
    always #10 clk_sys = ~clk_sys; // 50MHz
    
    initial c64_phi2 = 0;
    always begin
        #500 c64_phi2 = 1;
        #500 c64_phi2 = 0;
    end

    // -------------------------------------------------------------------------
    // Tasks
    // -------------------------------------------------------------------------
    task write_reg(input [3:0] addr, input [7:0] val);
        begin
            @(posedge clk_sys);
            cs_reu = 1;
            reg_addr = addr;
            we = 1;
            data_in = val;
            @(posedge clk_sys);
            cs_reu = 0;
            we = 0;
            #10;
        end
    endtask
    
    task read_reg(input [3:0] addr);
        begin
            @(posedge clk_sys);
            cs_reu = 1;
            reg_addr = addr;
            we = 0;
            @(posedge clk_sys);
            #1; // Wait for output
            $display("Reg %h: %h", addr, data_out);
            cs_reu = 0;
            #10;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Init
        rst_n = 0;
        cs_reu = 0;
        reg_addr = 0;
        we = 0;
        data_in = 0;
        ff00_write = 0;
        c64_dma_ack = 0;
        c64_data_in = 0;
        mem_rdata = 8'h55; // Default RAM content
        
        #100;
        rst_n = 1;
        #100;
        
        $display("--- REU Testbench ---");
        
        // 1. Setup Stash (C64 -> REU)
        // C64 Addr: $1000
        // REU Addr: $000000
        // Len: 2 bytes
        write_reg(4'h2, 8'h00);
        write_reg(4'h3, 8'h10);
        write_reg(4'h4, 8'h00);
        write_reg(4'h5, 8'h00);
        write_reg(4'h6, 8'h00);
        write_reg(4'h7, 8'h02);
        write_reg(4'h8, 8'h00);
        write_reg(4'hA, 8'h00); // Auto-inc both
        
        // 2. Execute Stash
        $display("Starting Stash...");
        write_reg(4'h1, 8'h90); // Exec + Stash + Imm
        
        // 3. Wait for BA Low
        wait(c64_ba == 0);
        $display("DMA Requested");
        
        // 4. Grant Bus
        @(posedge c64_phi2);
        c64_dma_ack = 1;
        
        // Provide Data for Cycle 1 (Read $1000)
        // Data must be valid before PHI2 falls
        #200; 
        c64_data_in = 8'hAA; 
        
        // 5. Cycle 1 Check
        @(negedge c64_phi2);
        if (c64_rw_out == 1 && c64_addr_out == 16'h1000)
            $display("Cycle 1 OK: Read $1000");
        else
            $display("Cycle 1 FAIL: Addr=%h RW=%b", c64_addr_out, c64_rw_out);
            
        
        // Wait for internal write
        wait(mem_req == 1 && mem_we == 1);
        if (mem_addr == 24'h000000 && mem_wdata == 8'hAA)
            $display("RAM Write 1 OK");
        else
            $display("RAM Write 1 FAIL: Addr=%h Data=%h", mem_addr, mem_wdata);
            
        // Provide Data for Cycle 2 (Read $1001)
        // Wait for next PHI2 High
        @(posedge c64_phi2);
        #200;
        c64_data_in = 8'hBB;
        
        // 6. Cycle 2 Check
        @(negedge c64_phi2);
        if (c64_rw_out == 1 && c64_addr_out == 16'h1001)
            $display("Cycle 2 OK: Read $1001");
            
        
        wait(mem_req == 1 && mem_we == 1);
        if (mem_addr == 24'h000001 && mem_wdata == 8'hBB)
            $display("RAM Write 2 OK");
            
        // 7. End
        wait(c64_ba == 1);
        c64_dma_ack = 0;
        $display("DMA Finished");
        
        // Check Status
        read_reg(4'h0); // Should be 0x40 (End of Block) or similar
        
        $stop;
    end

endmodule
