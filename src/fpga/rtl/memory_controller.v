// SuperCPU Memory Controller
// Handles access to SuperRAM (Up to 16MB).
// Currently implements a small internal Block RAM for testing.
// TODO: Replace internal BRAM with DDR3/SDRAM Controller interface for full 16MB support.

module memory_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface
    input  wire [23:0] addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    input  wire        we,      // 1 = Write, 0 = Read
    input  wire        en       // 1 = Access Enabled
);

    // -------------------------------------------------------------------------
    // Internal Block RAM (64KB Placeholder)
    // -------------------------------------------------------------------------
    // We map this 64KB to Bank 01 ($010000 - $01FFFF) for testing.
    // Or we can just alias the lower 16 bits of any address.
    
    reg [7:0] mem [0:65535]; // 64KB RAM
    
    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                mem[addr[15:0]] <= din;
                dout <= din; // Write-through or undefined
            end else begin
                dout <= mem[addr[15:0]];
            end
        end
    end

endmodule
