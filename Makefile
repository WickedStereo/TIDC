## Makefile for TIDC System Simulation with Verilator

# Project settings
PROJECT = tidc_system
TB_MODULE = tidc_system_tb
DUT_MODULE = tidc_top

# Source files
RTL_DIR = rtl
TB_DIR = tb
RTL_SOURCES = $(wildcard $(RTL_DIR)/*.v)
TB_SOURCES = $(TB_DIR)/tidc_system_tb_verilator.v $(TB_DIR)/main.cpp

# Build directory
BUILD_DIR = obj_dir

# Verilator settings
VERILATOR = verilator
VERILATOR_FLAGS = -Wall -Wno-UNUSED -Wno-UNOPTFLAT -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-STMTDLY -Wno-INFINITELOOP -Wno-SYNCASYNCNET -Wno-CMPCONST -Wno-DECLFILENAME --cc --exe --trace
VERILATOR_INCLUDES = -I$(RTL_DIR)

# C++ settings
CXX_FLAGS = -O3 -std=c++14

# Targets
.PHONY: all clean sim waves

all: sim

# Build the simulation executable
$(BUILD_DIR)/V$(TB_MODULE): $(RTL_SOURCES) $(TB_SOURCES)
	@echo "Building with Verilator..."
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INCLUDES) \
		--top-module $(TB_MODULE) \
		$(TB_SOURCES) $(RTL_SOURCES) \
		--build -o V$(TB_MODULE)

# Run the simulation
sim: $(BUILD_DIR)/V$(TB_MODULE)
	@echo "Running simulation..."
	cd $(BUILD_DIR) && ./V$(TB_MODULE)

# View waveforms (requires GTKWave)
waves: sim
	@echo "Opening waveforms in GTKWave..."
	@if [ -f tidc_system_tb.vcd ]; then \
		gtkwave tidc_system_tb.vcd & \
	else \
		echo "VCD file not found. Make sure simulation ran successfully."; \
	fi

# Clean build files
clean:
	@echo "Cleaning build files..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.out

# Quick lint check
lint: $(RTL_SOURCES)
	@echo "Running lint check..."
	$(VERILATOR) --lint-only $(VERILATOR_INCLUDES) $(RTL_SOURCES)

# Help
help:
	@echo "Available targets:"
	@echo "  all    - Build and run simulation (default)"
	@echo "  sim    - Build and run simulation"
	@echo "  waves  - Run simulation and open waveforms"
	@echo "  lint   - Run lint check on RTL"
	@echo "  clean  - Clean build files"
	@echo "  help   - Show this help" 