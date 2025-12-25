`timescale 1ns / 1ps
`include "c64_labels.vh"

module tb_supercpu();

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    reg         clk_50;
    reg         rst_n;
    
    // C64 Bus Signals
    reg         c64_phi2;
    reg         c64_rst_n;
    reg         c64_rw_n;
    reg         c64_ba;
    reg         c64_roml_n;
    reg         c64_romh_n;
    reg         c64_io1_n;
    reg         c64_io2_n;
    
    wire        fpga_game_n;
    wire        fpga_exrom_n;
    wire        fpga_dma_n;
    wire        fpga_irq_n;
    wire        fpga_nmi_n;
    
    wire [15:0] fpga_a;
    wire [7:0]  fpga_d;
    
    // Bidirectional Bus Drivers
    reg [15:0]  tb_a_drive;
    reg         tb_a_oe;
    reg [7:0]   tb_d_drive;
    reg         tb_d_oe;
    
    assign fpga_a = tb_a_oe ? tb_a_drive : 16'hZZZZ;
    assign fpga_d = tb_d_oe ? tb_d_drive : 8'hZZ;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    supercpu_top dut (
        .FPGA_CLK1_50 (clk_50),
        
        .FPGA_PHI2    (c64_phi2),
        .FPGA_DOT_CLK (1'b0), // Unused in sim for now
        .FPGA_RST_N   (c64_rst_n),
        .FPGA_RW_N    (c64_rw_n),
        .FPGA_BA      (c64_ba),
        
        .FPGA_IO1_N   (c64_io1_n),
        .FPGA_IO2_N   (c64_io2_n),
        .FPGA_ROML_N  (c64_roml_n),
        .FPGA_ROMH_N  (c64_romh_n),
        
        .FPGA_A       (fpga_a),
        .FPGA_D       (fpga_d),
        
        .FPGA_GAME_N  (fpga_game_n),
        .FPGA_EXROM_N (fpga_exrom_n),
        .FPGA_DMA_N   (fpga_dma_n),
        .FPGA_IRQ_N   (fpga_irq_n),
        .FPGA_NMI_N   (fpga_nmi_n),
        
        // HPS / HDMI / Audio (Stubbed)
        .hps_uart_tx_data(), .hps_uart_tx_valid(), .hps_uart_tx_full(1'b0),
        .hps_uart_rx_data(8'h00), .hps_uart_rx_valid(1'b0), .hps_uart_rx_read(),
        .hps_bridge_base(16'h0000), .hps_bridge_enable(1'b0),
        .HDMI_TX_CLK(), .HDMI_TX_DE(), .HDMI_TX_HS(), .HDMI_TX_VS(), .HDMI_TX_D(),
        .AUD_XCK(), .AUD_DACDAT(), .AUD_BCLK(), .AUD_DACLRCK(), .AUD_ADCLRCK(), .AUD_ADCDAT(1'b0)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk_50 = 0;
    always #10 clk_50 = ~clk_50; // 50MHz (20ns period)
    
    // C64 PHI2 Generation (1MHz approx)
    initial c64_phi2 = 0;
    always begin
        #500 c64_phi2 = 1;
        #500 c64_phi2 = 0;
    end

    // -------------------------------------------------------------------------
    // Execution Tracer
    // -------------------------------------------------------------------------
    always @(posedge clk_50) begin
        // Trace when CPU is reading an instruction (VDA=1, VPA=1)
        // Note: We need to access internal signals of the DUT for this.
        // Since we can't easily do that without hierarchical reference,
        // we'll just trace the address bus when RW is high (Read).
        // This is "noisy" but sufficient for seeing KERNAL calls.
        
        // Hierarchical access to CPU signals for cleaner tracing
        if (dut.u_cpu.VDA && dut.u_cpu.VPA && dut.u_cpu.RDY) begin
             print_label_trace(dut.u_cpu.ADDR_OUT[15:0]);
        end
    end

    // -------------------------------------------------------------------------
    // Tasks
    // -------------------------------------------------------------------------
    task write_byte(input [15:0] addr, input [7:0] data);
        begin
            @(posedge c64_phi2); // Wait for start of cycle
            tb_a_drive = addr;
            tb_a_oe = 1;
            tb_d_drive = data;
            tb_d_oe = 1;
            c64_rw_n = 0;
            
            // Chip Select Logic
            if (addr >= 16'hDF00 && addr <= 16'hDFFF) c64_io2_n = 0;
            if (addr >= 16'hDE00 && addr <= 16'hDEFF) c64_io1_n = 0;
            
            @(negedge c64_phi2); // Hold until end of cycle
            
            // Release
            tb_a_oe = 0;
            tb_d_oe = 0;
            c64_rw_n = 1;
            c64_io2_n = 1;
            c64_io1_n = 1;
            #10;
        end
    endtask

    task read_byte(input [15:0] addr);
        begin
            @(posedge c64_phi2);
            tb_a_drive = addr;
            tb_a_oe = 1;
            tb_d_oe = 0; // High Z for read
            c64_rw_n = 1;
            
            if (addr >= 16'hDF00 && addr <= 16'hDFFF) c64_io2_n = 0;
            if (addr >= 16'hDE00 && addr <= 16'hDEFF) c64_io1_n = 0;
            
            @(negedge c64_phi2);
            $display("Read $%h: $%h", addr, fpga_d);
            
            tb_a_oe = 0;
            c64_io2_n = 1;
            c64_io1_n = 1;
            #10;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Initialize
        rst_n = 0;
        c64_rst_n = 0;
        c64_rw_n = 1;
        c64_ba = 1;
        c64_roml_n = 1;
        c64_romh_n = 1;
        c64_io1_n = 1;
        c64_io2_n = 1;
        tb_a_oe = 0;
        tb_d_oe = 0;
        
        // Reset Pulse
        #100;
        rst_n = 1;
        c64_rst_n = 1;
        #1000;
        
        $display("--- Starting Simulation ---");
        
        // 1. Configure REU
        $display("Configuring REU...");
        write_byte(16'hDF02, 8'h00); // C64 Addr Low
        write_byte(16'hDF03, 8'h04); // C64 Addr High ($0400)
        write_byte(16'hDF04, 8'h00); // REU Addr Low
        write_byte(16'hDF05, 8'h00); // REU Addr High
        write_byte(16'hDF06, 8'h00); // REU Bank
        write_byte(16'hDF07, 8'h01); // Length Low (1 byte)
        write_byte(16'hDF08, 8'h00); // Length High
        write_byte(16'hDF09, 8'h00); // IRQ Mask
        write_byte(16'hDF0A, 8'h00); // Addr Control
        
        // 2. Trigger Stash (C64 -> REU)
        $display("Triggering Stash...");
        write_byte(16'hDF01, 8'h90); // Execute + Stash (00) + Immediate
        
        // 3. Wait for DMA
        wait(fpga_dma_n == 0);
        $display("DMA Request Detected!");
        
        // 4. Grant Bus
        @(posedge c64_phi2);
        c64_ba = 0; // Acknowledge
        
        // 5. Simulate DMA Cycle
        // REU should drive Address $0400 and Read
        // Data must be valid before PHI2 falls
        #200;
        tb_d_drive = 8'hAA;
        tb_d_oe = 1;
        
        @(negedge c64_phi2);
        $display("DMA Cycle 1: Addr=$%h RW=%b", fpga_a, c64_rw_n);
        
        // Hold data for a bit then release
        #100;
        tb_d_oe = 0;
        
        // REU should now write to internal RAM (invisible to bus)
        
        // 6. Release Bus
        wait(fpga_dma_n == 1);
        c64_ba = 1;
        $display("DMA Complete.");
        
        // 7. Verify Status
        read_byte(16'hDF00);
        
        // 8. Verify ID Logic
        $display("Checking ID Logic...");
        read_byte(16'hDFFF); // Should be 55 or AA
        read_byte(16'hDFFF); // Should toggle
        read_byte(16'hDFFE); // Should be 'C' (0x43)
        
        $display("--- Test Complete ---");
        $stop;
    end

endmodule
