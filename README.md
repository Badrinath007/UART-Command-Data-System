# UART based Command and Data Communication System
Verilog implementation of a UART-based Command and Data Communication System. Features a multi-byte packet protocol ([Header][CMD][Data][Checksum]) and a verified control FSM for robust hardware-level data processing.

UART-Based Command and Data Communication System
- Project Overview
This project implements a "Production-Grade" UART communication system in Verilog. Beyond simple bit-shifting, this system includes a Control FSM that acts as a protocol parser, enabling secure and reliable Command and Data exchange between a PC (or another MCU) and the FPGA.

- Technical Architecture
The system is built with a modular approach to ensure scalability and ease of verification:

Top-Level (uart_top.v): Orchestrates the handshake between the receiver and the command processor.

Command Processor (FSM): A state machine that implements a multi-byte packet protocol: [Header: 0x55] [CMD] [DATA] [Checksum].

Receiver (rx.v): Features mid-bit sampling logic and a 2-stage synchronizer to prevent metastability.

Transmitter (tx.v): Drives the serial line with precise timing, ensuring a clean return to the IDLE state (logic 1) via a dedicated stop-bit drive.

- Verification & Functional Correctness
The design was verified using a self-checking Verilog testbench. The results confirmed 100% functional accuracy for the following scenarios:

Valid Packet Execution: Successfully parsed 0x55 -> 0x01 -> 0xA5 -> 0xA6. The system verified the checksum and updated the internal reg_file to 0xA5.

Robust Error Handling: Demonstrated that packets with incorrect checksums are automatically discarded, protecting the hardware from executing corrupted data.

- Waveform Analysis
As seen in the simulation, the tx_busy signal holds high throughout the transmission, and the state transitions perfectly align with the baud rate.

- Roadmap
Following the "Production-First" mindset, the next phases of development include:

Phase 2: Implementing 16x Oversampling in the RX module to improve noise immunity.

Phase 3: Integrating a Synchronous FIFO buffer to handle high-speed data bursts without packet loss.

- License
This project is licensed under the MIT License - see the LICENSE file for details.
