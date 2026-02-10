module tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tx_start, // Added: Trigger for transmission
	input wire [7:0] tx_data,
    output reg  tx,
    output reg  tx_busy,
    output reg tx_done
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD;

    localparam [1:0]
        IDLE 	=	2'b00,
        START	=	2'b01,
        DATA	=	2'b10,
        STOP	=	2'b11;

    reg [1:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    /*always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    	<= 	IDLE;
            baud_cnt 	<= 	16'd0;
            tx       	<= 	1'b1;   // Idle line is HIGH
            bit_cnt		<=	3'b0;
            tx_busy		<=	1'b0;
            shift_reg	<=	8'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx       <= 1'b1;
                    baud_cnt <= 16'd0;
                    bit_cnt	<=	3'd0;
                    tx_busy	<=	1'b0;
                    // Transition to START when tx_start is pulsed
                    if (tx_start) begin
                    	//shift_reg	<=	tx_data;
                        state <= START;
                        tx_busy	<=	1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0;  // Start bit
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 16'd0;
                        state    <= DATA; 
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                    //state	<=	IDLE;
                end

                DATA:begin
                	//tx 	<=	shift_reg[0];
                	shift_reg<=tx_data;
                	if(baud_cnt	==	BAUD_DIV-1) begin
                		baud_cnt	<=	16'b0;
                		tx 	<=	shift_reg[0];
                		shift_reg	<=	{1'b0,shift_reg[7:1]};
                		if(bit_cnt	==	3'd7) begin
                			bit_cnt	<=	3'b0;
                			state	<=	IDLE;
                			tx_busy<=1'b0;
                		end
                		else begin
                			bit_cnt	<=	bit_cnt+1'b1;
                		end
                	end
                	
                end
                	
                
            endcase
        end
    end*/
    always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        state     <= IDLE;
                        baud_cnt  <= 16'd0;
                        bit_cnt   <= 3'd0;
                        shift_reg <= 8'h00;
                        tx        <= 1'b1;   
                        tx_busy   <= 1'b0;
                        tx_done <=1'b0;
                    end else begin
                        case (state)
                            IDLE: begin
                                tx      <= 1'b1;
                                tx_busy <= 1'b0;
                                baud_cnt <= 16'd0;
                                bit_cnt  <= 3'd0;
                                if (tx_start) begin
                                    tx      <= 1'b0;    // Immediate Start bit
                                    tx_busy <= 1'b1;
                                    tx_done<=1'b0;
                                    state   <= START;
                                end
                                else begin
                                	tx_done<=1'b0;
                                end
                            end
            
                            START: begin
                                tx <= 1'b0; 
                                if (baud_cnt == BAUD_DIV - 1) begin
                                    baud_cnt  <= 16'd0;    // Reset baud_cnt for the first data bit
                                    shift_reg <= tx_data;  // A5 is stored exactly as we hit state 10
                                    tx        <= tx_data[0]; // FIX: Pre-drive the first bit of A5
                                    
                                    state     <= DATA;
                                    
                                end else begin
                                    baud_cnt <= baud_cnt + 1'b1;
                                end
                            end
            
                            DATA: begin
                                
                                if (baud_cnt == BAUD_DIV - 1) begin
                                    baud_cnt <= 16'd0; // Reset counter for the next bit or state
                                    
                                    
                                    
                                    if (bit_cnt == 3'd7) begin
                                        
                                        bit_cnt <= 3'd0;
                                        state   <= STOP; // Transition only after bit 7 has finished its time
                                        tx<=1'b1;
                                        //shift_reg<=8'b0;
                                    end else begin
                                        bit_cnt <= bit_cnt + 1'b1;
                                        // Shift occurs only once per baud period
                                        shift_reg <= {1'b0, shift_reg[7:1]};
                                        tx <= shift_reg[1]; // Continuous drive of the current LSB 
                                    end
                                end else begin
                                    baud_cnt <= baud_cnt + 1'b1; // Keep counting within the current bit
                                    tx <= shift_reg[0]; // Hold the current bit level
                                end
                                //tx <= shift_reg[0]; // Hold the current bit level
                            end
                                    
                            STOP: begin
                                tx <= 1'b1; 
                                if (baud_cnt == BAUD_DIV - 1) begin
                                    baud_cnt <= 16'd0;
                                    state    <= IDLE;
                                    tx_done  <= 1'b1; 
                                    tx_busy  <= 1'b0;
                                end else begin
                                    baud_cnt <= baud_cnt + 1'b1;
                                    tx_done  <= 1'b0; // Hold done low until the very end
                                end
                            end 
                            
                          
                        endcase
                   end
                end

endmodule
