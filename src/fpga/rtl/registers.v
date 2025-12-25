// SuperCPU Control Registers
// Handles configuration and status registers.
// Mapped to $D070 - $D07F (Standard CMD SuperCPU location)

module registers (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface
    input  wire [15:0] addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    input  wire        we,      // 1 = Write
    input  wire        en,      // 1 = Chip Select (Address Match)
    
    // Hardware Inputs (Status)
    input  wire [31:0] phi2_freq,   // Measured PHI2 Frequency
    input  wire        c64_rst_n,   // Live C64 Reset Line
    input  wire        safe_mode,   // 1 = Safe Mode Active (Force Defaults)
    input  wire        turbo_toggle,// 1 = Pulse to toggle Turbo
    
    // Control Outputs
    output reg         turbo_mode,  // 1 = 20MHz, 0 = 1MHz
    output reg         enable_regs, // 1 = Registers Visible
    output reg         reu_enable,  // 1 = Internal REU Enabled
    output reg         hps_bridge_enable, // 1 = Bridge Window Active
    output reg  [15:0] hps_bridge_base,   // Base Address for Bridge Window
    output reg  [7:0]  hps_bridge_bank    // Bank Address for Bridge Window
);

    // -------------------------------------------------------------------------
    // Register Definitions
    // -------------------------------------------------------------------------
    // $D070: Control Register 1 (CMD Compatible)
    //        Bit 7: Turbo Switch (Read Only?)
    //        Bit 6: Turbo Enable (R/W)
    //        Bit 5: REU Enable (New - Default 1)
    
    // $D074: System Status (New)
    //        Bit 0: C64 Reset Line Status (0=Resetting, 1=Running)
    //        Bit 1: C128 Mode Detected (Based on Frequency > 1.5MHz)
    
    // $D075-$D078: PHI2 Frequency (32-bit, Little Endian)

    // $D07A: Bridge Control (New)
    //        Bit 0: Enable Bridge Window
    // $D07B: Bridge Base Address Low
    // $D07C: Bridge Base Address High
    // $D07D: Bridge Bank Address (New - Default $00)
    
    reg [7:0] reg_d070;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_d070    <= 8'h60; // Default Turbo ON (Bit 6), REU ON (Bit 5)
            turbo_mode  <= 1'b1;
            enable_regs <= 1'b1;
            reu_enable  <= 1'b1;
            hps_bridge_enable <= 1'b0; // Default Disabled (Safety)
            hps_bridge_base   <= 16'h033C; // Default to Cassette Buffer
            hps_bridge_bank   <= 8'h00;    // Default to Bank 0 (C64 Compatibility)
        end else if (safe_mode) begin
            // Safe Mode Override: Disable all enhancements
            reg_d070    <= 8'h00; 
            turbo_mode  <= 1'b0; // Force 1MHz
            enable_regs <= 1'b1; // Keep registers visible for debugging
            reu_enable  <= 1'b0; // Disable REU
            hps_bridge_enable <= 1'b0; // Disable Bridge
        end else begin
            // Physical Button Override
            if (turbo_toggle) begin
                turbo_mode <= !turbo_mode;
                reg_d070[6] <= !turbo_mode; // Update register shadow
            end
            
            // CPU Write Logic
            if (en && we) begin
                case (addr[3:0])
                    4'h0: begin // $D070
                        reg_d070 <= din;
                        turbo_mode <= din[6];
                        reu_enable <= din[5];
                    end
                    4'hA: hps_bridge_enable <= din[0]; // $D07A
                    4'hB: hps_bridge_base[7:0] <= din; // $D07B
                    4'hC: hps_bridge_base[15:8] <= din; // $D07C
                    4'hD: hps_bridge_bank <= din;      // $D07D
                    // Add more registers here
                endcase
            end
        end
    end
    
    // Read Logic
    always @(*) begin
        dout = 8'hFF; // Default Open Bus
        if (en) begin
            case (addr[3:0])
                4'h0: dout = reg_d070;
                
                // New Status Registers
                4'h4: dout = {6'b0, (phi2_freq > 1500000), c64_rst_n}; // $D074
                
                // Frequency Counter (Read Only)
                4'h5: dout = phi2_freq[7:0];   // $D075
                4'h6: dout = phi2_freq[15:8];  // $D076
                4'h7: dout = phi2_freq[23:16]; // $D077
                4'h8: dout = phi2_freq[31:24]; // $D078

                // Bridge Registers
                4'hA: dout = {7'b0, hps_bridge_enable};
                4'hB: dout = hps_bridge_base[7:0];
                4'hC: dout = hps_bridge_base[15:8];
                4'hD: dout = hps_bridge_bank;
                
                default: dout = 8'hFF;
            endcase
        end
    end

endmodule
