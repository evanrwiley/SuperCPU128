// System PLL Wrapper
// Generates 20MHz CPU Clock from 50MHz Input
// Note: In the real Quartus project, replace this with an ALTPLL IP Core.

module pll_sys (
    input  wire refclk,   // 50MHz Input
    input  wire rst,      // Reset
    output wire outclk_0, // 20MHz Output
    output wire locked    // PLL Locked Signal
);

    // -------------------------------------------------------------------------
    // Simulation Model
    // -------------------------------------------------------------------------
    // For simulation/linting purposes only. 
    // This will NOT synthesize to a real PLL on hardware without the IP Core.
    
    `ifdef SYNTHESIS
        // In synthesis, we expect the user to generate the IP named 'pll_sys_ip'
        // or we can instantiate a generic cyclonev_pll if we want to be fancy,
        // but usually it's better to leave a black box or error out if missing.
        
        // For this "Clean Room" recreation, we will assume the user generates
        // a PLL named 'pll_sys_ip' with the following ports.
        pll_sys_ip u_pll (
            .refclk   (refclk),
            .rst      (rst),
            .outclk_0 (outclk_0),
            .locked   (locked)
        );
    `else
        // Simple clock divider/simulation for testing
        // 50MHz -> 20MHz is factor of 2.5. Hard to do with simple flip-flops.
        // We'll just approximate or toggle.
        reg clk_20 = 0;
        initial forever #25 clk_20 = ~clk_20; // 20MHz = 50ns period -> 25ns toggle
        
        assign outclk_0 = clk_20;
        assign locked   = 1'b1;
    `endif

endmodule
