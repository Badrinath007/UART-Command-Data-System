module rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg [7:0]  rx_data,
    output reg        rx_done,
    output reg framing_err
);

    localparam integer baud_div  = CLK_FREQ / BAUD;
    localparam integer half_baud = baud_div / 2;

    // State encoding (plain Verilog)
    localparam [2:0]
        IDLE  = 3'b000,
        START = 3'b001,
        DATA  = 3'b010,
        STOP  = 3'b011,
        DONE  = 3'b100;

    reg [2:0]  state;
    reg [15:0] baud_cnt;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            baud_cnt  <= 16'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
            rx_data   <= 8'd0;
            rx_done   <= 1'b0;
            framing_err<=1'b0;
        end else begin
           

            case (state)

                IDLE: begin
                	rx_done <= 1'b0;
                	framing_err	<=1'b0;
                	baud_cnt<=16'd0;

                    if (rx == 1'b0) begin
                        state <= START;
                    end
                end

                /*START: begin
                    if(baud_cnt==half_baud) begin
                    	if(rx!=1'b0) begin
                    		state<=IDLE;
                    		baud_cnt<=16'd0;
                    	end
                    end
                    if (baud_cnt == baud_div-1) begin
                       // baud_cnt <= half_baud;
                        baud_cnt<=16'b0;
                       // bit_cnt  <= 3'b0;
                        state    <= DATA;
                    end
                    else begin
                    	baud_cnt<=baud_cnt+1;
                    end
                end*/

                START: begin
                	if(baud_cnt==(baud_div>>1)) begin
                		baud_cnt<=0;
                		bit_cnt<=0;
                		state<=DATA;
                	end
                	else begin
                		baud_cnt<=baud_cnt+1;
                	end
                end

               	DATA: begin
                    //baud_cnt <= baud_cnt + 1;

                    // sample mid-bit
                   /* if (baud_cnt == half_baud) begin
                      
                    end*/

                    // move to next bit
                    if (baud_cnt == baud_div - 1) begin
                        baud_cnt <= 16'd0;

                        shift_reg <= {rx,shift_reg[7:1]};
                        
                        if(bit_cnt == 3'd7) begin
                        	bit_cnt<=3'd0;
                        	baud_cnt<=16'b0;
                        	state <= STOP;
                        end
                        else begin
                        	bit_cnt<=bit_cnt+1;
                        end
                    end 
                    else begin
                    	baud_cnt <= baud_cnt + 1;
                   
                    end
                end
               /*	DATA: begin
               	
                    if (baud_cnt == baud_div - 1) begin
                        baud_cnt <= 16'd0;
                
                        // sample exactly once per bit (midpoint already aligned)
                        shift_reg <= {rx,shift_reg[7:1]};
                
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                            state   <= STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1;
                    end
                end*/

                STOP: begin
                    //baud_cnt <= baud_cnt + 1;
                    if (baud_cnt == baud_div - 1) begin
                    	baud_cnt<=16'b0;
                    	if(rx==1'b1) begin
                    		rx_data  <= shift_reg;
                        	rx_done  <= 1'b1;
                        end
                        else begin
                        	framing_err	<=1'b1;
                        	rx_done		<=1'b0;
                        	
                        end
                        state<= IDLE;
                    end 
                    else begin
                    	baud_cnt<=baud_cnt+1;
                    end
                end

                DONE: begin
                	
                    rx_done <= 1'b1;
                   	state   <= IDLE;
                end


            endcase
        end
    end

endmodule
