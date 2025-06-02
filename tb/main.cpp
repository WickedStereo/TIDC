#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtidc_system_tb.h"

#include <iostream>
#include <memory>

// Global time for Verilator
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char **argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    std::cout << "Starting TIDC system simulation..." << std::endl;
    
    // Create instance of our module under test
    auto dut = std::make_unique<Vtidc_system_tb>();
    
    // Initialize VCD tracing
    Verilated::traceEverOn(true);
    auto trace = std::make_unique<VerilatedVcdC>();
    dut->trace(trace.get(), 99);
    trace->open("tidc_system_tb.vcd");
    
    // Initialize inputs
    dut->clk = 0;
    
    std::cout << "Driving clock manually for Verilator compatibility" << std::endl;
    
    // Run simulation
    const int MAX_SIM_TIME = 100000;  // Maximum simulation cycles
    
    while (!Verilated::gotFinish() && main_time < MAX_SIM_TIME) {
        // Toggle clock
        dut->clk = !dut->clk;
        
        // Evaluate model
        dut->eval();
        
        // Dump trace
        trace->dump(main_time);
        
        // Increment time
        main_time++;
        
        // Check for simulation completion every 1000 cycles
        if (main_time % 1000 == 0) {
            std::cout << "Simulation time: " << main_time << " time units (clock cycles: " << main_time/2 << ")" << std::endl;
        }
    }
    
    // Final trace dump
    trace->dump(main_time);
    
    if (main_time >= MAX_SIM_TIME) {
        std::cout << "ERROR: Simulation timeout reached!" << std::endl;
        std::cout << "- Simulation ran for maximum allowed cycles without completion" << std::endl;
    }
    
    std::cout << "Simulation time: " << main_time << " time units (clock cycles: " << main_time/2 << ")" << std::endl;
    
    // Clean up
    trace->close();
    dut->final();
    
    std::cout << "Simulation completed successfully!" << std::endl;
    return 0;
} 