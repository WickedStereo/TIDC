// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: TIDC System Testbench (Verilator Compatible)
// Description: Testbench for direct TileLink adapter testing - compatible with Verilator
// =============================================================================

// Include shared parameter definitions
`include "tidc_params.v"

module tidc_system_tb (
    input wire clk  // Clock driven from C++ for Verilator compatibility
);

    // Reset
    reg rst_n;
    
    // L1 TileLink Adapter interfaces
    // L1 Adapter 0 interface
    reg                         l1_0_request_valid;
    reg  [WADDR-1:0]            l1_0_request_addr;
    reg  [2:0]                  l1_0_request_type;
    reg  [CACHE_LINE_BITS-1:0]  l1_0_request_data;
    reg  [2:0]                  l1_0_request_permissions;
    wire                        l1_0_request_ready;
    
    wire                        l1_0_data_valid;
    wire [CACHE_LINE_BITS-1:0]  l1_0_data;
    wire                        l1_0_data_error;
    
    wire                        l1_0_probe_req_valid;
    wire [WADDR-1:0]            l1_0_probe_req_addr;
    wire [2:0]                  l1_0_probe_req_permissions;
    
    reg                         l1_0_probe_ack_valid;
    reg  [WADDR-1:0]            l1_0_probe_ack_addr;
    reg  [2:0]                  l1_0_probe_ack_permissions;
    reg  [CACHE_LINE_BITS-1:0]  l1_0_probe_ack_dirty_data;
    
    // L1 Adapter 1 interface
    reg                         l1_1_request_valid;
    reg  [WADDR-1:0]            l1_1_request_addr;
    reg  [2:0]                  l1_1_request_type;
    reg  [CACHE_LINE_BITS-1:0]  l1_1_request_data;
    reg  [2:0]                  l1_1_request_permissions;
    wire                        l1_1_request_ready;
    
    wire                        l1_1_data_valid;
    wire [CACHE_LINE_BITS-1:0]  l1_1_data;
    wire                        l1_1_data_error;
    
    wire                        l1_1_probe_req_valid;
    wire [WADDR-1:0]            l1_1_probe_req_addr;
    wire [2:0]                  l1_1_probe_req_permissions;
    
    reg                         l1_1_probe_ack_valid;
    reg  [WADDR-1:0]            l1_1_probe_ack_addr;
    reg  [2:0]                  l1_1_probe_ack_permissions;
    reg  [CACHE_LINE_BITS-1:0]  l1_1_probe_ack_dirty_data;
    
    // L1 Adapter 2 interface
    reg                         l1_2_request_valid;
    reg  [WADDR-1:0]            l1_2_request_addr;
    reg  [2:0]                  l1_2_request_type;
    reg  [CACHE_LINE_BITS-1:0]  l1_2_request_data;
    reg  [2:0]                  l1_2_request_permissions;
    wire                        l1_2_request_ready;
    
    wire                        l1_2_data_valid;
    wire [CACHE_LINE_BITS-1:0]  l1_2_data;
    wire                        l1_2_data_error;
    
    wire                        l1_2_probe_req_valid;
    wire [WADDR-1:0]            l1_2_probe_req_addr;
    wire [2:0]                  l1_2_probe_req_permissions;
    
    reg                         l1_2_probe_ack_valid;
    reg  [WADDR-1:0]            l1_2_probe_ack_addr;
    reg  [2:0]                  l1_2_probe_ack_permissions;
    reg  [CACHE_LINE_BITS-1:0]  l1_2_probe_ack_dirty_data;
    
    // L1 Adapter 3 interface
    reg                         l1_3_request_valid;
    reg  [WADDR-1:0]            l1_3_request_addr;
    reg  [2:0]                  l1_3_request_type;
    reg  [CACHE_LINE_BITS-1:0]  l1_3_request_data;
    reg  [2:0]                  l1_3_request_permissions;
    wire                        l1_3_request_ready;
    
    wire                        l1_3_data_valid;
    wire [CACHE_LINE_BITS-1:0]  l1_3_data;
    wire                        l1_3_data_error;
    
    wire                        l1_3_probe_req_valid;
    wire [WADDR-1:0]            l1_3_probe_req_addr;
    wire [2:0]                  l1_3_probe_req_permissions;
    
    reg                         l1_3_probe_ack_valid;
    reg  [WADDR-1:0]            l1_3_probe_ack_addr;
    reg  [2:0]                  l1_3_probe_ack_permissions;
    reg  [CACHE_LINE_BITS-1:0]  l1_3_probe_ack_dirty_data;
    
    // L2 TileLink Adapter interface
    wire                        l2_cmd_valid;
    wire [2:0]                  l2_cmd_type;
    wire [WADDR-1:0]            l2_cmd_addr;
    wire [CACHE_LINE_BITS-1:0]  l2_cmd_data;
    wire [WSIZE-1:0]            l2_cmd_size;
    wire                        l2_cmd_dirty;
    
    reg                         l2_response_valid;
    reg  [CACHE_LINE_BITS-1:0]  l2_response_data;
    reg                         l2_response_error;
    
    // Test address space
    localparam ADDR_A = 32'h1000;
    localparam ADDR_B = 32'h2000;
    localparam ADDR_C = 32'h3000;
    
    // Test data patterns
    localparam [CACHE_LINE_BITS-1:0] DATA_PATTERN_1 = {CACHE_LINE_BITS{1'b1}};
    localparam [CACHE_LINE_BITS-1:0] DATA_PATTERN_2 = {{CACHE_LINE_BITS/2{1'b1}}, {CACHE_LINE_BITS/2{1'b0}}};
    localparam [CACHE_LINE_BITS-1:0] DATA_PATTERN_3 = {{CACHE_LINE_BITS/4{1'b1}}, {CACHE_LINE_BITS/4{1'b0}}, {CACHE_LINE_BITS/4{1'b1}}, {CACHE_LINE_BITS/4{1'b0}}};
    
    // Test state machine
    localparam TEST_RESET        = 4'd0;
    localparam TEST_L1_0_REQ_A   = 4'd1;
    localparam TEST_L1_0_WAIT_A  = 4'd2;
    localparam TEST_L1_1_REQ_A   = 4'd3;
    localparam TEST_L1_1_WAIT_A  = 4'd4;
    localparam TEST_L1_0_REQ_B   = 4'd5;
    localparam TEST_L1_0_WAIT_B  = 4'd6;
    localparam TEST_L1_2_REQ_C   = 4'd7;
    localparam TEST_L1_2_WAIT_C  = 4'd8;
    localparam TEST_DONE         = 4'd9;
    
    reg [3:0] test_state;
    reg [15:0] wait_counter;
    
    // Instantiate the DUT
    tidc_top dut (
        .clk(clk),
        .rst_n(rst_n),
        
        // L1 Adapter 0 interface
        .l1_0_request_valid(l1_0_request_valid),
        .l1_0_request_addr(l1_0_request_addr),
        .l1_0_request_type(l1_0_request_type),
        .l1_0_request_data(l1_0_request_data),
        .l1_0_request_permissions(l1_0_request_permissions),
        .l1_0_request_ready(l1_0_request_ready),
        
        .l1_0_data_valid(l1_0_data_valid),
        .l1_0_data(l1_0_data),
        .l1_0_data_error(l1_0_data_error),
        
        .l1_0_probe_req_valid(l1_0_probe_req_valid),
        .l1_0_probe_req_addr(l1_0_probe_req_addr),
        .l1_0_probe_req_permissions(l1_0_probe_req_permissions),
        
        .l1_0_probe_ack_valid(l1_0_probe_ack_valid),
        .l1_0_probe_ack_addr(l1_0_probe_ack_addr),
        .l1_0_probe_ack_permissions(l1_0_probe_ack_permissions),
        .l1_0_probe_ack_dirty_data(l1_0_probe_ack_dirty_data),
        
        // L1 Adapter 1 interface
        .l1_1_request_valid(l1_1_request_valid),
        .l1_1_request_addr(l1_1_request_addr),
        .l1_1_request_type(l1_1_request_type),
        .l1_1_request_data(l1_1_request_data),
        .l1_1_request_permissions(l1_1_request_permissions),
        .l1_1_request_ready(l1_1_request_ready),
        
        .l1_1_data_valid(l1_1_data_valid),
        .l1_1_data(l1_1_data),
        .l1_1_data_error(l1_1_data_error),
        
        .l1_1_probe_req_valid(l1_1_probe_req_valid),
        .l1_1_probe_req_addr(l1_1_probe_req_addr),
        .l1_1_probe_req_permissions(l1_1_probe_req_permissions),
        
        .l1_1_probe_ack_valid(l1_1_probe_ack_valid),
        .l1_1_probe_ack_addr(l1_1_probe_ack_addr),
        .l1_1_probe_ack_permissions(l1_1_probe_ack_permissions),
        .l1_1_probe_ack_dirty_data(l1_1_probe_ack_dirty_data),
        
        // L1 Adapter 2 interface
        .l1_2_request_valid(l1_2_request_valid),
        .l1_2_request_addr(l1_2_request_addr),
        .l1_2_request_type(l1_2_request_type),
        .l1_2_request_data(l1_2_request_data),
        .l1_2_request_permissions(l1_2_request_permissions),
        .l1_2_request_ready(l1_2_request_ready),
        
        .l1_2_data_valid(l1_2_data_valid),
        .l1_2_data(l1_2_data),
        .l1_2_data_error(l1_2_data_error),
        
        .l1_2_probe_req_valid(l1_2_probe_req_valid),
        .l1_2_probe_req_addr(l1_2_probe_req_addr),
        .l1_2_probe_req_permissions(l1_2_probe_req_permissions),
        
        .l1_2_probe_ack_valid(l1_2_probe_ack_valid),
        .l1_2_probe_ack_addr(l1_2_probe_ack_addr),
        .l1_2_probe_ack_permissions(l1_2_probe_ack_permissions),
        .l1_2_probe_ack_dirty_data(l1_2_probe_ack_dirty_data),
        
        // L1 Adapter 3 interface
        .l1_3_request_valid(l1_3_request_valid),
        .l1_3_request_addr(l1_3_request_addr),
        .l1_3_request_type(l1_3_request_type),
        .l1_3_request_data(l1_3_request_data),
        .l1_3_request_permissions(l1_3_request_permissions),
        .l1_3_request_ready(l1_3_request_ready),
        
        .l1_3_data_valid(l1_3_data_valid),
        .l1_3_data(l1_3_data),
        .l1_3_data_error(l1_3_data_error),
        
        .l1_3_probe_req_valid(l1_3_probe_req_valid),
        .l1_3_probe_req_addr(l1_3_probe_req_addr),
        .l1_3_probe_req_permissions(l1_3_probe_req_permissions),
        
        .l1_3_probe_ack_valid(l1_3_probe_ack_valid),
        .l1_3_probe_ack_addr(l1_3_probe_ack_addr),
        .l1_3_probe_ack_permissions(l1_3_probe_ack_permissions),
        .l1_3_probe_ack_dirty_data(l1_3_probe_ack_dirty_data),
        
        // L2 TileLink Adapter interface
        .l2_cmd_valid(l2_cmd_valid),
        .l2_cmd_type(l2_cmd_type),
        .l2_cmd_addr(l2_cmd_addr),
        .l2_cmd_data(l2_cmd_data),
        .l2_cmd_size(l2_cmd_size),
        .l2_cmd_dirty(l2_cmd_dirty),
        
        .l2_response_valid(l2_response_valid),
        .l2_response_data(l2_response_data),
        .l2_response_error(l2_response_error)
    );
    
    // Simple L2 response logic (for testing)
    always @(posedge clk) begin
        if (!rst_n) begin
            l2_response_valid <= 1'b0;
            l2_response_data <= {CACHE_LINE_BITS{1'b0}};
            l2_response_error <= 1'b0;
        end else begin
            // Simple L2 simulation: always respond with test data after one cycle
            if (l2_cmd_valid) begin
                l2_response_valid <= 1'b1;
                // Return different data patterns based on address
                case (l2_cmd_addr)
                    ADDR_A: l2_response_data <= DATA_PATTERN_1;
                    ADDR_B: l2_response_data <= DATA_PATTERN_2;
                    ADDR_C: l2_response_data <= DATA_PATTERN_3;
                    default: l2_response_data <= {CACHE_LINE_BITS{1'b0}};
                endcase
                l2_response_error <= 1'b0;
            end else begin
                l2_response_valid <= 1'b0;
            end
        end
    end
    
    // Simulation timeout counter (instead of using #delay which doesn't work with external clock)
    reg [31:0] timeout_counter;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            timeout_counter <= 32'd0;
        end else begin
            timeout_counter <= timeout_counter + 1;
            if (timeout_counter >= 32'd500000) begin  // 500k cycles timeout (10ms at 50MHz)
                $display("ERROR: Simulation timeout reached!");
                $finish;
            end
        end
    end
    
    // Test state machine
    always @(posedge clk) begin
        if (!rst_n) begin
            test_state <= TEST_RESET;
            wait_counter <= 16'd0;
            
            // Initialize all L1 inputs
            l1_0_request_valid <= 1'b0;
            l1_0_request_addr <= 32'h0;
            l1_0_request_type <= 3'b000;
            l1_0_request_data <= {CACHE_LINE_BITS{1'b0}};
            l1_0_request_permissions <= 3'b000;
            l1_0_probe_ack_valid <= 1'b0;
            l1_0_probe_ack_addr <= 32'h0;
            l1_0_probe_ack_permissions <= 3'b000;
            l1_0_probe_ack_dirty_data <= {CACHE_LINE_BITS{1'b0}};
            
            l1_1_request_valid <= 1'b0;
            l1_1_request_addr <= 32'h0;
            l1_1_request_type <= 3'b000;
            l1_1_request_data <= {CACHE_LINE_BITS{1'b0}};
            l1_1_request_permissions <= 3'b000;
            l1_1_probe_ack_valid <= 1'b0;
            l1_1_probe_ack_addr <= 32'h0;
            l1_1_probe_ack_permissions <= 3'b000;
            l1_1_probe_ack_dirty_data <= {CACHE_LINE_BITS{1'b0}};
            
            l1_2_request_valid <= 1'b0;
            l1_2_request_addr <= 32'h0;
            l1_2_request_type <= 3'b000;
            l1_2_request_data <= {CACHE_LINE_BITS{1'b0}};
            l1_2_request_permissions <= 3'b000;
            l1_2_probe_ack_valid <= 1'b0;
            l1_2_probe_ack_addr <= 32'h0;
            l1_2_probe_ack_permissions <= 3'b000;
            l1_2_probe_ack_dirty_data <= {CACHE_LINE_BITS{1'b0}};
            
            l1_3_request_valid <= 1'b0;
            l1_3_request_addr <= 32'h0;
            l1_3_request_type <= 3'b000;
            l1_3_request_data <= {CACHE_LINE_BITS{1'b0}};
            l1_3_request_permissions <= 3'b000;
            l1_3_probe_ack_valid <= 1'b0;
            l1_3_probe_ack_addr <= 32'h0;
            l1_3_probe_ack_permissions <= 3'b000;
            l1_3_probe_ack_dirty_data <= {CACHE_LINE_BITS{1'b0}};
        end
        else begin
            // Default - clear valid signals
            l1_0_request_valid <= 1'b0;
            l1_1_request_valid <= 1'b0;
            l1_2_request_valid <= 1'b0;
            l1_3_request_valid <= 1'b0;
            
            case (test_state)
                TEST_RESET: begin
                    wait_counter <= wait_counter + 1;
                    if (wait_counter >= 16'd20) begin
                        $display("=== TileLink Direct Adapter Testing ===");
                        $display("TEST 1: L1_0 Read Miss (Acquire NtoB) to address %h", ADDR_A);
                        test_state <= TEST_L1_0_REQ_A;
                        wait_counter <= 16'd0;
                    end
                    else if (wait_counter == 16'd10) begin
                        $display("Reset phase: wait_counter = %d, rst_n = %b", wait_counter, rst_n);
                    end
                end
                
                TEST_L1_0_REQ_A: begin
                    l1_0_request_valid <= 1'b1;
                    l1_0_request_addr <= ADDR_A;
                    l1_0_request_type <= 3'b000; // Read miss
                    l1_0_request_permissions <= PARAM_NtoB;
                    l1_0_request_data <= {CACHE_LINE_BITS{1'b0}};
                    
                    $display("L1_0 requesting: valid=%b, ready=%b, addr=%h", l1_0_request_valid, l1_0_request_ready, l1_0_request_addr);
                    
                    if (l1_0_request_ready) begin
                        $display("L1_0 request accepted, moving to wait state");
                        test_state <= TEST_L1_0_WAIT_A;
                        wait_counter <= 16'd0;
                    end
                end
                
                TEST_L1_0_WAIT_A: begin
                    if (l1_0_data_valid) begin
                        $display("L1_0 received data: %h", l1_0_data);
                        $display("TEST 2: L1_1 Read Miss (Acquire NtoB) to same address %h", ADDR_A);
                        test_state <= TEST_L1_1_REQ_A;
                        wait_counter <= 16'd0;
                    end else begin
                        wait_counter <= wait_counter + 1;
                        if (wait_counter >= 16'd1000) begin
                            $display("ERROR: Timeout waiting for L1_0 data response");
                            $finish;
                        end
                    end
                end
                
                TEST_L1_1_REQ_A: begin
                    l1_1_request_valid <= 1'b1;
                    l1_1_request_addr <= ADDR_A;
                    l1_1_request_type <= 3'b000; // Read miss
                    l1_1_request_permissions <= PARAM_NtoB;
                    l1_1_request_data <= {CACHE_LINE_BITS{1'b0}};
                    
                    if (l1_1_request_ready) begin
                        test_state <= TEST_L1_1_WAIT_A;
                        wait_counter <= 16'd0;
                    end
                end
                
                TEST_L1_1_WAIT_A: begin
                    if (l1_1_data_valid) begin
                        $display("L1_1 received data: %h", l1_1_data);
                        $display("TEST 3: L1_0 Write Miss (Acquire NtoT) to address %h", ADDR_B);
                        test_state <= TEST_L1_0_REQ_B;
                        wait_counter <= 16'd0;
                    end else begin
                        wait_counter <= wait_counter + 1;
                        if (wait_counter >= 16'd1000) begin
                            $display("ERROR: Timeout waiting for L1_1 data response");
                            $finish;
                        end
                    end
                end
                
                TEST_L1_0_REQ_B: begin
                    l1_0_request_valid <= 1'b1;
                    l1_0_request_addr <= ADDR_B;
                    l1_0_request_type <= 3'b001; // Write miss
                    l1_0_request_permissions <= PARAM_NtoT;
                    l1_0_request_data <= {CACHE_LINE_BITS{1'b0}};
                    
                    if (l1_0_request_ready) begin
                        test_state <= TEST_L1_0_WAIT_B;
                        wait_counter <= 16'd0;
                    end
                end
                
                TEST_L1_0_WAIT_B: begin
                    if (l1_0_data_valid) begin
                        $display("L1_0 received exclusive data: %h", l1_0_data);
                        $display("TEST 4: L1_2 Read Miss to address %h", ADDR_C);
                        test_state <= TEST_L1_2_REQ_C;
                        wait_counter <= 16'd0;
                    end else begin
                        wait_counter <= wait_counter + 1;
                        if (wait_counter >= 16'd1000) begin
                            $display("ERROR: Timeout waiting for L1_0 data response");
                            $finish;
                        end
                    end
                end
                
                TEST_L1_2_REQ_C: begin
                    l1_2_request_valid <= 1'b1;
                    l1_2_request_addr <= ADDR_C;
                    l1_2_request_type <= 3'b000; // Read miss
                    l1_2_request_permissions <= PARAM_NtoB;
                    l1_2_request_data <= {CACHE_LINE_BITS{1'b0}};
                    
                    if (l1_2_request_ready) begin
                        test_state <= TEST_L1_2_WAIT_C;
                        wait_counter <= 16'd0;
                    end
                end
                
                TEST_L1_2_WAIT_C: begin
                    if (l1_2_data_valid) begin
                        $display("L1_2 received data: %h", l1_2_data);
                        test_state <= TEST_DONE;
                        wait_counter <= 16'd0;
                    end else begin
                        wait_counter <= wait_counter + 1;
                        if (wait_counter >= 16'd1000) begin
                            $display("ERROR: Timeout waiting for L1_2 data response");
                            $finish;
                        end
                    end
                end
                
                TEST_DONE: begin
                    wait_counter <= wait_counter + 1;
                    if (wait_counter >= 16'd100) begin
                        $display("=== TileLink Direct Testing Complete ===");
                        $display("All basic TileLink transactions tested successfully");
                        $finish;
                    end
                end
            endcase
        end
    end
    
    // Reset sequence - counter based for Verilator compatibility
    reg [7:0] reset_counter;
    
    always @(posedge clk) begin
        if (reset_counter < 8'd50) begin  // Hold reset for 50 cycles
            rst_n <= 1'b0;
            reset_counter <= reset_counter + 1;
        end else begin
            rst_n <= 1'b1;
        end
    end
    
    initial begin
        reset_counter = 8'd0;
        rst_n = 1'b0;
    end
    
    // Optional: Dump waveforms for viewing in a waveform viewer
    initial begin
        $dumpfile("tidc_system_tb.vcd");
        $dumpvars(0, tidc_system_tb);
    end

endmodule 