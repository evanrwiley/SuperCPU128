module id_logic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cs,          // Chip Select ($DFA0-$DFFF)
    input  wire [15:0] addr,        // CPU Address
    output reg  [7:0]  dout
);

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------
    localparam [7:0] ID_CHAR = "C"; // 'C' for Copilot/Custom
    localparam [15:0] VERSION = 16'h0100; // v1.0
    
    // Copyright String: "SuperCPU FPGA v1.0" + CR + NULL
    // Length: 18 bytes + 2 = 20 bytes
    // 01234567890123456789
    // SuperCPU FPGA v1.0
    
    // -------------------------------------------------------------------------
    // Toggling Logic for $DFFF
    // -------------------------------------------------------------------------
    reg toggle_bit;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_bit <= 0;
        end else if (cs && addr == 16'hDFFF) begin
            toggle_bit <= ~toggle_bit;
        end
    end

    // -------------------------------------------------------------------------
    // Read Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        dout = 8'hFF; // Default open bus
        
        if (cs) begin
            case (addr)
                16'hDFFF: dout = toggle_bit ? 8'hAA : 8'h55;
                16'hDFFE: dout = ID_CHAR;
                16'hDFFD: dout = VERSION[15:8];
                16'hDFFC: dout = VERSION[7:0];
                
                // String at $DFA0
                16'hDFA0: dout = "S";
                16'hDFA1: dout = "u";
                16'hDFA2: dout = "p";
                16'hDFA3: dout = "e";
                16'hDFA4: dout = "r";
                16'hDFA5: dout = "C";
                16'hDFA6: dout = "P";
                16'hDFA7: dout = "U";
                16'hDFA8: dout = " ";
                16'hDFA9: dout = "F";
                16'hDFAA: dout = "P";
                16'hDFAB: dout = "G";
                16'hDFAC: dout = "A";
                16'hDFAD: dout = " ";
                16'hDFAE: dout = "v";
                16'hDFAF: dout = "1";
                16'hDFB0: dout = ".";
                16'hDFB1: dout = "0";
                16'hDFB2: dout = 8'h0D; // CR
                16'hDFB3: dout = 8'h00; // NULL
                
                default: dout = 8'hFF;
            endcase
        end
    end

endmodule
