// SuperCPU Bus Interface Unit (BIU)
// Handles synchronization between the 20MHz CPU Domain and the 1MHz C64 Bus Domain.

module bus_interface (
    // Fast Domain (20MHz)
    input  wire        clk_20,
    input  wire        rst_n,
    
    // CPU Interface
    input  wire [23:0] cpu_addr,
    input  wire [7:0]  cpu_dout,
    output reg  [7:0]  cpu_din,
    input  wire        cpu_rw,      // 1=Read, 0=Write
    input  wire        cpu_vda,     // Valid Data Address
    input  wire        cpu_vpa,     // Valid Program Address
    output reg         cpu_rdy,     // 1=Run, 0=Pause
    
    // C64 Bus Interface (1MHz Domain - Asynchronous to clk_20)
    input  wire        c64_phi2,
    input  wire        c64_ba,
    input  wire        c64_roml_n,
    input  wire        c64_romh_n,
    input  wire        c64_io1_n,
    input  wire        c64_io2_n,
    
    // C64 Control Outputs
    output reg         c64_game_n,
    output reg         c64_exrom_n,
    output reg         c64_dma_n,
    
    // PLA / Banking Signals (Inputs from C64 PLA/MMU)
    input  wire        c64_loram,
    input  wire        c64_hiram,
    input  wire        c64_charen,
    
    // GEOS ROM Banking
    input  wire        geos_rom_enable, // 1 = Map GEOS ROM
    input  wire [7:0]  geos_rom_dout,   // Data from Internal GEOS ROM
    output wire        geos_rom_cs,     // Chip Select for GEOS ROM
    
    // C64 Data Bus (Bidirectional)
    input  wire [7:0]  c64_d_in,
    output reg  [7:0]  c64_d_out,
    output reg         c64_d_oe,    // Output Enable for Data Bus

    // C64 Address Bus (Output when DMA active)
    output reg  [15:0] c64_a_out,
    output reg         c64_a_oe     // Output Enable for Address Bus
);

    // -------------------------------------------------------------------------
    // Address Decoding & PLA Logic
    // -------------------------------------------------------------------------
    // Determine if the current CPU access targets Internal RAM or External C64 Bus.
    // SuperCPU Memory Map (Simplified):
    // Bank 00: Mapped to C64 (mostly)
    // Bank 01-FF: SuperRAM (Fast)
    
    wire is_bank_0;
    assign is_bank_0 = (cpu_addr[23:16] == 8'h00);
    
    // PLA Logic Implementation (Based on c64-pla.txt)
    // We need to know if an address hits C64 RAM, ROM, or I/O to decide
    // whether to fetch from C64 Bus or Internal Shadow RAM (if implemented).
    // For now, we use this to determine if we should assert GAME/EXROM or
    // if we are accessing internal GEOS ROM.
    
    wire [15:0] addr = cpu_addr[15:0];
    
    // Basic Range Checks
    wire is_basic  = (addr >= 16'hA000 && addr <= 16'hBFFF);
    wire is_kernal = (addr >= 16'hE000 && addr <= 16'hFFFF);
    wire is_char   = (addr >= 16'hD000 && addr <= 16'hDFFF);
    wire is_io     = (addr >= 16'hD000 && addr <= 16'hDFFF); // Overlaps Char
    
    // PLA Equations (Simplified for Banking Decision)
    // BASIC ROM Active: HIRAM=1, LORAM=1, GAME=1, EXROM=1
    wire basic_active = c64_loram && c64_hiram && c64_game_n && c64_exrom_n;
    
    // KERNAL ROM Active: HIRAM=1, GAME=1, EXROM=1
    wire kernal_active = c64_hiram && c64_game_n && c64_exrom_n;
    
    // CHAR ROM Active: LORAM=1, HIRAM=1, CHAREN=0, GAME=1, EXROM=1
    wire char_active = c64_loram && c64_hiram && !c64_charen && c64_game_n && c64_exrom_n;
    
    // I/O Active: LORAM=1, HIRAM=1, CHAREN=1, GAME=1, EXROM=1
    wire io_active = c64_loram && c64_hiram && c64_charen && c64_game_n && c64_exrom_n;

    // GEOS ROM Mapping: Usually $C000-$CFFF or similar, depending on banking.
    // If enabled, we intercept reads to this range and serve from internal ROM.
    // Assuming GEOS ROM is mapped at $C000-$FFFF (16K) or similar.
    // Let's assume standard C128 Function ROM slot: $8000-$BFFF or $C000-$FFFF
    // For this implementation, we'll map it to $C000-$FFFF if enabled.
    
    wire is_geos_range = (cpu_addr[15:14] == 2'b11); // $C000-$FFFF
    assign geos_rom_cs = is_bank_0 && geos_rom_enable && is_geos_range && cpu_rw;
    
    wire access_c64;
    assign access_c64 = is_bank_0 && (cpu_vda || cpu_vpa) && !geos_rom_cs;

    // -------------------------------------------------------------------------
    // Synchronization Logic
    // -------------------------------------------------------------------------
    // We need to detect the rising and falling edges of PHI2 in the 20MHz domain.
    
    reg [2:0] phi2_sync;
    always @(posedge clk_20 or negedge rst_n) begin
        if (!rst_n) phi2_sync <= 3'b000;
        else phi2_sync <= {phi2_sync[1:0], c64_phi2};
    end
    
    wire phi2_rising  = (phi2_sync[2:1] == 2'b01);
    wire phi2_falling = (phi2_sync[2:1] == 2'b10);
    wire phi2_high    = phi2_sync[1];

    // -------------------------------------------------------------------------
    // State Machine
    // -------------------------------------------------------------------------
    localparam S_IDLE       = 0;
    localparam S_WAIT_PHI2  = 1;
    localparam S_ACCESS     = 2;
    localparam S_HOLD       = 3;
    
    reg [1:0] state;
    
    always @(posedge clk_20 or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            cpu_rdy <= 1'b1;
            c64_dma_n <= 1'b0; // Default to DMA Active (Halt 6510)
            c64_d_oe <= 1'b0;
            c64_a_oe <= 1'b0;
            c64_a_out <= 16'h0000;
        end else begin
            case (state)
                S_IDLE: begin
                    if (geos_rom_cs && cpu_rw) begin
                        // Fast Read from Internal GEOS ROM
                        cpu_din <= geos_rom_dout;
                        cpu_rdy <= 1'b1;
                    end else if (access_c64) begin
                        // CPU wants to access C64. Pause CPU.
                        cpu_rdy <= 1'b0;
                        // DMA is already Low
                        state <= S_WAIT_PHI2;
                    end else begin
                        // Fast Access (SuperRAM)
                        cpu_rdy <= 1'b1;
                        // DMA stays Low
                    end
                end
                
                S_WAIT_PHI2: begin
                    // Wait for PHI2 to go High (Start of C64 Cycle)
                    // AND ensure BA is High (Bus Available)
                    if (phi2_rising && c64_ba) begin
                        state <= S_ACCESS;
                        
                        // Drive Address
                        c64_a_out <= cpu_addr[15:0];
                        c64_a_oe <= 1'b1;
                        
                        // Setup Data if Write
                        if (!cpu_rw) begin
                            c64_d_out <= cpu_dout;
                            c64_d_oe <= 1'b1;
                        end
                    end
                end
                
                S_ACCESS: begin
                    // Wait for PHI2 to go Low (End of C64 Cycle)
                    if (phi2_falling) begin
                        // Latch Data if Read
                        if (cpu_rw) begin
                            cpu_din <= c64_d_in;
                        end
                        // Release Bus
                        c64_d_oe <= 1'b0;
                        c64_a_oe <= 1'b0;
                        
                        // Resume CPU
                        cpu_rdy <= 1'b1;
                        state <= S_HOLD;
                    end
                end
                
                S_HOLD: begin
                    // Hold RDY high for one cycle to let CPU advance
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Passthrough Signals
    // -------------------------------------------------------------------------
    // For now, hardcode GAME/EXROM to emulate a standard cartridge or SuperCPU mode
    always @(posedge clk_20) begin
        c64_game_n  <= 1'b0; // Assert GAME (16K Cartridge Mode / Ultimax?) - TBD
        c64_exrom_n <= 1'b0; // Assert EXROM
    end

endmodule
