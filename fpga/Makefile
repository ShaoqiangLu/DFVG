################################################################################
# Makefile for DFVG FPGA Draft Engine (Vivado Flow)
#
# Supports:
#   make synthesize   - run RTL synthesis
#   make implement    - placement & routing
#   make bitstream    - generate .bit file
#   make clean        - remove Vivado project outputs
#
# This Makefile assumes:
#   - You are using Xilinx Vivado (2020.2+)
#   - You have 'vivado' in your PATH
#   - TCL scripts exist in ./scripts/*.tcl
################################################################################

# Project settings
TOP_MODULE    := draft_top
PROJECT_NAME  := dfvg_fpga
BUILD_DIR     := build
TCL_DIR       := scripts

# TCL scripts (you can rename according to your project)
SYNTH_TCL     := $(TCL_DIR)/synthesize.tcl
IMPL_TCL      := $(TCL_DIR)/implement.tcl
BIT_TCL       := $(TCL_DIR)/generate_bitstream.tcl

# Vivado binary
VIVADO        := vivado -mode batch -nojournal -log vivado.log


################################################################################
# Commands
################################################################################

all: synthesize implement bitstream
	@echo "[OK] FPGA full flow completed!"

synthesize:
	@echo "[INFO] Running synthesis..."
	$(VIVADO) -source $(SYNTH_TCL) -tclargs $(TOP_MODULE) $(PROJECT_NAME) $(BUILD_DIR)
	@echo "[OK] Synthesis completed."

implement:
	@echo "[INFO] Running implementation..."
	$(VIVADO) -source $(IMPL_TCL) -tclargs $(TOP_MODULE) $(PROJECT_NAME) $(BUILD_DIR)
	@echo "[OK] Implementation completed."

bitstream:
	@echo "[INFO] Generating bitstream..."
	$(VIVADO) -source $(BIT_TCL) -tclargs $(TOP_MODULE) $(PROJECT_NAME) $(BUILD_DIR)
	@echo "[OK] Bitstream generated: $(BUILD_DIR)/$(PROJECT_NAME).bit"


clean:
	@echo "[CLEAN] Removing build directory..."
	rm -rf $(BUILD_DIR)
	rm -f vivado.log vivado.jou
	@echo "[CLEAN] FPGA build artifacts removed."

.PHONY: all synthesize implement bitstream clean

