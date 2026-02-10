#!/bin/bash

# ==============================================================================
# Project: UART Command and Data Communication System
# Script:  Professional Simulation Automation
# Purpose: Compiles RTL/TB, runs simulation, and checks for successful completion.
# ==============================================================================

# --- 1. Configuration ---
PROJECT_NAME="UART_CMD_SYS"
RTL_DIR="./rtl"
TB_DIR="./tb"
BUILD_DIR="./sim/build"
OUT_FILE="${BUILD_DIR}/sim_out"
VCD_FILE="uart_system.vcd"

# Colors for professional logging
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "-------------------------------------------------------"
echo "  Starting $PROJECT_NAME Automation Script  "
echo "-------------------------------------------------------"

# --- 2. Clean/Setup Build Environment ---
if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning old build files..."
    rm -rf "$BUILD_DIR"
fi
mkdir -p "$BUILD_DIR"

# --- 3. Compilation ---
echo -n "Compiling Verilog files... "
# Using -g2012 for SystemVerilog compatibility (future-proofing)
iverilog -g2012 -o "$OUT_FILE" \
    "$TB_DIR/uart_top_tb.v" \
    "$RTL_DIR/uart_top.v" \
    "$RTL_DIR/rx.v" \
    "$RTL_DIR/tx.v"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}COMPILATION SUCCESS${NC}"
else
    echo -e "${RED}COMPILATION FAILED${NC}"
    exit 1
fi

# --- 4. Simulation Execution ---
echo "Running simulation..."
vvp "$OUT_FILE" | grep -E "SUCCESS|FAILURE|Verification"

# --- 5. Final Result Check ---
if [ -f "$VCD_FILE" ]; then
    echo -e "${GREEN}Simulation Complete. Waveform generated: $VCD_FILE${NC}"
else
    echo -e "${RED}Simulation Error: VCD file not found.${NC}"
    exit 1
fi

echo "-------------------------------------------------------"
echo "  Finished Successfully  "
echo "-------------------------------------------------------"
