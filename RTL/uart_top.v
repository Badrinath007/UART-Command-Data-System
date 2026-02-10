module uart_top #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire uart_rx,
    output wire uart_tx
);

    // 1. Double-Flop Synchronizer for RX (Prevents Metastability)
    reg sync_1, sync_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {sync_1, sync_2} <= 2'b11;
        else         {sync_1, sync_2} <= {uart_rx, sync_1};
    end

    // 2. Internal Interconnects
    wire [7:0] rx_data_out;
    wire       rx_done_tick;
    reg  [7:0] tx_data_in;
    reg        tx_start_tick;
    wire       tx_busy_status;
    wire       tx_done_status;

    // --- Updated Control FSM for Command/Data System ---
    localparam ST_IDLE   = 3'd0,
               ST_CMD    = 3'd1,
               ST_DATA   = 3'd2,
               ST_CHKSUM = 3'd3,
               ST_EXEC   = 3'd4;
    
    reg [2:0]  p_state;
    reg [7:0]  hold_cmd, hold_data;
    reg [7:0]  reg_file; // A dummy internal register to store data
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_state <= ST_IDLE;
            reg_file <= 8'h00;
        end else begin
            case (p_state)
                ST_IDLE: begin
                    if (rx_done_tick && rx_data_out == 8'h55) 
                        p_state <= ST_CMD;
                end
    
                ST_CMD: begin
                    if (rx_done_tick) begin
                        hold_cmd <= rx_data_out;
                        p_state  <= ST_DATA;
                    end
                end
    
                ST_DATA: begin
                    if (rx_done_tick) begin
                        hold_data <= rx_data_out;
                        p_state   <= ST_CHKSUM;
                    end
                end
    
                ST_CHKSUM: begin
                    if (rx_done_tick) begin
                        // Verify: Checksum = CMD + DATA
                        if (rx_data_out == (hold_cmd + hold_data))
                            p_state <= ST_EXEC;
                        else
                            p_state <= ST_IDLE; // Error: Drop packet
                    end
                end
    
                ST_EXEC: begin
                    if (hold_cmd == 8'h01) begin
                        reg_file <= hold_data; // "Write" Command
                    end
                    // After execution, we can echo the result back
                    tx_data_in    <= reg_file; 
                    tx_start_tick <= 1'b1;
                    p_state       <= ST_IDLE;
                end
            endcase
        end
    end

    // 3. Receiver Instance
    rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) rx_inst (
        .clk(clk), .rst_n(rst_n), .rx(sync_2),
        .rx_data(rx_data_out), .rx_done(rx_done_tick), .framing_err()
    );

    // 4. Transmitter Instance
    tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) tx_inst (
        .clk(clk), .rst_n(rst_n), .tx_data(tx_data_in),
        .tx_start(tx_start_tick), .tx(uart_tx), .tx_busy(tx_busy_status), .tx_done(tx_done_status)
    );

    // 5. Control FSM (Echo Logic)
    localparam STATE_IDLE = 2'b00, STATE_SEND = 2'b01;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            tx_start_tick <= 1'b0;
            tx_data_in <= 8'h00;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_start_tick <= 1'b0;
                    if (rx_done_tick) begin
                        tx_data_in <= rx_data_out; // Capture the byte
                        state      <= STATE_SEND;
                    end
                end
                STATE_SEND: begin
                    tx_start_tick <= 1'b1; // Trigger TX
                    state         <= STATE_IDLE; // Return and wait for completion/next byte
                end
            endcase
        end
    end
endmodule
