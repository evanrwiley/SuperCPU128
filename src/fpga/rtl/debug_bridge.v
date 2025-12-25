// Debug Bridge / Hardware Monitor
// Allows the ARM Co-Processor (Linux) to inspect and control the SuperCPU.
// Features:
// 1. Memory Peek/Poke (Read/Write any address)
// 2. CPU Control (Halt, Step, Run)
// 3. Register Inspection (via Shadow Registers)

module debug_bridge (
    input  wire        clk,
    input  wire        rst_n,
    
    // Interface to ARM/HPS (Memory Mapped)
    input  wire        cmd_valid,      // 1 = Command Ready
    input  wire [7:0]  cmd_type,       // 0=Read, 1=Write, 2=Halt, 3=Resume
    input  wire [23:0] cmd_addr,       // Target Address
    input  wire [7:0]  cmd_wdata,      // Write Data
    output reg  [7:0]  cmd_rdata,      // Read Data
    output reg         cmd_done,       // 1 = Command Complete
    
    // Interface to System Bus (Master)
    output reg         dbg_req,        // Request Bus Access
    input  wire        dbg_ack,        // Bus Granted
    output reg  [23:0] dbg_addr,
    output reg  [7:0]  dbg_wdata,
    input  wire [7:0]  dbg_rdata,
    output reg         dbg_we,         // 1 = Write
    
    // CPU Control
    output reg         cpu_halt_req,   // Request CPU Halt (RDY Low)
    input  wire        cpu_halted      // CPU is currently halted
);

    // State Machine
    localparam S_IDLE    = 0;
    localparam S_REQ_BUS = 1;
    localparam S_ACCESS  = 2;
    localparam S_DONE    = 3;
    
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            cmd_done <= 0;
            dbg_req <= 0;
            cpu_halt_req <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    cmd_done <= 0;
                    if (cmd_valid) begin
                        case (cmd_type)
                            8'h00: begin // Read Memory
                                dbg_addr <= cmd_addr;
                                dbg_we <= 0;
                                state <= S_REQ_BUS;
                            end
                            8'h01: begin // Write Memory
                                dbg_addr <= cmd_addr;
                                dbg_wdata <= cmd_wdata;
                                dbg_we <= 1;
                                state <= S_REQ_BUS;
                            end
                            8'h02: begin // Halt CPU
                                cpu_halt_req <= 1;
                                cmd_done <= 1; // Immediate ack
                            end
                            8'h03: begin // Resume CPU
                                cpu_halt_req <= 0;
                                cmd_done <= 1; // Immediate ack
                            end
                        endcase
                    end
                end
                
                S_REQ_BUS: begin
                    dbg_req <= 1;
                    if (dbg_ack) begin
                        state <= S_ACCESS;
                    end
                end
                
                S_ACCESS: begin
                    // Wait one cycle for memory to respond
                    // (Assuming synchronous memory for now)
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    if (!dbg_we) cmd_rdata <= dbg_rdata;
                    dbg_req <= 0;
                    cmd_done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
