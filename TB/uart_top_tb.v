/*module uart_top_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD     = 115200;
    parameter BIT_TIME = 8680; // (1/115200) * 1e9 ns

    reg clk;
    reg rst_n;
    reg uart_rx;
    wire uart_tx;

    // Instantiate the Top Level
    uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz
    end

    // Task to send a byte to the RX input
    task send_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 0; // START bit
            #BIT_TIME;
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i]; // DATA bits LSB first
                #BIT_TIME;
            end
            uart_rx = 1; // STOP bit
            #BIT_TIME;
        end
    endtask

    // Stimulus
    initial begin
    	$dumpfile("wave.vcd");
    	$dumpvars(0,uart_top_tb);
        // Initialize
        rst_n = 0;
        uart_rx = 1;
        #100;
        rst_n = 1;
        #1000;

        $display("--- Starting Echo Test ---");
        
        // Send A5
        $display("Sending 8'hA5...");
        send_byte(8'hA5);

        // Wait for the Echo to finish on uart_tx
        // The top level will wait for rx_done, then trigger tx_start
        #(11 * BIT_TIME); 

        $display("--- Test Finished ---");
        $finish;
    end

endmodule*/

`timescale 1ns / 1ps

module uart_top_tb;

    // Parameters
    parameter CLK_FREQ = 50_000_000;
    parameter BAUD     = 115200;
    parameter BIT_TIME = 8680; // (1/115200) * 1e9 ns

    // Signals
    reg clk;
    reg rst_n;
    reg uart_rx;
    wire uart_tx;

    // Instantiate Top Level Module
    uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // --- 1. Clock Generation ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz
    end

    // --- 2. Helper Task to Send Serial Data ---
    task send_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 0; // START bit
            #(BIT_TIME);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i]; // DATA bits LSB first
                #(BIT_TIME);
            end
            uart_rx = 1; // STOP bit
            #(BIT_TIME);
            #(BIT_TIME); // Gap between bytes
        end
    endtask

    // --- 3. Functional Verification Scenarios ---
    initial begin
        // Reset
        rst_n = 0;
        uart_rx = 1;
        #200;
        rst_n = 1;
        #2000;

        $display("\n--- Starting UART Command & Data Verification ---");

        // TEST 1: Valid Write Command
        // Packet: [Header: 55] [CMD: 01 (Write)] [DATA: A5] [CHKSUM: 01+A5 = A6]
        $display("TEST 1: Sending Valid WRITE Packet (55 01 A5 A6)...");
        send_byte(8'h55); 
        send_byte(8'h01); 
        send_byte(8'hA5); 
        send_byte(8'hA6); 
        
        // Give the FSM enough time to process the 4 bytes
        #(20 * BIT_TIME); 

        // Manual check of the internal register
        if (dut.reg_file === 8'hA5) 
            $display("SUCCESS: Command Processed. reg_file = %h", dut.reg_file);
        else 
            $display("FAILURE: reg_file expected A5, got %h", dut.reg_file);

        #10000;

        // TEST 2: Invalid Checksum (System should ignore)
        // Packet: [Header: 55] [CMD: 01] [DATA: BB] [CHKSUM: 00 (WRONG)]
        $display("\nTEST 2: Sending Packet with INVALID Checksum...");
        send_byte(8'h55);
        send_byte(8'h01);
        send_byte(8'hBB); // New data that should be ignored
        send_byte(8'h00); // Invalid Checksum
        
        #(20 * BIT_TIME);
        
        // reg_file should still be A5 from Test 1
        if (dut.reg_file === 8'hA5)
            $display("SUCCESS: Invalid checksum ignored. reg_file stays %h", dut.reg_file);
        else
            $display("FAILURE: reg_file was wrongly updated to %h", dut.reg_file);

        $display("\n--- Verification Finished ---");
        $finish;
    end

    // VCD Dump for waveform analysis
    initial begin
        $dumpfile("uart_system.vcd");
        $dumpvars(0, uart_top_tb);
    end

endmodule
