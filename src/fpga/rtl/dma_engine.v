// DMA Engine
// Allows High-Speed Data Transfer between Linux (HPS) and C64/SuperRAM.
// Acts as a Bus Master on the C64 Bus.

module dma_engine (
    input  wire        clk_sys,
    input  wire        rst_n,
    
    // Control Interface (from Linux/HPS)
    input  wire        dma_start,
    input  wire [31:0] src_addr,     // Source Address (System Memory)
    input  wire [23:0] dst_addr,     // Destination Address (C64/SuperRAM)
    input  wire [15:0] count,        // Number of Bytes
    input  wire        direction,    // 0: Sys->C64, 1: C64->Sys
    output reg         dma_busy,
    output reg         dma_done,
    
    // C64 Bus Interface (Master Mode)
    input  wire        c64_phi2,     // Sync to PHI2
    output reg         c64_ba,       // Bus Available (Request Bus)
    input  wire        c64_dma_ack,  // AEC/BA acknowledgement
    output reg [23:0]  c64_addr_out,
    output reg [7:0]   c64_data_out,
    input  wire [7:0]  c64_data_in,
    output reg         c64_rw_out
);

    // State Machine
    localparam IDLE = 0;
    localparam REQ_BUS = 1;
    localparam TRANSFER = 2;
    localparam RELEASE = 3;
    
    reg [1:0] state;
    reg [15:0] bytes_transferred;
    
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dma_busy <= 0;
            dma_done <= 0;
            c64_ba <= 1; // High = Bus Free
        end else begin
            case (state)
                IDLE: begin
                    dma_done <= 0;
                    if (dma_start) begin
                        state <= REQ_BUS;
                        dma_busy <= 1;
                        bytes_transferred <= 0;
                    end
                end
                
                REQ_BUS: begin
                    c64_ba <= 0; // Pull Low to Request Bus
                    // Wait for PHI2 High and AEC (handled by external logic usually)
                    // For now, assume immediate grant for simulation
                    if (c64_dma_ack) begin 
                        state <= TRANSFER;
                    end
                end
                
                TRANSFER: begin
                    // Perform Transfer on PHI2 High
                    if (c64_phi2) begin
                        if (direction == 0) begin // Sys -> C64
                            c64_rw_out <= 0; // Write
                            c64_addr_out <= dst_addr + bytes_transferred;
                            c64_data_out <= 8'hAA; // Placeholder for data from FIFO
                        end else begin // C64 -> Sys
                            c64_rw_out <= 1; // Read
                            c64_addr_out <= src_addr[23:0] + bytes_transferred;
                            // Capture c64_data_in
                        end
                        
                        bytes_transferred <= bytes_transferred + 1;
                        if (bytes_transferred == count - 1) begin
                            state <= RELEASE;
                        end
                    end
                end
                
                RELEASE: begin
                    c64_ba <= 1; // Release Bus
                    dma_busy <= 0;
                    dma_done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
