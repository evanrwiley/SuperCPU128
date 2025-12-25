// Bus Sampler / Logic Analyzer
// Captures C64 Bus signals into a circular buffer for debugging.
// Triggerable by address match or external signal.

module bus_sampler (
    input  wire        clk_sys,
    input  wire        rst_n,
    
    // Signals to Sample
    input  wire [15:0] c64_addr,
    input  wire [7:0]  c64_data,
    input  wire        c64_rw,
    input  wire        c64_phi2,
    input  wire        c64_irq_n,
    input  wire        c64_nmi_n,
    
    // Control
    input  wire        trigger_enable,
    input  wire [15:0] trigger_addr,
    output reg         triggered,
    
    // Readout Interface (to Linux)
    input  wire [9:0]  read_addr,
    output wire [31:0] read_data
);

    // Sample Buffer (1024 samples deep)
    // Format: [31:24] Flags, [23:16] Data, [15:0] Addr
    reg [31:0] buffer [0:1023];
    reg [9:0]  head;
    
    always @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            head <= 0;
            triggered <= 0;
        end else begin
            // Sample on PHI2 falling edge (end of cycle) or rising edge?
            // Let's sample on every system clock for high res, or PHI2 edges.
            // Sampling on PHI2 falling edge gives the final state of the cycle.
            
            // Simple continuous sampling for now
            buffer[head] <= {5'b0, c64_nmi_n, c64_irq_n, c64_rw, c64_data, c64_addr};
            head <= head + 1;
            
            if (trigger_enable && c64_addr == trigger_addr) begin
                triggered <= 1;
            end
        end
    end
    
    assign read_data = buffer[read_addr];

endmodule
