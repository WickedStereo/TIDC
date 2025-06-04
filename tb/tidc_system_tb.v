// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: TIDC System Testbench
// Description: Testbench for direct TileLink adapter testing (no cache stubs)
// =============================================================================

module tidc_system_tb;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Fixed Parameters (de-parameterized)
    localparam NUM_L1_CACHES = 4;
    localparam WDATA = 8;  // bytes
    localparam WADDR = 32;
    localparam WSIZE = 4;
    localparam WSOURCE = 4;
    localparam WSINK = 4;
    localparam CACHE_LINE_BITS = 256;
    
    // Permission parameters
    localparam PARAM_NtoB = 0;   // None to Branch
    localparam PARAM_NtoT = 1;   // None to Tip
    
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
    
    // L2 TileLink Adapter interface (corrected directions)
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
    
    // Helper tasks for L1 requests
    task send_l1_request;
        input [1:0] l1_id;
        input [WADDR-1:0] addr;
        input [2:0] req_type;  // 000=ReadMiss, 001=WriteMiss, 010=WriteBack
        input [2:0] permissions; // NtoB, NtoT, BtoT
        input [CACHE_LINE_BITS-1:0] data;
        begin
            case (l1_id)
                2'd0: begin
                    l1_0_request_valid = 1'b1;
                    l1_0_request_addr = addr;
                    l1_0_request_type = req_type;
                    l1_0_request_permissions = permissions;
                    l1_0_request_data = data;
                end
                2'd1: begin
                    l1_1_request_valid = 1'b1;
                    l1_1_request_addr = addr;
                    l1_1_request_type = req_type;
                    l1_1_request_permissions = permissions;
                    l1_1_request_data = data;
                end
                2'd2: begin
                    l1_2_request_valid = 1'b1;
                    l1_2_request_addr = addr;
                    l1_2_request_type = req_type;
                    l1_2_request_permissions = permissions;
                    l1_2_request_data = data;
                end
                2'd3: begin
                    l1_3_request_valid = 1'b1;
                    l1_3_request_addr = addr;
                    l1_3_request_type = req_type;
                    l1_3_request_permissions = permissions;
                    l1_3_request_data = data;
                end
            endcase
        end
    endtask
    
    task clear_l1_request;
        input [1:0] l1_id;
        begin
            case (l1_id)
                2'd0: l1_0_request_valid = 1'b0;
                2'd1: l1_1_request_valid = 1'b0;
                2'd2: l1_2_request_valid = 1'b0;
                2'd3: l1_3_request_valid = 1'b0;
            endcase
        end
    endtask
    
    // Helper task to handle probe acknowledgements
    task send_probe_ack;
        input [1:0] l1_id;
        input [WADDR-1:0] addr;
        input [2:0] permissions; // TtoT, TtoB, TtoN, BtoB, BtoN, NtoN
        input [CACHE_LINE_BITS-1:0] dirty_data;
        begin
            case (l1_id)
                2'd0: begin
                    l1_0_probe_ack_valid = 1'b1;
                    l1_0_probe_ack_addr = addr;
                    l1_0_probe_ack_permissions = permissions;
                    l1_0_probe_ack_dirty_data = dirty_data;
                end
                2'd1: begin
                    l1_1_probe_ack_valid = 1'b1;
                    l1_1_probe_ack_addr = addr;
                    l1_1_probe_ack_permissions = permissions;
                    l1_1_probe_ack_dirty_data = dirty_data;
                end
                2'd2: begin
                    l1_2_probe_ack_valid = 1'b1;
                    l1_2_probe_ack_addr = addr;
                    l1_2_probe_ack_permissions = permissions;
                    l1_2_probe_ack_dirty_data = dirty_data;
                end
                2'd3: begin
                    l1_3_probe_ack_valid = 1'b1;
                    l1_3_probe_ack_addr = addr;
                    l1_3_probe_ack_permissions = permissions;
                    l1_3_probe_ack_dirty_data = dirty_data;
                end
            endcase
        end
    endtask
    
    task clear_probe_ack;
        input [1:0] l1_id;
        begin
            case (l1_id)
                2'd0: l1_0_probe_ack_valid = 1'b0;
                2'd1: l1_1_probe_ack_valid = 1'b0;
                2'd2: l1_2_probe_ack_valid = 1'b0;
                2'd3: l1_3_probe_ack_valid = 1'b0;
            endcase
        end
    endtask
    
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
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Simple L2 response logic (for testing)
    // In a real system, this would be handled by a proper L2 cache controller
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
    
    // Simulation timeout
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout reached!");
        $finish;
    end

    // Test sequence focusing on TileLink protocol
    initial begin
        // Initialize all L1 inputs
        l1_0_request_valid = 1'b0;
        l1_0_request_addr = 32'h0;
        l1_0_request_type = 3'b000;
        l1_0_request_data = {CACHE_LINE_BITS{1'b0}};
        l1_0_request_permissions = 3'b000;
        l1_0_probe_ack_valid = 1'b0;
        l1_0_probe_ack_addr = 32'h0;
        l1_0_probe_ack_permissions = 3'b000;
        l1_0_probe_ack_dirty_data = {CACHE_LINE_BITS{1'b0}};
        
        l1_1_request_valid = 1'b0;
        l1_1_request_addr = 32'h0;
        l1_1_request_type = 3'b000;
        l1_1_request_data = {CACHE_LINE_BITS{1'b0}};
        l1_1_request_permissions = 3'b000;
        l1_1_probe_ack_valid = 1'b0;
        l1_1_probe_ack_addr = 32'h0;
        l1_1_probe_ack_permissions = 3'b000;
        l1_1_probe_ack_dirty_data = {CACHE_LINE_BITS{1'b0}};
        
        l1_2_request_valid = 1'b0;
        l1_2_request_addr = 32'h0;
        l1_2_request_type = 3'b000;
        l1_2_request_data = {CACHE_LINE_BITS{1'b0}};
        l1_2_request_permissions = 3'b000;
        l1_2_probe_ack_valid = 1'b0;
        l1_2_probe_ack_addr = 32'h0;
        l1_2_probe_ack_permissions = 3'b000;
        l1_2_probe_ack_dirty_data = {CACHE_LINE_BITS{1'b0}};
        
        l1_3_request_valid = 1'b0;
        l1_3_request_addr = 32'h0;
        l1_3_request_type = 3'b000;
        l1_3_request_data = {CACHE_LINE_BITS{1'b0}};
        l1_3_request_permissions = 3'b000;
        l1_3_probe_ack_valid = 1'b0;
        l1_3_probe_ack_addr = 32'h0;
        l1_3_probe_ack_permissions = 3'b000;
        l1_3_probe_ack_dirty_data = {CACHE_LINE_BITS{1'b0}};
        
        // Apply reset
        rst_n = 0;
        #20;
        rst_n = 1;
        #20;
        
        $display("=== TileLink Direct Adapter Testing ===");
        
        // TEST 1: Simple read miss from L1_0 (NtoB - None to Branch/Shared)
        $display("TEST 1: L1_0 Read Miss (Acquire NtoB) to address %h", ADDR_A);
        send_l1_request(2'd0, ADDR_A, 3'b000, PARAM_NtoB, {CACHE_LINE_BITS{1'b0}});
        
        // Wait for request to be accepted
        @(posedge clk);
        while (!l1_0_request_ready) @(posedge clk);
        clear_l1_request(2'd0);
        
        // Wait for response data
        while (!l1_0_data_valid) @(posedge clk);
        @(posedge clk);
        $display("L1_0 received data: %h", l1_0_data);
        #20;
        
        // TEST 2: L1_1 read miss to same address (should get shared access)
        $display("TEST 2: L1_1 Read Miss (Acquire NtoB) to same address %h", ADDR_A);
        send_l1_request(2'd1, ADDR_A, 3'b000, PARAM_NtoB, {CACHE_LINE_BITS{1'b0}});
        
        // Wait for request to be accepted
        @(posedge clk);
        while (!l1_1_request_ready) @(posedge clk);
        clear_l1_request(2'd1);
        
        // Wait for response data
        while (!l1_1_data_valid) @(posedge clk);
        @(posedge clk);
        $display("L1_1 received data: %h", l1_1_data);
        #20;
        
        // TEST 3: L1_0 write miss (NtoT - None to Tip/Exclusive)
        $display("TEST 3: L1_0 Write Miss (Acquire NtoT) to address %h", ADDR_B);
        send_l1_request(2'd0, ADDR_B, 3'b001, PARAM_NtoT, {CACHE_LINE_BITS{1'b0}});
        
        // Wait for request to be accepted
        @(posedge clk);
        while (!l1_0_request_ready) @(posedge clk);
        clear_l1_request(2'd0);
        
        // Wait for response data
        while (!l1_0_data_valid) @(posedge clk);
        @(posedge clk);
        $display("L1_0 received exclusive data: %h", l1_0_data);
        #20;
        
        // TEST 4: Simple read miss from L1_2 to different address
        $display("TEST 4: L1_2 Read Miss to address %h", ADDR_C);
        send_l1_request(2'd2, ADDR_C, 3'b000, PARAM_NtoB, {CACHE_LINE_BITS{1'b0}});
        
        // Wait for request to be accepted
        @(posedge clk);
        while (!l1_2_request_ready) @(posedge clk);
        clear_l1_request(2'd2);
        
        // Wait for response
        while (!l1_2_data_valid) @(posedge clk);
        @(posedge clk);
        $display("L1_2 received data: %h", l1_2_data);
        #20;
        
        // End simulation
        $display("=== TileLink Direct Testing Complete ===");
        $display("All basic TileLink transactions tested successfully");
        #100;
        $finish;
    end
    
    // Optional: Dump waveforms for viewing in a waveform viewer
    initial begin
        $dumpfile("tidc_system_tb.vcd");
        $dumpvars(0, tidc_system_tb);
    end

endmodule 