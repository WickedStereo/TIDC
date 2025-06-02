#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtidc_system_tb_simple.h"

// Global time for Verilator
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create an instance of our module
    Vtidc_system_tb_simple* top = new Vtidc_system_tb_simple;
    
    // Enable VCD tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open("tidc_system_tb.vcd");
    
    // Initialize signals
    top->clk = 0;
    top->rst_n = 0;
    
    // Reset for the first 20 cycles
    for (int i = 0; i < 20; i++) {
        top->clk = 0;
        top->eval();
        tfp->dump(main_time++);
        
        top->clk = 1;
        top->eval();
        tfp->dump(main_time++);
    }
    
    // Release reset
    top->rst_n = 1;
    
    // Simulate for a reasonable amount of time
    while (!Verilated::gotFinish() && main_time < 200000) {  // 100k clock cycles
        top->clk = 0;
        top->eval();
        tfp->dump(main_time++);
        
        top->clk = 1;
        top->eval();
        tfp->dump(main_time++);
    }
    
    // Final evaluation
    top->final();
    
    // Clean up
    tfp->close();
    delete top;
    delete tfp;
    
    if (Verilated::gotFinish()) {
        printf("Simulation completed successfully!\n");
        return 0;
    } else {
        printf("Simulation timed out!\n");
        return 1;
    }
} 