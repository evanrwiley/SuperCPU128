// System Health Monitor & Smart Recovery
// Monitors CPU and Bus activity to detect hangs/crashes.
// Implements "Smart Recovery" by forcing resets and engaging Safe Mode.

module system_health (
    input  wire        clk,
    input  wire        por_n,        // Power-On Reset (Hard Reset)
    input  wire        cpu_valid,    // CPU VDA or VPA (Instruction/Data Fetch)
    input  wire        cpu_rdy,      // CPU Ready Line (1=Running, 0=Wait)
    
    output reg         sys_reset_req,// Request to reset the system (Soft Reset)
    output reg         safe_mode,    // 1 = Force Safe Mode (Disable Turbo/REU)
    output reg         bus_release   // 1 = Force release of RDY (Break deadlock)
);

    // Configuration
    parameter CLK_FREQ = 20000000; // 20 MHz
    parameter HANG_TIMEOUT = CLK_FREQ / 2; // 0.5 Seconds (Bus Hang)
    parameter CRASH_TIMEOUT = CLK_FREQ * 2; // 2.0 Seconds (CPU Crash/Loop)
    parameter CRASH_LIMIT = 3; // Crashes before Safe Mode

    reg [31:0] activity_timer;
    reg [31:0] wait_timer;
    reg [2:0]  crash_counter;
    reg [31:0] cooldown_timer; // To decrement crash counter if stable

    always @(posedge clk or negedge por_n) begin
        if (!por_n) begin
            activity_timer <= 0;
            wait_timer     <= 0;
            crash_counter  <= 0;
            cooldown_timer <= 0;
            sys_reset_req  <= 0;
            safe_mode      <= 0;
            bus_release    <= 0;
        end else begin
            // 1. Bus Hang Monitor (RDY Stuck Low)
            if (cpu_rdy) begin
                wait_timer <= 0;
                bus_release <= 0;
            end else begin
                if (wait_timer < HANG_TIMEOUT) begin
                    wait_timer <= wait_timer + 1;
                end else begin
                    // Timeout! Force release of bus to break deadlock
                    bus_release <= 1; 
                end
            end

            // 2. CPU Crash Monitor (No Valid Activity)
            if (cpu_valid) begin
                activity_timer <= 0;
            end else begin
                if (activity_timer < CRASH_TIMEOUT) begin
                    activity_timer <= activity_timer + 1;
                end
            end

            // 3. Recovery Logic
            if (activity_timer == CRASH_TIMEOUT) begin
                // Detected a crash
                sys_reset_req <= 1; // Pulse Reset
                if (crash_counter < CRASH_LIMIT) begin
                    crash_counter <= crash_counter + 1;
                end
            end else begin
                sys_reset_req <= 0;
            end

            // 4. Safe Mode Trigger
            if (crash_counter >= CRASH_LIMIT) begin
                safe_mode <= 1;
            end

            // 5. Cooldown (Healing)
            // If system runs stably for 10 seconds, reduce crash counter
            if (cpu_valid && !safe_mode) begin
                if (cooldown_timer < (CLK_FREQ * 10)) begin
                    cooldown_timer <= cooldown_timer + 1;
                end else begin
                    cooldown_timer <= 0;
                    if (crash_counter > 0) crash_counter <= crash_counter - 1;
                end
            end
        end
    end

endmodule
