// UART Emulation Module (ACIA 6551 Compatible-ish)
// Maps a virtual UART to the C64/C128 bus.
// The "TX" data is written to a FIFO readable by Linux.
// The "RX" data is read from a FIFO writable by Linux.

module uart_emulation (
    input  wire        clk,
    input  wire        rst_n,
    
    // CPU Interface
    input  wire [3:0]  addr,    // Register Select (0-3)
    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    input  wire        we,      // 1 = Write
    input  wire        en,      // 1 = Chip Select
    
    // Linux Interface (FIFO)
    output reg  [7:0]  tx_fifo_data,
    output reg         tx_fifo_valid,
    input  wire        tx_fifo_full,
    
    input  wire [7:0]  rx_fifo_data,
    input  wire        rx_fifo_valid,
    output reg         rx_fifo_read,
    
    // Interrupts
    output reg         irq_n
);

    // -------------------------------------------------------------------------
    // Registers (ACIA 6551)
    // -------------------------------------------------------------------------
    // 0: Data Register (R/W)
    // 1: Status Register (R)
    // 2: Command Register (R/W)
    // 3: Control Register (R/W)
    
    reg [7:0] status_reg;
    reg [7:0] command_reg;
    reg [7:0] control_reg;
    
    // Status Bits
    // Bit 7: IRQ (1 = Interrupt)
    // Bit 4: Receiver Full (1 = Char available)
    // Bit 1: Transmitter Empty (1 = Ready for char)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg  <= 8'h02; // TX Empty
            command_reg <= 8'h00;
            control_reg <= 8'h00;
            tx_fifo_valid <= 0;
            rx_fifo_read <= 0;
            irq_n <= 1'b1;
        end else begin
            // Default Pulse Clears
            tx_fifo_valid <= 0;
            rx_fifo_read <= 0;
            
            // Update Status
            status_reg[4] <= rx_fifo_valid; // RX Full if data in FIFO
            status_reg[1] <= !tx_fifo_full; // TX Empty if FIFO not full
            
            if (en) begin
                if (we) begin
                    case (addr[1:0])
                        2'h0: begin // Data Register (Write = TX)
                            tx_fifo_data <= din;
                            tx_fifo_valid <= 1'b1;
                        end
                        2'h1: begin // Status Register (Reset)
                            // Software Reset
                        end
                        2'h2: command_reg <= din;
                        2'h3: control_reg <= din;
                    endcase
                end else begin
                    // Read Operation
                    if (addr[1:0] == 2'h0) begin // Data Register (Read = RX)
                        rx_fifo_read <= 1'b1; // Pop from FIFO
                    end
                end
            end
        end
    end
    
    always @(*) begin
        dout = 8'hFF;
        if (en) begin
            case (addr[1:0])
                2'h0: dout = rx_fifo_data;
                2'h1: dout = status_reg;
                2'h2: dout = command_reg;
                2'h3: dout = control_reg;
            endcase
        end
    end

endmodule
