// REU Emulation Module (Commodore 1700/1750/1764 Compatible)
// Implements DMA transfers between C64 System RAM and Internal SuperRAM.
// Base Address: $DF00 (IO2)
// Updated for Robustness: FF00 Trigger, Swap, Verify, Status Clear

module reu_emulation (
    input  wire        clk_sys,      // System Clock (e.g. 20MHz or 50MHz)
    input  wire        rst_n,
    
    // C64 Bus Interface (Slave - Register Access)
    input  wire        cs_reu,       // Chip Select ($DF00-$DF0A)
    input  wire [3:0]  reg_addr,     // Register Offset
    input  wire        we,           // Write Enable
    input  wire [7:0]  data_in,      // Data Input
    output reg  [7:0]  data_out,     // Data Output
    input  wire        ff00_write,   // Trigger signal from $FF00 write
    
    // DMA Interface (Master - Bus Control)
    input  wire        c64_phi2,     // PHI2 Clock
    output reg         c64_ba,       // Bus Available (Low = Request DMA)
    input  wire        c64_dma_ack,  // Acknowledge (Bus Granted)
    output reg [15:0]  c64_addr_out, // Address to C64 Bus
    output reg [7:0]   c64_data_out, // Data to C64 Bus
    input  wire [7:0]  c64_data_in,  // Data from C64 Bus
    output reg         c64_rw_out,   // 1=Read, 0=Write
    
    // Internal Memory Interface (SuperRAM)
    output reg [23:0]  mem_addr,     // Address to Internal RAM
    output reg [7:0]   mem_wdata,    // Data to Internal RAM
    input  wire [7:0]  mem_rdata,    // Data from Internal RAM
    output reg         mem_we,       // Write Enable Internal RAM
    output reg         mem_req       // Request Internal RAM Access
);

    // -------------------------------------------------------------------------
    // Registers
    // -------------------------------------------------------------------------
    reg [7:0] r_status;      // 00: Status
    reg [7:0] r_command;     // 01: Command
    reg [15:0] r_c64_addr;   // 02-03: C64 Address
    reg [23:0] r_reu_addr;   // 04-06: REU Address
    reg [15:0] r_transfer_len;// 07-08: Transfer Length
    reg [7:0] r_irq_mask;    // 09: Interrupt Mask
    reg [7:0] r_addr_control;// 0A: Address Control
    
    // Shadow registers for Autoload
    reg [15:0] s_c64_addr;
    reg [23:0] s_reu_addr;
    reg [15:0] s_transfer_len;

    // -------------------------------------------------------------------------
    // Register Read/Write
    // -------------------------------------------------------------------------
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            r_status <= 8'h10; // Version=0, Size=1 (>256KB)
            r_command <= 0;
            r_c64_addr <= 0;
            r_reu_addr <= 0;
            r_transfer_len <= 0;
            r_irq_mask <= 0;
            r_addr_control <= 0;
            
            s_c64_addr <= 0;
            s_reu_addr <= 0;
            s_transfer_len <= 0;
        end else begin
            // Register Write
            if (cs_reu && we) begin
                case (reg_addr)
                    4'h1: begin 
                        r_command <= data_in;
                        // Autoload capture on Execute bit set
                        if (data_in[7]) begin
                            s_c64_addr <= r_c64_addr;
                            s_reu_addr <= r_reu_addr;
                            s_transfer_len <= r_transfer_len;
                        end
                    end
                    4'h2: r_c64_addr[7:0] <= data_in;
                    4'h3: r_c64_addr[15:8] <= data_in;
                    4'h4: r_reu_addr[7:0] <= data_in;
                    4'h5: r_reu_addr[15:8] <= data_in;
                    4'h6: r_reu_addr[23:16] <= data_in | 8'hF8; // Set unused bits high
                    4'h7: r_transfer_len[7:0] <= data_in;
                    4'h8: r_transfer_len[15:8] <= data_in;
                    4'h9: r_irq_mask <= data_in;
                    4'hA: r_addr_control <= data_in;
                endcase
            end
            
            // Status Register Clear on Read
            if (cs_reu && !we && reg_addr == 4'h0) begin
                r_status[7:5] <= 3'b000; // Clear Interrupt, End, Fault
            end
            
            // Update Status from State Machine (Logic below overrides this if needed)
            if (status_update_en) begin
                r_status[7:5] <= status_update_val;
            end
            
            // Clear FF00 Trigger bit if used
            if (clear_ff00_bit) begin
                r_command[4] <= 0;
            end
            
            // Clear Execute bit when done
            if (clear_execute_bit) begin
                r_command[7] <= 0;
            end
            
            // Address/Length Updates from State Machine
            if (update_regs) begin
                r_c64_addr <= next_c64_addr;
                r_reu_addr <= next_reu_addr;
                r_transfer_len <= next_transfer_len;
            end
            
            // Autoload Restore
            if (autoload_restore) begin
                r_c64_addr <= s_c64_addr;
                r_reu_addr <= s_reu_addr;
                r_transfer_len <= s_transfer_len;
            end
        end
    end
    
    always @(*) begin
        case (reg_addr)
            4'h0: data_out = r_status;
            4'h1: data_out = r_command;
            4'h2: data_out = r_c64_addr[7:0];
            4'h3: data_out = r_c64_addr[15:8];
            4'h4: data_out = r_reu_addr[7:0];
            4'h5: data_out = r_reu_addr[15:8];
            4'h6: data_out = r_reu_addr[23:16] | 8'hF8;
            4'h7: data_out = r_transfer_len[7:0];
            4'h8: data_out = r_transfer_len[15:8];
            4'h9: data_out = r_irq_mask | 8'h1F;
            4'hA: data_out = r_addr_control | 8'h3F;
            default: data_out = 8'hFF;
        endcase
    end

    // -------------------------------------------------------------------------
    // PHI2 Edge Detection
    // -------------------------------------------------------------------------
    reg [1:0] phi2_sr;
    always @(posedge clk_sys) phi2_sr <= {phi2_sr[0], c64_phi2};
    wire phi2_rise = (phi2_sr == 2'b01);
    wire phi2_fall = (phi2_sr == 2'b10);

    // -------------------------------------------------------------------------
    // DMA State Machine
    // -------------------------------------------------------------------------
    localparam IDLE = 0;
    localparam WAIT_FF00 = 1;
    localparam REQ_BUS = 2;
    localparam READ_SYS = 3;
    localparam READ_REU = 4;
    localparam READ_REU_INTERNAL = 5;
    localparam WRITE_REU = 6;
    localparam WRITE_SYS = 7;
    localparam WRITE_REU_SWAP = 8;
    localparam WRITE_SYS_SWAP = 9;
    localparam VERIFY_COMPARE = 10;
    localparam UPDATE_ADDR = 11;
    localparam FINISH = 12;
    
    reg [3:0] state;
    reg [7:0] temp_sys;
    reg [7:0] temp_reu;
    
    // Control Signals generated by State Machine
    reg status_update_en;
    reg [2:0] status_update_val;
    reg clear_ff00_bit;
    reg clear_execute_bit;
    reg update_regs;
    reg autoload_restore;
    
    // Next values for registers
    reg [15:0] next_c64_addr;
    reg [23:0] next_reu_addr;
    reg [15:0] next_transfer_len;
    
    wire [1:0] transfer_type = r_command[1:0]; // 00=Sys->REU, 01=REU->Sys, 10=Swap, 11=Verify
    wire       fixed_c64     = r_addr_control[7];
    wire       fixed_reu     = r_addr_control[6];
    
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            c64_ba <= 1; // High = Bus Free
            mem_req <= 0;
            mem_we <= 0;
            status_update_en <= 0;
            clear_ff00_bit <= 0;
            clear_execute_bit <= 0;
            update_regs <= 0;
            autoload_restore <= 0;
            phi2_sr <= 0;
        end else begin
            // Defaults
            status_update_en <= 0;
            clear_ff00_bit <= 0;
            clear_execute_bit <= 0;
            update_regs <= 0;
            autoload_restore <= 0;
            mem_req <= 0;
            mem_we <= 0;
            
            case (state)
                IDLE: begin
                    c64_ba <= 1;
                    if (r_command[7]) begin // Execute
                        if (r_command[4]) begin // FF00 Trigger
                            state <= WAIT_FF00;
                        end else begin
                            state <= REQ_BUS;
                        end
                    end
                end
                
                WAIT_FF00: begin
                    if (ff00_write) begin
                        clear_ff00_bit <= 1;
                        state <= REQ_BUS;
                    end
                    if (!r_command[7]) state <= IDLE;
                end
                
                REQ_BUS: begin
                    c64_ba <= 0; // Request Bus
                    if (c64_dma_ack) begin
                        // Determine first step based on type
                        if (transfer_type == 2'b01) // REU -> Sys
                            state <= READ_REU;
                        else // Sys->REU, Swap, Verify
                            state <= READ_SYS;
                    end
                end
                
                READ_SYS: begin
                    // Read from C64
                    c64_rw_out <= 1; // Read
                    c64_addr_out <= r_c64_addr;
                    
                    // Wait for end of PHI2 cycle (Data Valid)
                    if (phi2_fall) begin
                        state <= (transfer_type == 2'b00) ? WRITE_REU : READ_REU_INTERNAL;
                    end
                end
                
                READ_REU: begin
                    // Read from REU (for REU->Sys)
                    mem_req <= 1;
                    mem_we <= 0;
                    mem_addr <= r_reu_addr;
                    state <= WRITE_SYS;
                end
                
                READ_REU_INTERNAL: begin
                    // Capture Sys Data from previous cycle (latched at phi2_fall)
                    temp_sys <= c64_data_in;
                    
                    // Read from REU (for Swap/Verify)
                    mem_req <= 1;
                    mem_we <= 0;
                    mem_addr <= r_reu_addr;
                    
                    state <= (transfer_type == 2'b10) ? WRITE_REU_SWAP : VERIFY_COMPARE;
                end
                
                WRITE_REU: begin
                    // Capture Sys Data (if coming from READ_SYS directly)
                    if (transfer_type == 2'b00) temp_sys <= c64_data_in;
                    
                    // Write to REU
                    mem_req <= 1;
                    mem_we <= 1;
                    mem_addr <= r_reu_addr;
                    mem_wdata <= (transfer_type == 2'b00) ? c64_data_in : temp_sys;
                    
                    state <= UPDATE_ADDR;
                end
                
                WRITE_SYS: begin
                    // Capture REU Data
                    temp_reu <= mem_rdata;
                    
                    // Write to Sys
                    c64_rw_out <= 0; // Write
                    c64_addr_out <= r_c64_addr;
                    c64_data_out <= mem_rdata; 
                    
                    // Wait for end of PHI2 cycle (Write Complete)
                    if (phi2_fall) begin
                        state <= UPDATE_ADDR;
                    end
                end
                
                WRITE_REU_SWAP: begin
                    // Capture REU Data from READ_REU_INTERNAL
                    temp_reu <= mem_rdata;
                    
                    // Write Sys Data to REU
                    mem_req <= 1;
                    mem_we <= 1;
                    mem_addr <= r_reu_addr;
                    mem_wdata <= temp_sys;
                    
                    state <= WRITE_SYS_SWAP;
                end
                
                WRITE_SYS_SWAP: begin
                    // Write REU Data to Sys
                    c64_rw_out <= 0;
                    c64_addr_out <= r_c64_addr;
                    c64_data_out <= temp_reu;
                    
                    if (phi2_fall) begin
                        state <= UPDATE_ADDR;
                    end
                end
                
                VERIFY_COMPARE: begin
                    // Capture REU Data
                    temp_reu <= mem_rdata;
                    
                    if (temp_sys != mem_rdata) begin
                        // Fault!
                        status_update_en <= 1;
                        status_update_val <= 3'b001; // Fault=1
                        if (r_irq_mask[5]) status_update_val[2] <= 1; // IRQ Pending
                        
                        state <= FINISH;
                    end else begin
                        state <= UPDATE_ADDR;
                    end
                end
                
                UPDATE_ADDR: begin
                    update_regs <= 1;
                    next_c64_addr <= fixed_c64 ? r_c64_addr : r_c64_addr + 1;
                    next_reu_addr <= fixed_reu ? r_reu_addr : r_reu_addr + 1;
                    next_transfer_len <= r_transfer_len - 1;
                    
                    if (r_transfer_len == 1) begin
                        state <= FINISH;
                        status_update_en <= 1;
                        status_update_val <= 3'b010; // End of Block=1
                        if (r_irq_mask[6]) status_update_val[2] <= 1; // IRQ Pending
                    end else begin
                        // Loop back
                        if (transfer_type == 2'b01) state <= READ_REU;
                        else state <= READ_SYS;
                    end
                end
                
                FINISH: begin
                    c64_ba <= 1; // Release Bus
                    clear_execute_bit <= 1;
                    
                    if (r_command[5]) begin // Autoload
                        autoload_restore <= 1;
                    end
                    
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
