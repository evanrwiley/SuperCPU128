// SuperCPU User Interface (LEDs & Buttons)
// Provides visual feedback and physical control for the system.

module super_control (
    input  wire        clk,
    input  wire        rst_n,
    
    // Inputs from Hardware
    input  wire        key_turbo_n,  // Physical Turbo Button (Active Low)
    input  wire        key_reset_n,  // Physical Reset Button (Active Low)
    
    // Inputs from System Logic
    input  wire        safe_mode,    // 1 = Safe Mode Active
    input  wire        cpu_activity, // 1 = CPU Fetching
    input  wire        bridge_active,// 1 = AI Bridge Access
    input  wire        turbo_enabled,// Current Turbo State
    
    // Outputs to System Logic
    output reg         turbo_toggle, // Pulse to toggle Turbo
    output reg         sys_reset_req,// Pulse to request Reset
    
    // Outputs to Hardware (LEDs)
    output reg  [3:0]  leds          // [3]=AI, [2]=CPU, [1]=Safe, [0]=Turbo
);

    // -------------------------------------------------------------------------
    // Debounce Logic
    // -------------------------------------------------------------------------
    reg [19:0] db_turbo_cnt;
    reg [19:0] db_reset_cnt;
    reg        turbo_btn_state;
    reg        reset_btn_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            db_turbo_cnt <= 0;
            db_reset_cnt <= 0;
            turbo_btn_state <= 1;
            reset_btn_state <= 1;
            turbo_toggle <= 0;
            sys_reset_req <= 0;
        end else begin
            // Turbo Button Debounce
            if (key_turbo_n != turbo_btn_state) begin
                db_turbo_cnt <= db_turbo_cnt + 1;
                if (db_turbo_cnt == 20'hFFFFF) begin
                    turbo_btn_state <= key_turbo_n;
                    if (key_turbo_n == 0) turbo_toggle <= 1; // Press detected
                end
            end else begin
                db_turbo_cnt <= 0;
                turbo_toggle <= 0;
            end
            
            // Reset Button Debounce
            if (key_reset_n != reset_btn_state) begin
                db_reset_cnt <= db_reset_cnt + 1;
                if (db_reset_cnt == 20'hFFFFF) begin
                    reset_btn_state <= key_reset_n;
                    if (key_reset_n == 0) sys_reset_req <= 1; // Press detected
                end
            end else begin
                db_reset_cnt <= 0;
                sys_reset_req <= 0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // LED Logic
    // -------------------------------------------------------------------------
    reg [23:0] blink_cnt;
    reg [23:0] pulse_cnt;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blink_cnt <= 0;
            pulse_cnt <= 0;
            leds <= 0;
        end else begin
            blink_cnt <= blink_cnt + 1;
            
            // LED 0: Turbo Status (Solid ON = Turbo, OFF = 1MHz)
            leds[0] <= turbo_enabled;
            
            // LED 1: Safe Mode (Fast Blink = Danger/Safe Mode)
            leds[1] <= safe_mode ? blink_cnt[22] : 1'b0;
            
            // LED 2: CPU Heartbeat (Pulse on activity)
            if (cpu_activity) pulse_cnt <= 24'hFFFFFF; // Reset stretcher
            else if (pulse_cnt > 0) pulse_cnt <= pulse_cnt - 1;
            leds[2] <= (pulse_cnt > 24'hF00000); // Show short flash
            
            // LED 3: AI Bridge Activity (Solid when active)
            leds[3] <= bridge_active;
        end
    end

endmodule
