// Bridge RAM (Simple Dual Port or Single Port for now)
// Used for "Window" mapping into C64 address space.

module bridge_ram (
    input  wire        clk,
    input  wire [7:0]  addr,
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    input  wire        we,
    input  wire        en
);

    reg [7:0] mem [0:255];

    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                mem[addr] <= din;
            end
            dout <= mem[addr];
        end
    end

endmodule
