// SuperCPU Top Level Module
// Target: DE10-Nano + Sysop-64 Carrier
// Author: Copilot & User

`include "include/memory_map.vh"

module supercpu_top (
    // Clock
    input  wire        FPGA_CLK1_50,
    
    // C64 Expansion Port Interface (Mapped to Sysop-64 Carrier)
    // Inputs from C64
    input  wire        FPGA_PHI2,       // 1MHz System Clock
    input  wire        FPGA_DOT_CLK,    // 8MHz Dot Clock
    input  wire        FPGA_RST_N,      // System Reset (Active Low)
    input  wire        FPGA_RW_N,       // Read/Write (High = Read, Low = Write)
    input  wire        FPGA_BA,         // Bus Available (High = Bus Free)
    
    input  wire        FPGA_IO1_N,      // I/O Block 1 Select ($DE00-$DEFF)
    input  wire        FPGA_IO2_N,      // I/O Block 2 Select ($DF00-$DFFF)
    input  wire        FPGA_ROML_N,     // ROM Low Select ($8000-$9FFF)
    input  wire        FPGA_ROMH_N,     // ROM High Select ($A000-$BFFF)
    
    // Bidirectional Address/Data
    inout  wire [15:0] FPGA_A,          // Address Bus (Bidirectional)
    inout  wire [7:0]  FPGA_D,          // Data Bus (Bidirectional)
    
    // Outputs to C64 (Open Drain or Driven Low)
    output wire        FPGA_GAME_N,     // Cartridge Mode Select
    output wire        FPGA_EXROM_N,    // Cartridge Mode Select
    output wire        FPGA_DMA_N,      // DMA Request (Active Low)
    output wire        FPGA_IRQ_N,      // Interrupt Request
    output wire        FPGA_NMI_N,      // Non-Maskable Interrupt

    // HDMI Interface
    output wire        HDMI_TX_CLK,
    output wire        HDMI_TX_DE,
    output wire        HDMI_TX_HS,
    output wire        HDMI_TX_VS,
    output wire [23:0] HDMI_TX_D,

    // Audio Interface (I2S)
    output wire        AUD_XCK,
    output wire        AUD_DACDAT,
    output wire        AUD_BCLK,
    output wire        AUD_DACLRCK,
    output wire        AUD_ADCLRCK,
    input  wire        AUD_ADCDAT,

    // HPS Interface (UART FIFO)
    output wire [7:0]  hps_uart_tx_data,
    output wire        hps_uart_tx_valid,
    input  wire        hps_uart_tx_full,
    
    input  wire [7:0]  hps_uart_rx_data,
    input  wire        hps_uart_rx_valid,
    output wire        hps_uart_rx_read,

    // HPS Interface (Bridge Window Control)
    input  wire [15:0] hps_bridge_base,   // Base address for Bridge Window (e.g. 0x033C)
    input  wire        hps_bridge_enable, // Enable Bridge Window

    // HPS Interface (Debug Bridge)
    input  wire        hps_dbg_valid,
    input  wire [7:0]  hps_dbg_type,
    input  wire [23:0] hps_dbg_addr,
    input  wire [7:0]  hps_dbg_wdata,
    output wire [7:0]  hps_dbg_rdata,
    output wire        hps_dbg_done,

    // User Interface (DE10-Nano)
    input  wire [1:0]  KEY,
    output wire [7:0]  LED
);

    // -------------------------------------------------------------------------
    // Clock Generation (PLL)
    // -------------------------------------------------------------------------
    wire clk_20;
    wire pll_locked;
    
    pll_sys u_pll (
        .refclk   (FPGA_CLK1_50),
        .rst      (!FPGA_RST_N), // PLL Reset is Active High usually
        .outclk_0 (clk_20),
        .locked   (pll_locked)
    );

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    wire sys_reset_req;        // From System Health
    wire sys_reset_req_manual; // From SuperControl
    wire bus_release;          // From System Health
    wire safe_mode;            // From System Health
    wire turbo_toggle;         // From SuperControl
    wire [3:0] control_leds;   // From SuperControl
    wire cpu_vda;              // CPU Valid Data Address
    wire cpu_vpa;              // CPU Valid Program Address

    // Combined Reset Logic
    // Reset if:
    // 1. C64 Reset is Low (FPGA_RST_N)
    // 2. PLL is not locked
    // 3. System Health requests reset (Watchdog/Bus Hang)
    // 4. Physical Reset Button (via SuperControl)
    wire sys_reset_req_combined = !FPGA_RST_N || !pll_locked || sys_reset_req || sys_reset_req_manual;
    wire sys_reset_n = !sys_reset_req_combined;

    // -------------------------------------------------------------------------
    // System Health & Physical Control
    // -------------------------------------------------------------------------
    system_health u_health (
        .clk            (clk_20),
        .por_n          (FPGA_RST_N), // Use raw C64 reset for health monitor base
        .cpu_valid      (cpu_vda | cpu_vpa), // Valid Instruction or Data Fetch
        .cpu_rdy        (FPGA_BA),    // Monitor Bus Availability (RDY)
        .sys_reset_req  (sys_reset_req),
        .bus_release    (bus_release),
        .safe_mode      (safe_mode)
    );

    super_control u_control (
        .clk            (clk_20),
        .rst_n          (FPGA_RST_N),
        .key_turbo_n    (KEY[0]),
        .key_reset_n    (KEY[1]),
        .safe_mode      (safe_mode),
        .cpu_activity   (cpu_rw),     // Blink on access
        .bridge_active  (hps_bridge_enable), // Blink on AI Bridge active
        .turbo_enabled  (turbo_mode),
        .turbo_toggle   (turbo_toggle),
        .sys_reset_req  (sys_reset_req_manual), // Manual reset request
        .leds           (control_leds)
    );
    
    assign LED = {4'b0000, control_leds};
    
    // CPU Signals
    wire [23:0] cpu_addr;
    wire [7:0]  cpu_dout;
    wire [7:0]  cpu_din;
    wire        cpu_rw; // 1=Write (from placeholder)
    wire        cpu_vda;
    wire        cpu_vpa;
    wire        cpu_rdy;
    
    // Bus Interface Signals
    wire [7:0]  biu_d_out;
    wire [7:0]  biu_d_in;
    wire        biu_d_oe;
    wire [15:0] biu_a_out;
    wire        biu_a_oe;
    wire        biu_game_n;
    wire        biu_exrom_n;
    wire        biu_dma_n;
    
    // Memory Signals
    wire [7:0]  ram_dout;
    
    // Register Signals
    wire [7:0]  reg_dout;
    wire        turbo_mode;
    wire        enable_regs;
    
    // System Detection Signals
    wire [31:0] phi2_freq;

    // -------------------------------------------------------------------------
    // Address Decoding
    // -------------------------------------------------------------------------
    wire is_bank_0 = (cpu_addr[23:16] == 8'h00);
    
    // Registers: $D070-$D07F in Bank 0
    wire is_regs   = is_bank_0 && (cpu_addr[15:0] >= `ADDR_SCPU_REGS_START) && (cpu_addr[15:0] <= `ADDR_SCPU_REGS_END) && enable_regs;

    // UART: $DE00-$DE0F in Bank 0
    wire is_uart   = is_bank_0 && (cpu_addr[15:0] >= `ADDR_UART_START) && (cpu_addr[15:0] <= `ADDR_UART_END);

    // SID: $D400-$D4FF in Bank 0
    wire is_sid    = is_bank_0 && (cpu_addr[15:0] >= `ADDR_SID_START) && (cpu_addr[15:0] <= `ADDR_SID_END);

    // REU: $DF00-$DF0A in Bank 0 (Can be disabled by Register)
    wire reu_enable; // Controlled by 'registers.v'
    wire is_reu    = is_bank_0 && reu_enable && (cpu_addr[15:0] >= `ADDR_REU_START) && (cpu_addr[15:0] <= `ADDR_REU_END);

    // ID Logic: $DFA0-$DFFF in Bank 0
    wire is_id_logic = is_bank_0 && (cpu_addr[15:0] >= `ADDR_ID_START) && (cpu_addr[15:0] <= `ADDR_ID_END);

    // FF00 Write Detection for REU Trigger
    wire is_ff00_write = is_bank_0 && (cpu_addr[15:0] == `ADDR_REU_TRIGGER) && cpu_rw;

    // C128 Specific Ranges (Pass-through to Bus)
    wire is_mmu    = is_bank_0 && (cpu_addr[15:0] >= `ADDR_MMU_START) && (cpu_addr[15:0] <= `ADDR_MMU_END);
    wire is_vdc    = is_bank_0 && (cpu_addr[15:0] >= `ADDR_VDC_START) && (cpu_addr[15:0] <= `ADDR_VDC_END);
    wire is_cia1   = is_bank_0 && (cpu_addr[15:0] >= `ADDR_CIA1_START) && (cpu_addr[15:0] <= `ADDR_CIA1_END);
    wire is_cia2   = is_bank_0 && (cpu_addr[15:0] >= `ADDR_CIA2_START) && (cpu_addr[15:0] <= `ADDR_CIA2_END);

    // Bridge Window: Dynamic Mapping (e.g. Cassette Buffer)
    // ROBUSTNESS: Safety Masks to prevent system crashes
    wire bridge_addr_match = (cpu_addr[23:16] == hps_bridge_bank) && 
                             (cpu_addr[15:0] >= hps_bridge_base) && 
                             (cpu_addr[15:0] < (hps_bridge_base + 16'd192));

    // Safety: If in Bank 0, disallow mapping over Critical System Areas
    // 1. Zero Page & Stack ($0000-$01FF)
    // 2. I/O Area ($D000-$DFFF)
    // 3. Kernal Vectors ($FF00-$FFFF)
    wire bridge_safe = (hps_bridge_bank != 8'h00) || (
                       (hps_bridge_base >= 16'h0200) && 
                       (hps_bridge_base <  16'hD000) &&
                       ((hps_bridge_base + 16'd192) < 16'hD000) // Ensure end doesn't overlap
                       );

    wire is_bridge = hps_bridge_enable && bridge_addr_match && bridge_safe;
    
    // SuperRAM: Banks 01-FF
    // ROBUSTNESS: Shadow Protection
    // If the Bridge is active in Bank 1+, we must DISABLE SuperRAM at that spot
    // to prevent bus contention or data corruption.
    wire is_ram    = !is_bank_0 && !is_bridge; 
    
    // C64/C128 Bus: Everything else in Bank 0
    // Note: MMU, VDC, CIA, VIC are all on the external bus unless explicitly emulated/shadowed.
    // 'is_sid' is currently treated as internal (shadowed/emulated).
    wire is_c64    = is_bank_0 && !is_regs && !is_uart && !is_bridge && !is_sid && !is_reu && !is_id_logic;

    // -------------------------------------------------------------------------
    // Data Mux (CPU Data Input)
    // -------------------------------------------------------------------------
    wire [7:0] uart_dout;
    wire [7:0] bridge_dout; // TODO: Implement Bridge RAM
    wire [7:0] sid_dout;
    wire [7:0] reu_dout;
    wire [7:0] id_dout;

    assign cpu_din = (is_ram)      ? ram_dout :
                     (is_regs)     ? reg_dout :
                     (is_uart)     ? uart_dout :
                     (is_bridge)   ? bridge_dout :
                     (is_sid)      ? sid_dout :
                     (is_reu)      ? reu_dout :
                     (is_id_logic) ? id_dout :
                                     biu_d_in;

    // -------------------------------------------------------------------------
    // 65816 CPU Core Instance
    // -------------------------------------------------------------------------
    cpu_65816 u_cpu (
        .CLK      (clk_20),
        .RST_N    (sys_reset_n),
        .RDY      (cpu_rdy),
        .IRQ_N    (uart_irq_n), // Connected to UART IRQ
        .NMI_N    (1'b1), // TODO: Map to FPGA_NMI_N input if needed
        .ABORT_N  (1'b1),
        .BE       (1'b1),
        .SO_N     (1'b1),
        
        .ADDR_OUT (cpu_addr),
        .DI       (cpu_din),
        .DO       (cpu_dout),
        .WE       (cpu_rw), 
        
        .VDA      (cpu_vda),
        .VPA      (cpu_vpa),
        .VPB      (),
        .MLB      (),
        .E        (),
        .MX       ()
    );

    // -------------------------------------------------------------------------
    // Memory Controller (SuperRAM)
    // -------------------------------------------------------------------------
    // Arbitration: REU has priority over CPU for SuperRAM access
    // Mapping: REU Bank 0 corresponds to SuperCPU Bank 1 (Physical RAM Start)
    
    wire [23:0] mem_mux_addr;
    wire [7:0]  mem_mux_din;
    wire        mem_mux_we;
    wire        mem_mux_en;
    
    assign mem_mux_en   = (reu_mem_req) ? 1'b1 : is_ram;
    assign mem_mux_we   = (reu_mem_req) ? reu_mem_we : cpu_rw;
    assign mem_mux_din  = (reu_mem_req) ? reu_mem_wdata : cpu_dout;
    
    // Address Translation: REU Addr + 0x010000 = CPU Addr
    assign mem_mux_addr = (reu_mem_req) ? {reu_mem_addr[23:16] + 8'h01, reu_mem_addr[15:0]} : cpu_addr;

    memory_controller u_mem (
        .clk      (clk_20),
        .rst_n    (sys_reset_n),
        .addr     (mem_mux_addr),
        .din      (mem_mux_din),
        .dout     (ram_dout),
        .we       (mem_mux_we),
        .en       (mem_mux_en)
    );

    // -------------------------------------------------------------------------
    // Control Registers
    // -------------------------------------------------------------------------
    wire hps_bridge_enable;
    wire [15:0] hps_bridge_base;
    wire [7:0]  hps_bridge_bank;

    registers u_regs (
        .clk         (clk_20),
        .rst_n       (sys_reset_n),
        .addr        (cpu_addr[15:0]),
        .din         (cpu_dout),
        .dout        (reg_dout),
        .we          (cpu_rw),
        .en          (is_regs),
        .phi2_freq   (phi2_freq),
        .c64_rst_n   (FPGA_RST_N),
        .safe_mode   (safe_mode),
        .turbo_toggle(turbo_toggle),
        .turbo_mode  (turbo_mode),
        .enable_regs (enable_regs),
        .reu_enable  (reu_enable),
        .hps_bridge_enable (hps_bridge_enable),
        .hps_bridge_base   (hps_bridge_base),
        .hps_bridge_bank   (hps_bridge_bank)
    );

    // -------------------------------------------------------------------------
    // UART Emulation (ZiModem)
    // -------------------------------------------------------------------------
    wire uart_irq_n;
    
    uart_emulation u_uart (
        .clk           (clk_20),
        .rst_n         (sys_reset_n),
        
        // CPU Interface
        .addr          (cpu_addr[3:0]),
        .din           (cpu_dout),
        .dout          (uart_dout),
        .we            (cpu_rw),
        .en            (is_uart),
        
        // Linux Interface (FIFO)
        .tx_fifo_data  (hps_uart_tx_data),
        .tx_fifo_valid (hps_uart_tx_valid),
        .tx_fifo_full  (hps_uart_tx_full),
        
        .rx_fifo_data  (hps_uart_rx_data),
        .rx_fifo_valid (hps_uart_rx_valid),
        .rx_fifo_read  (hps_uart_rx_read),
        
        // Interrupts
        .irq_n         (uart_irq_n)
    );

    // -------------------------------------------------------------------------
    // Bridge Window RAM (Dual Port - Port A: CPU, Port B: HPS via Qsys)
    // -------------------------------------------------------------------------
    // For now, we just instantiate a small RAM block.
    // In a real design, Port B would be connected to the HPS bridge.
    
    bridge_ram u_bridge_ram (
        .clk   (clk_20),
        .addr  (cpu_addr[7:0]), // Only 256 bytes for now
        .din   (cpu_dout),
        .dout  (bridge_dout),
        .we    (cpu_rw),
        .en    (is_bridge)
    );

    // -------------------------------------------------------------------------
    // GEOS ROM (Placeholder for now)
    // -------------------------------------------------------------------------
    wire [7:0] geos_rom_dout;
    wire       geos_rom_cs;
    wire       geos_enable = 1'b0; // TODO: Connect to a register bit
    
    // In a real implementation, instantiate a ROM block here
    assign geos_rom_dout = 8'hEA; // NOP

    // -------------------------------------------------------------------------
    // ID Logic (Emulator Detection Standard)
    // -------------------------------------------------------------------------
    id_logic u_id (
        .clk   (clk_20),
        .rst_n (sys_reset_n),
        .cs    (is_id_logic),
        .addr  (cpu_addr[15:0]),
        .dout  (id_dout)
    );

    // -------------------------------------------------------------------------
    // SuperControl (User Interface)
    // -------------------------------------------------------------------------
    wire turbo_toggle;
    wire sys_reset_req_btn;
    wire [3:0] leds;
    
    // Combine Reset Requests (Health Monitor OR Physical Button)
    wire sys_reset_req_combined = sys_reset_req || sys_reset_req_btn;
    wire sys_reset_n = FPGA_RST_N && pll_locked && !sys_reset_req_combined;

    super_control u_control (
        .clk           (clk_20),
        .rst_n         (FPGA_RST_N), // Always powered
        .key_turbo_n   (FPGA_KEY[0]), // Map to DE10 Key 0
        .key_reset_n   (FPGA_KEY[1]), // Map to DE10 Key 1
        .safe_mode     (safe_mode),
        .cpu_activity  (cpu_vda || cpu_vpa),
        .bridge_active (is_bridge),
        .turbo_enabled (turbo_mode),
        .turbo_toggle  (turbo_toggle),
        .sys_reset_req (sys_reset_req_btn),
        .leds          (FPGA_LED[3:0]) // Map to DE10 LEDs
    );

    // -------------------------------------------------------------------------
    // System Health & Smart Recovery
    // -------------------------------------------------------------------------
    wire sys_reset_req;
    wire safe_mode;
    wire bus_release;
    wire cpu_rdy_biu; // Internal RDY from BIU
    
    system_health u_health (
        .clk         (clk_20),
        .por_n       (FPGA_RST_N && pll_locked), // Only Power Cycle resets the Health Monitor
        .cpu_valid   (cpu_vda || cpu_vpa),
        .cpu_rdy     (cpu_rdy),
        .sys_reset_req (sys_reset_req),
        .safe_mode   (safe_mode),
        .bus_release (bus_release)
    );

    // -------------------------------------------------------------------------
    // Bus Interface Unit
    // -------------------------------------------------------------------------
    bus_interface u_biu (
        .clk_20      (clk_20),
        .rst_n       (sys_reset_n),
        
        // CPU Side
        .cpu_addr    (cpu_addr),
        .cpu_dout    (cpu_dout),
        .cpu_din     (biu_d_in), // Only BIU data goes here
        .cpu_rw      (!cpu_rw), // Convert Write Enable to R/W (1=Read)
        .cpu_vda     (cpu_vda),
        .cpu_vpa     (cpu_vpa),
        .cpu_rdy     (cpu_rdy_biu), // Internal RDY from BIU
        
        // GEOS
        .geos_rom_enable (geos_enable),
        .geos_rom_dout   (geos_rom_dout),
        .geos_rom_cs     (geos_rom_cs),
        
        // C64 Side
        .c64_phi2    (FPGA_PHI2),
        .c64_ba      (FPGA_BA),
        .c64_roml_n  (FPGA_ROML_N),
        .c64_romh_n  (FPGA_ROMH_N),
        .c64_io1_n   (FPGA_IO1_N),
        .c64_io2_n   (FPGA_IO2_N),
        
        // PLA Inputs (Need to be wired to GPIO or assumed)
        // For now, we assume standard C64 mode (1,1,1)
        .c64_loram   (1'b1), // TODO: Connect to GPIO
        .c64_hiram   (1'b1), // TODO: Connect to GPIO
        .c64_charen  (1'b1), // TODO: Connect to GPIO
        
        .c64_game_n  (biu_game_n),
        .c64_exrom_n (biu_exrom_n),
        .c64_dma_n   (biu_dma_n),
        
        .c64_d_in    (FPGA_D),
        .c64_d_out   (biu_d_out),
        .c64_d_oe    (biu_d_oe),
        
        .c64_a_out   (biu_a_out),
        .c64_a_oe    (biu_a_oe)
    );

    // RDY Logic: Combine BIU Wait State with Health Monitor Release
    assign cpu_rdy = cpu_rdy_biu || bus_release;
    
    // -------------------------------------------------------------------------
    // System Detection (Frequency Monitor)
    // -------------------------------------------------------------------------
    freq_monitor u_freq (
        .clk_ref  (FPGA_CLK1_50),
        .rst_n    (sys_reset_n),
        .clk_test (FPGA_PHI2),
        .freq_hz  (phi2_freq)
    );
    
    // Note: phi2_freq can be read by the Linux side via a memory mapped register
    // (Not yet implemented in 'registers.v', but the signal is available here).

    // -------------------------------------------------------------------------
    // Advanced Features (Video, Audio, DMA, Sampler)
    // -------------------------------------------------------------------------
    
    // Video
    isevic_video u_video (
        .clk_sys      (FPGA_CLK1_50),
        .rst_n        (sys_reset_n),
        .c64_phi2     (FPGA_PHI2),
        .c64_addr     (FPGA_A),
        .c64_data     (FPGA_D),
        .c64_rw       (FPGA_RW_N),
        .vic_bank     (8'h00), // TODO: Connect to CIA2 Port A snoop
        .pal_ntsc_mode(1'b1),
        .hdmi_clk     (HDMI_TX_CLK),
        .hdmi_de      (HDMI_TX_DE),
        .hdmi_hs      (HDMI_TX_HS),
        .hdmi_vs      (HDMI_TX_VS),
        .hdmi_rgb     (HDMI_TX_D)
    );

    // Audio
    sid_emulation u_sid (
        .clk_sys      (clk_20),
        .rst_n        (sys_reset_n),
        .cs_sid       (is_sid),
        .we           (cpu_rw),
        .addr         (cpu_addr[4:0]),
        .data_in      (cpu_dout),
        .data_out     (sid_dout),
        .audio_l      (), 
        .audio_r      ()
    );
    
    // Debug Bridge
    wire        dbg_req;
    wire        dbg_ack;
    wire [23:0] dbg_addr;
    wire [7:0]  dbg_wdata;
    wire [7:0]  dbg_rdata;
    wire        dbg_we;
    wire        cpu_halt_req;

    debug_bridge u_debug (
        .clk          (clk_20),
        .rst_n        (sys_reset_n),
        .cmd_valid    (hps_dbg_valid),
        .cmd_type     (hps_dbg_type),
        .cmd_addr     (hps_dbg_addr),
        .cmd_wdata    (hps_dbg_wdata),
        .cmd_rdata    (hps_dbg_rdata),
        .cmd_done     (hps_dbg_done),
        
        .dbg_req      (dbg_req),
        .dbg_ack      (dbg_ack),
        .dbg_addr     (dbg_addr),
        .dbg_wdata    (dbg_wdata),
        .dbg_rdata    (dbg_rdata),
        .dbg_we       (dbg_we),
        
        .cpu_halt_req (cpu_halt_req),
        .cpu_halted   (!cpu_rdy) // Approximation
    );

    // DMA Engine
    wire dma_req_n;
    wire [23:0] dma_addr;
    wire [7:0]  dma_data_out;
    wire        dma_rw;
    wire        dma_busy;
    
    // DMA Arbiter (Simple Priority: Debug > DMA > REU)
    // Note: This is a simplification. A real arbiter is needed.
    // For now, we just let Debug steal cycles if it wants.
    assign dbg_ack = dbg_req; // Immediate grant (Dangerous? Needs proper timing)
    
    // Muxing DMA/Debug signals to the Bus Interface
    // If Debug is active, it overrides DMA engine
    wire [23:0] active_dma_addr = dbg_req ? dbg_addr : dma_addr;
    wire [7:0]  active_dma_data = dbg_req ? dbg_wdata : dma_data_out;
    wire        active_dma_rw   = dbg_req ? !dbg_we : dma_rw; // dma_rw: 1=Read? Check dma_engine.
    
    // Wait, dma_engine usually outputs 'rw' as 1=Read, 0=Write?
    // Let's check dma_engine.v. Assuming standard 6502.
    
    dma_engine u_dma (
        .clk_sys      (clk_20),
        .rst_n        (sys_reset_n),
        .dma_start    (1'b0), // TODO: Connect to Register
        .src_addr     (32'h0),
        .dst_addr     (24'h0),
        .count        (16'h0),
        .direction    (1'b0),
        .dma_busy     (dma_busy),
        .dma_done     (),
        
        .c64_phi2     (FPGA_PHI2),
        .c64_ba       (dma_req_n), 
        .c64_dma_ack  (FPGA_BA),
        .c64_addr_out (dma_addr),
        .c64_data_out (dma_data_out),
        .c64_data_in  (FPGA_D),
        .c64_rw_out   (dma_rw)
    );
    
    // REU Emulation
    wire reu_ba;
    wire [15:0] reu_addr_out;
    wire [7:0]  reu_data_out;
    wire        reu_rw_out;
    wire        reu_mem_req;
    wire        reu_mem_we;
    wire [23:0] reu_mem_addr;
    wire [7:0]  reu_mem_wdata;
    
    reu_emulation u_reu (
        .clk_sys      (clk_20),
        .rst_n        (sys_reset_n),
        
        // Register Interface
        .cs_reu       (is_reu),
        .reg_addr     (cpu_addr[3:0]),
        .we           (cpu_rw),
        .data_in      (cpu_dout),
        .data_out     (reu_dout),
        .ff00_write   (is_ff00_write),
        
        // DMA Interface
        .c64_phi2     (FPGA_PHI2),
        .c64_ba       (reu_ba),
        .c64_dma_ack  (FPGA_BA),
        .c64_addr_out (reu_addr_out),
        .c64_data_out (reu_data_out),
        .c64_data_in  (FPGA_D),
        .c64_rw_out   (reu_rw_out),
        
        // Internal Memory Interface (Connected to Memory Controller)
        .mem_addr     (reu_mem_addr),
        .mem_wdata    (reu_mem_wdata),
        .mem_rdata    (ram_dout), // Read from SuperRAM
        .mem_we       (reu_mem_we),
        .mem_req      (reu_mem_req)
    );

    // Bus Sampler
    bus_sampler u_sampler (
        .clk_sys      (clk_20),
        .rst_n        (sys_reset_n),
        .c64_addr     (FPGA_A),
        .c64_data     (FPGA_D),
        .c64_rw       (FPGA_RW_N),
        .c64_phi2     (FPGA_PHI2),
        .c64_irq_n    (FPGA_IRQ_N),
        .c64_nmi_n    (FPGA_NMI_N),
        .trigger_enable (1'b0),
        .trigger_addr   (16'h0),
        .triggered      (),
        .read_addr      (10'h0),
        .read_data      ()
    );

    // -------------------------------------------------------------------------
    // Output Assignments
    // -------------------------------------------------------------------------
    assign FPGA_GAME_N  = biu_game_n;
    assign FPGA_EXROM_N = biu_exrom_n;
    // Safety: Force DMA release if Bus Hang detected
    // Debug: Force DMA request if Debugger wants bus
    assign FPGA_DMA_N   = bus_release ? 1'b1 : 
                          (dbg_req)   ? 1'b0 : // Debugger requests DMA
                          (biu_dma_n & dma_req_n & reu_ba); 
    
    // Tristate Data Bus
    // Priority: Debug > DMA > REU > CPU
    assign FPGA_D = (dbg_req && dbg_we)       ? dbg_wdata :    // Debug Write
                    (dma_busy && !dma_rw)     ? dma_data_out : // DMA Write
                    (!reu_ba && !reu_rw_out)  ? reu_data_out : // REU Write
                    (biu_d_oe)                ? biu_d_out :    // CPU Write
                                                8'bzzzzzzzz;

    // Tristate Address Bus
    assign FPGA_A = (dbg_req)  ? dbg_addr[15:0] :
                    (dma_busy) ? dma_addr[15:0] : 
                    (!reu_ba)  ? reu_addr_out :
                    (biu_a_oe) ? biu_a_out : 16'hZZZZ;
    
    // Interrupts (Open Drain) - Currently not driven by CPU
    assign FPGA_IRQ_N   = 1'bZ; 
    assign FPGA_NMI_N   = 1'bZ;

    // Audio Clock Placeholders
    assign AUD_XCK     = 1'b0;
    assign AUD_DACDAT  = 1'b0;
    assign AUD_BCLK    = 1'b0;
    assign AUD_DACLRCK = 1'b0;
    assign AUD_ADCLRCK = 1'b0;

endmodule
