// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: L2 TileLink Adapter
// Description: Central TileLink Slave Agent and coherence manager for the TIDC system
// =============================================================================

// Include shared parameter definitions
`include "tidc_params.v"

module l2_tilelink_adapter (
    input  wire                         clk,
    input  wire                         rst_n,
    
    // TileLink Channel A (requests from L1s)
    input  wire [3:0]                   a_valid,
    input  wire [11:0]                  a_opcode,  // Packed array of opcodes from each master (4*3)
    input  wire [11:0]                  a_param,   // Packed array of params from each master (4*3)
    input  wire [15:0]                  a_size,    // Packed array of sizes from each master (4*4)
    input  wire [15:0]                  a_source,  // Packed array of source IDs from each master (4*4)
    input  wire [127:0]                 a_address, // Packed array of addresses from each master (4*32)
    input  wire [255:0]                 a_data,    // Packed array of data from each master (4*64)
    input  wire [31:0]                  a_mask,    // Packed array of masks from each master (4*8)
    output wire [3:0]                   a_ready,
    
    // TileLink Channel B (probes to L1s)
    output reg  [3:0]                   b_valid,
    output reg  [11:0]                  b_opcode,  // Packed array of opcodes to each master (4*3)
    output reg  [11:0]                  b_param,   // Packed array of params to each master (4*3)
    output reg  [15:0]                  b_size,    // Packed array of sizes to each master (4*4)
    output reg  [15:0]                  b_source,  // Packed array of source IDs to each master (4*4)
    output reg  [127:0]                 b_address, // Packed array of addresses to each master (4*32)
    output reg  [255:0]                 b_data,    // Packed array of data to each master (4*64)
    output reg  [31:0]                  b_mask,    // Packed array of masks to each master (4*8)
    input  wire [3:0]                   b_ready,
    
    // TileLink Channel C (responses from L1s)
    input  wire [3:0]                   c_valid,
    input  wire [11:0]                  c_opcode,  // Packed array of opcodes from each master (4*3)
    input  wire [11:0]                  c_param,   // Packed array of params from each master (4*3)
    input  wire [15:0]                  c_size,    // Packed array of sizes from each master (4*4)
    input  wire [15:0]                  c_source,  // Packed array of source IDs from each master (4*4)
    input  wire [127:0]                 c_address, // Packed array of addresses from each master (4*32)
    input  wire [255:0]                 c_data,    // Packed array of data from each master (4*64)
    input  wire [3:0]                   c_error,   // Packed array of error flags from each master
    output wire [3:0]                   c_ready,
    
    // TileLink Channel D (responses to L1s)
    output reg  [3:0]                   d_valid,
    output reg  [11:0]                  d_opcode,  // Packed array of opcodes to each master (4*3)
    output reg  [11:0]                  d_param,   // Packed array of params to each master (4*3)
    output reg  [15:0]                  d_size,    // Packed array of sizes to each master (4*4)
    output reg  [15:0]                  d_source,  // Packed array of source IDs to each master (4*4)
    output reg  [15:0]                  d_sink,    // Packed array of sink IDs to each master (4*4)
    output reg  [255:0]                 d_data,    // Packed array of data to each master (4*64)
    output reg  [3:0]                   d_error,   // Packed array of error flags to each master
    input  wire [3:0]                   d_ready,
    
    // TileLink Channel E (acknowledgements from L1s)
    input  wire [3:0]                   e_valid,
    input  wire [15:0]                  e_sink,    // Packed array of sink IDs from each master (4*4)
    output wire [3:0]                   e_ready,
    
    // L2 Cache Controller Interface
    output reg                          l2_cmd_valid,
    output reg  [2:0]                   l2_cmd_type,  // 000=Read, 001=Write, 010=Invalidate, 011=WriteBack
    output reg  [31:0]                  l2_cmd_addr,
    output reg  [255:0]                 l2_cmd_data,  // Data for write/write-back commands
    output reg  [3:0]                   l2_cmd_size,
    output reg                          l2_cmd_dirty,  // Indicates if data is dirty (for write-back)
    
    input  wire                         l2_response_valid,
    input  wire [255:0]                 l2_response_data,  // Data from L2 cache for read responses
    input  wire                         l2_response_error   // Error status from L2 cache
);

    // Define internal components and signals
    
    // Request Arbiter for selecting between multiple master requests
    wire                      arb_valid;
    wire [1:0]                arb_channel;   // 0 = Channel A, 1 = Channel C
    wire [3:0]                arb_master_oh; // One-hot encoding of selected master
    wire [1:0]                arb_master_id; // Binary encoding of selected master (log2(4) = 2 bits)
    wire                      arb_ready;
    wire                      arb_busy;
    
    // Directory interface signals
    reg                       dir_lookup_req;
    reg  [31:0]               dir_lookup_addr;
    wire                      dir_lookup_valid;
    wire [2:0]                dir_lookup_state;
    wire [3:0]                dir_lookup_presence;
    wire [3:0]                dir_lookup_tip_state;
    
    reg                       dir_update_req;
    reg  [31:0]               dir_update_addr;
    reg  [2:0]                dir_update_state;
    reg  [3:0]                dir_update_presence;
    reg  [3:0]                dir_update_tip_state;
    wire                      dir_update_done;
    
    // Sink ID Manager signals
    wire                      sink_id_alloc_req;
    wire                      sink_id_alloc_gnt;
    wire [3:0]                sink_id_alloc_sink_id;
    wire                      sink_id_dealloc_req;
    reg  [3:0]                sink_id_dealloc_sink_id;
    
    // State Machine Definitions
    localparam STATE_IDLE             = 4'd0;  // Idle, waiting for requests
    localparam STATE_DIR_LOOKUP       = 4'd1;  // Looking up address in directory
    localparam STATE_ACQUIRE_PROCESS  = 4'd2;  // Processing an Acquire request
    localparam STATE_PROBE_SEND       = 4'd3;  // Sending Probes to sharers
    localparam STATE_PROBE_WAIT       = 4'd4;  // Waiting for ProbeAcks
    localparam STATE_L2_ACCESS        = 4'd5;  // Accessing L2 cache
    localparam STATE_GRANT_SEND       = 4'd6;  // Sending Grant/GrantData
    localparam STATE_RELEASE_PROCESS  = 4'd7;  // Processing a Release/ReleaseData
    localparam STATE_RELEASEACK_SEND  = 4'd8;  // Sending ReleaseAck
    localparam STATE_GRANTACK_WAIT    = 4'd9;  // Waiting for GrantAck
    localparam STATE_UNCACHED_PROCESS = 4'd10; // Processing uncached request
    
    // Main state machine register
    reg [3:0] state;
    reg [3:0] next_state;
    
    // Pending transaction tracking
    reg [31:0]                 pending_addr;
    reg [1:0]                  pending_master_id;
    reg [2:0]                  pending_opcode;
    reg [2:0]                  pending_param;
    reg [3:0]                  pending_source;
    reg [3:0]                  pending_sink;
    reg [255:0]                pending_data;
    
    // Probe response tracking
    reg [3:0]                  probe_sent;      // Bit vector of L1s that were probed
    reg [3:0]                  probe_acked;     // Bit vector of L1s that have responded
    
    // Integer variables for loops
    integer i, j;
    
    // Request Arbiter instantiation
    l2_request_arbiter request_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .a_valid_i(a_valid),
        .a_opcode_i(a_opcode),
        .a_ready_o(a_ready),
        .c_valid_i(c_valid),
        .c_opcode_i(c_opcode),
        .c_ready_o(c_ready),
        .arb_valid(arb_valid),
        .arb_channel(arb_channel),
        .arb_master_oh(arb_master_oh),
        .arb_master_id(arb_master_id),
        .arb_ready(arb_ready),
        .arb_busy(arb_busy)
    );
    
    // Directory instantiation
    directory directory_inst (
        .clk(clk),
        .rst_n(rst_n),
        .lookup_req(dir_lookup_req),
        .lookup_addr(dir_lookup_addr),
        .lookup_valid(dir_lookup_valid),
        .lookup_state(dir_lookup_state),
        .lookup_presence(dir_lookup_presence),
        .lookup_tip_state(dir_lookup_tip_state),
        .update_req(dir_update_req),
        .update_addr(dir_update_addr),
        .update_state(dir_update_state),
        .update_presence(dir_update_presence),
        .update_tip_state(dir_update_tip_state),
        .update_done(dir_update_done)
    );
    
    // Sink ID Manager instantiation
    sink_id_manager sink_id_mgr (
        .clk(clk),
        .rst(~rst_n),
        .alloc_req(sink_id_alloc_req),
        .alloc_gnt(sink_id_alloc_gnt),
        .alloc_sink_id(sink_id_alloc_sink_id),
        .dealloc_req(sink_id_dealloc_req),
        .dealloc_sink_id(sink_id_dealloc_sink_id)
    );
    
    // Control logic for Sink ID allocation
    assign sink_id_alloc_req = (state == STATE_GRANT_SEND) && !d_valid[pending_master_id] && l2_response_valid;
    assign sink_id_dealloc_req = (state == STATE_GRANTACK_WAIT) && e_valid[pending_master_id] && 
                               (e_sink[pending_master_id*4 +: 4] == pending_sink);
    
    // Connect to arbiter - ready when we can accept a new request
    // Always ready to avoid circular dependency - L2 adapter will handle queuing internally if needed
    assign arb_ready = 1'b1;
    
    // Grant ready signal on Channel E (always ready to accept GrantAcks)
    assign e_ready = 4'b1111;
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            state <= STATE_IDLE;
            
            // Reset pending transaction tracking
            pending_addr <= 32'b0;
            pending_master_id <= 2'b0;
            pending_opcode <= 3'b000;
            pending_param <= 3'b000;
            pending_source <= 4'b0;
            pending_sink <= 4'b0;
            pending_data <= 256'b0;
            
            // Reset probe tracking
            probe_sent <= 4'b0;
            probe_acked <= 4'b0;
            
            // Reset directory interface
            dir_lookup_req <= 1'b0;
            dir_lookup_addr <= 32'b0;
            dir_update_req <= 1'b0;
            dir_update_addr <= 32'b0;
            dir_update_state <= 3'b000;
            dir_update_presence <= 4'b0;
            dir_update_tip_state <= 4'b0;
            
            // Reset L2 cache interface
            l2_cmd_valid <= 1'b0;
            l2_cmd_type <= 3'b000;
            l2_cmd_addr <= 32'b0;
            l2_cmd_data <= 256'b0;
            l2_cmd_size <= 4'b0;
            l2_cmd_dirty <= 1'b0;
            
            // Reset TileLink outputs
            b_valid <= 4'b0;
            b_opcode <= 12'b0;
            b_param <= 12'b0;
            b_size <= 16'b0;
            b_source <= 16'b0;
            b_address <= 128'b0;
            b_data <= 256'b0;
            b_mask <= 32'b0;
            
            d_valid <= 4'b0;
            d_opcode <= 12'b0;
            d_param <= 12'b0;
            d_size <= 16'b0;
            d_source <= 16'b0;
            d_sink <= 16'b0;
            d_data <= 256'b0;
            d_error <= 4'b0;
            
            sink_id_dealloc_sink_id <= 4'b0;
        end
        else begin
            // Default values - clear one-shot signals
            dir_lookup_req <= 1'b0;
            dir_update_req <= 1'b0;
            l2_cmd_valid <= 1'b0;
            b_valid <= 4'b0;
            d_valid <= 4'b0;
            
            // State machine transitions
            state <= next_state;
            
            // State-specific actions
            case (state)
                STATE_IDLE: begin
                    // When a request arrives via the arbiter, capture it
                    if (arb_valid) begin
                        // Save request details
                        pending_master_id <= arb_master_id;
                        
                        // Extract information based on channel
                        if (arb_channel == 2'b00) begin // Channel A
                            // Extract Channel A signals for the selected master
                            pending_addr <= a_address[arb_master_id*32 +: 32];
                            pending_opcode <= a_opcode[arb_master_id*3 +: 3];
                            pending_param <= a_param[arb_master_id*3 +: 3];
                            pending_source <= a_source[arb_master_id*4 +: 4];
                            pending_data <= {{(256-64){1'b0}}, a_data[arb_master_id*64 +: 64]};
                        end
                        else begin // Channel C
                            // Extract Channel C signals for the selected master
                            pending_addr <= c_address[arb_master_id*32 +: 32];
                            pending_opcode <= c_opcode[arb_master_id*3 +: 3];
                            pending_param <= c_param[arb_master_id*3 +: 3];
                            pending_source <= c_source[arb_master_id*4 +: 4];
                            pending_data <= {{(256-64){1'b0}}, c_data[arb_master_id*64 +: 64]};
                        end
                    end
                end
                
                STATE_DIR_LOOKUP: begin
                    // Initiate directory lookup
                    dir_lookup_req <= 1'b1;
                    dir_lookup_addr <= pending_addr;
                end
                
                STATE_ACQUIRE_PROCESS: begin
                    // Process Acquire request based on directory state and requested permissions
                    if (dir_lookup_valid) begin
                        // Determine which L1s need to be probed based on requested permissions
                        if (pending_param == PARAM_NtoT || pending_param == PARAM_BtoT) begin
                            // Exclusive access requested - need to invalidate/downgrade all sharers
                            if (dir_lookup_state == DIR_STATE_SHARED || dir_lookup_state == DIR_STATE_EXCLUSIVE) begin
                                // There are sharers that need to be probed
                                probe_sent <= dir_lookup_presence & ~(1 << pending_master_id); // Don't probe requesting L1
                                probe_acked <= 4'b0;
                            end
                            else begin
                                // No sharers, can proceed directly to L2 access
                                probe_sent <= 4'b0;
                                probe_acked <= 4'b0;
                            end
                        end
                        else begin // NtoB - shared access
                            // No probes needed for shared access
                            probe_sent <= 4'b0;
                            probe_acked <= 4'b0;
                        end
                    end
                end
                
                STATE_PROBE_SEND: begin
                    // Send probes to L1s that have the cache line
                    for (i = 0; i < 4; i = i + 1) begin
                        if (probe_sent[i] && !probe_acked[i]) begin
                            // Send probe to this L1
                            b_valid[i] <= 1'b1;
                            b_opcode[i*3 +: 3] <= B_OPCODE_PROBE_BLOCK;
                            b_param[i*3 +: 3] <= (pending_param == PARAM_NtoT || pending_param == PARAM_BtoT) ? 
                                                  PARAM_toN : PARAM_toB; // Invalidate for exclusive, downgrade for shared
                            b_size[i*4 +: 4] <= 4'($clog2(256/8));
                            b_source[i*4 +: 4] <= pending_source;
                            b_address[i*32 +: 32] <= pending_addr;
                            b_data[i*64 +: 64] <= 64'b0;
                            b_mask[i*8 +: 8] <= 8'b11111111;
                        end
                    end
                end
                
                STATE_PROBE_WAIT: begin
                    // Check for incoming ProbeAck messages on Channel C
                    for (j = 0; j < 4; j = j + 1) begin
                        if (c_valid[j] && (c_opcode[j*3 +: 3] == C_OPCODE_PROBE_ACK || 
                                          c_opcode[j*3 +: 3] == C_OPCODE_PROBE_ACK_DATA) &&
                            c_address[j*32 +: 32] == pending_addr && probe_sent[j]) begin
                            
                            // Mark this L1 as having responded
                            probe_acked[j] <= 1'b1;
                            
                            // If ProbeAckData, write the data to L2 cache
                            if (c_opcode[j*3 +: 3] == C_OPCODE_PROBE_ACK_DATA) begin
                                l2_cmd_valid <= 1'b1;
                                l2_cmd_type <= L2_CMD_WRITE_BACK;
                                l2_cmd_addr <= pending_addr;
                                l2_cmd_data <= {{(256-64){1'b0}}, c_data[j*64 +: 64]};
                                l2_cmd_size <= $clog2(256/8);
                                l2_cmd_dirty <= 1'b1;
                            end
                        end
                    end
                end
                
                STATE_L2_ACCESS: begin
                    // Access L2 cache for the data
                    if (pending_opcode == A_OPCODE_ACQUIRE_BLOCK) begin
                        l2_cmd_valid <= 1'b1;
                        l2_cmd_type <= L2_CMD_READ;
                        l2_cmd_addr <= pending_addr;
                        l2_cmd_data <= 256'b0;
                        l2_cmd_size <= $clog2(256/8);
                        l2_cmd_dirty <= 1'b0;
                    end
                end
                
                STATE_GRANT_SEND: begin
                    // Send Grant/GrantData to the requesting L1
                    if (l2_response_valid && sink_id_alloc_gnt) begin
                        pending_sink <= sink_id_alloc_sink_id;
                        
                        d_valid[pending_master_id] <= 1'b1;
                        d_opcode[pending_master_id*3 +: 3] <= D_OPCODE_GRANT_DATA;
                        d_param[pending_master_id*3 +: 3] <= pending_param; // Grant the requested permissions
                        d_size[pending_master_id*4 +: 4] <= $clog2(256/8);
                        d_source[pending_master_id*4 +: 4] <= pending_source;
                        d_sink[pending_master_id*4 +: 4] <= sink_id_alloc_sink_id;
                        d_data[pending_master_id*64 +: 64] <= l2_response_data[63:0];
                        d_error[pending_master_id] <= l2_response_error;
                    end
                end
                
                STATE_RELEASE_PROCESS: begin
                    // Process Release/ReleaseData from L1
                    if (pending_opcode == C_OPCODE_RELEASE_DATA) begin
                        // Write the released data to L2 cache
                        l2_cmd_valid <= 1'b1;
                        l2_cmd_type <= L2_CMD_WRITE_BACK;
                        l2_cmd_addr <= pending_addr;
                        l2_cmd_data <= pending_data;
                        l2_cmd_size <= $clog2(256/8);
                        l2_cmd_dirty <= 1'b1;
                    end
                    
                    // Update directory to remove this L1 from presence vector
                    dir_update_req <= 1'b1;
                    dir_update_addr <= pending_addr;
                    
                    // Calculate new directory state
                    if (pending_param == PARAM_TtoN || pending_param == PARAM_BtoN) begin
                        // Remove this L1 from presence
                        dir_update_presence <= dir_lookup_presence & ~(1 << pending_master_id);
                        dir_update_tip_state <= dir_lookup_tip_state & ~(1 << pending_master_id);
                        
                        // Determine new global state
                        if ((dir_lookup_presence & ~(1 << pending_master_id)) == 0) begin
                            dir_update_state <= DIR_STATE_INVALID;
                        end
                        else if (|(dir_lookup_tip_state & ~(1 << pending_master_id))) begin
                            dir_update_state <= DIR_STATE_EXCLUSIVE;
                        end
                        else begin
                            dir_update_state <= DIR_STATE_SHARED;
                        end
                    end
                end
                
                STATE_RELEASEACK_SEND: begin
                    // Send ReleaseAck to the L1
                    d_valid[pending_master_id] <= 1'b1;
                    d_opcode[pending_master_id*3 +: 3] <= D_OPCODE_RELEASE_ACK;
                    d_param[pending_master_id*3 +: 3] <= 3'b000;
                    d_size[pending_master_id*4 +: 4] <= $clog2(256/8);
                    d_source[pending_master_id*4 +: 4] <= pending_source;
                    d_sink[pending_master_id*4 +: 4] <= {4{1'b0}};
                    d_data[pending_master_id*64 +: 64] <= {64{1'b0}};
                    d_error[pending_master_id] <= 1'b0;
                end
                
                STATE_GRANTACK_WAIT: begin
                    // Wait for GrantAck and update directory when received
                    if (e_valid[pending_master_id] && 
                        e_sink[pending_master_id*4 +: 4] == pending_sink) begin
                        
                        // Update directory with new state
                        dir_update_req <= 1'b1;
                        dir_update_addr <= pending_addr;
                        dir_update_presence <= dir_lookup_presence | (1 << pending_master_id);
                        
                        if (pending_param == PARAM_NtoT || pending_param == PARAM_BtoT) begin
                            // Exclusive access granted
                            dir_update_tip_state <= (1 << pending_master_id);
                            dir_update_state <= DIR_STATE_EXCLUSIVE;
                        end
                        else begin
                            // Shared access granted
                            dir_update_tip_state <= dir_lookup_tip_state & ~(1 << pending_master_id);
                            dir_update_state <= DIR_STATE_SHARED;
                        end
                        
                        // Deallocate sink ID
                        sink_id_dealloc_sink_id <= pending_sink;
                    end
                end
                
                STATE_UNCACHED_PROCESS: begin
                    // Handle uncached Get/Put operations
                    if (pending_opcode == A_OPCODE_GET) begin
                        // Uncached read
                        l2_cmd_valid <= 1'b1;
                        l2_cmd_type <= L2_CMD_READ;
                        l2_cmd_addr <= pending_addr;
                        l2_cmd_data <= {256{1'b0}};
                        l2_cmd_size <= $clog2(256/8);
                        l2_cmd_dirty <= 1'b0;
                    end
                    else if (pending_opcode == A_OPCODE_PUT_FULL_DATA) begin
                        // Uncached write
                        l2_cmd_valid <= 1'b1;
                        l2_cmd_type <= L2_CMD_WRITE;
                        l2_cmd_addr <= pending_addr;
                        l2_cmd_data <= pending_data;
                        l2_cmd_size <= $clog2(256/8);
                        l2_cmd_dirty <= 1'b1;
                        
                        // Send immediate AccessAck for writes
                        d_valid[pending_master_id] <= 1'b1;
                        d_opcode[pending_master_id*3 +: 3] <= D_OPCODE_ACCESS_ACK;
                        d_param[pending_master_id*3 +: 3] <= 3'b000;
                        d_size[pending_master_id*4 +: 4] <= $clog2(256/8);
                        d_source[pending_master_id*4 +: 4] <= pending_source;
                        d_sink[pending_master_id*4 +: 4] <= {4{1'b0}};
                        d_data[pending_master_id*64 +: 64] <= {64{1'b0}};
                        d_error[pending_master_id] <= l2_response_error;
                    end
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        // Default: stay in current state
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (arb_valid) begin
                    next_state = STATE_DIR_LOOKUP;
                end
            end
            
            STATE_DIR_LOOKUP: begin
                if (dir_lookup_valid) begin
                    // Determine next state based on request type
                    if (pending_opcode == A_OPCODE_ACQUIRE_BLOCK) begin
                        next_state = STATE_ACQUIRE_PROCESS;
                    end
                    else if (pending_opcode == C_OPCODE_RELEASE || pending_opcode == C_OPCODE_RELEASE_DATA) begin
                        next_state = STATE_RELEASE_PROCESS;
                    end
                    else if (pending_opcode == A_OPCODE_GET || pending_opcode == A_OPCODE_PUT_FULL_DATA) begin
                        next_state = STATE_UNCACHED_PROCESS;
                    end
                    else begin
                        next_state = STATE_IDLE; // Unknown opcode
                    end
                end
            end
            
            STATE_ACQUIRE_PROCESS: begin
                if (|probe_sent) begin
                    next_state = STATE_PROBE_SEND;
                end
                else begin
                    next_state = STATE_L2_ACCESS;
                end
            end
            
            STATE_PROBE_SEND: begin
                // Move to wait state after sending probes
                next_state = STATE_PROBE_WAIT;
            end
            
            STATE_PROBE_WAIT: begin
                // Check if all probes have been acknowledged
                if ((probe_sent & probe_acked) == probe_sent) begin
                    next_state = STATE_L2_ACCESS;
                end
            end
            
            STATE_L2_ACCESS: begin
                if (l2_response_valid) begin
                    next_state = STATE_GRANT_SEND;
                end
            end
            
            STATE_GRANT_SEND: begin
                if (d_valid[pending_master_id] && d_ready[pending_master_id]) begin
                    next_state = STATE_GRANTACK_WAIT;
                end
            end
            
            STATE_RELEASE_PROCESS: begin
                if (dir_update_done) begin
                    next_state = STATE_RELEASEACK_SEND;
                end
            end
            
            STATE_RELEASEACK_SEND: begin
                if (d_valid[pending_master_id] && d_ready[pending_master_id]) begin
                    next_state = STATE_IDLE;
                end
            end
            
            STATE_GRANTACK_WAIT: begin
                if (e_valid[pending_master_id] && 
                    e_sink[pending_master_id*4 +: 4] == pending_sink) begin
                    next_state = STATE_IDLE;
                end
            end
            
            STATE_UNCACHED_PROCESS: begin
                if (pending_opcode == A_OPCODE_GET && l2_response_valid) begin
                    // Send AccessAckData for uncached read
                    next_state = STATE_IDLE;
                end
                else if (pending_opcode == A_OPCODE_PUT_FULL_DATA) begin
                    // AccessAck already sent for uncached write
                    next_state = STATE_IDLE;
                end
            end
        endcase
    end
    
endmodule 