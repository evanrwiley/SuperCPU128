// Frequency Monitor
// Measures the frequency of the PHI2 clock using the 50MHz reference.
// Used to detect C64 (1MHz) vs C128 (2MHz) modes.

module freq_monitor (
    input  wire        clk_ref,     // 50MHz Reference
    input  wire        rst_n,
    input  wire        clk_test,    // Signal to measure (PHI2)
    output reg  [31:0] freq_hz      // Measured Frequency in Hz
);

    // -------------------------------------------------------------------------
    // Measurement Logic
    // -------------------------------------------------------------------------
    // Count clk_test edges over a fixed period of clk_ref.
    // 50MHz = 50,000,000 cycles per second.
    
    reg [31:0] ref_count;
    reg [31:0] test_count;
    reg [31:0] test_count_latched;
    
    // Synchronize clk_test to clk_ref domain to detect edges
    reg [2:0] test_sync;
    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) test_sync <= 3'b000;
        else test_sync <= {test_sync[1:0], clk_test};
    end
    
    wire test_rising = (test_sync[2:1] == 2'b01);
    
    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            ref_count <= 0;
            test_count <= 0;
            freq_hz <= 0;
        end else begin
            if (ref_count == 50000000 - 1) begin
                // One second has passed
                ref_count <= 0;
                freq_hz <= test_count; // Update output
                test_count <= 0;
            end else begin
                ref_count <= ref_count + 1;
                if (test_rising) begin
                    test_count <= test_count + 1;
                end
            end
        end
    end

endmodule
