// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: L2 Request Arbiter
// Description: Arbitrates among multiple incoming TileLink Channel A and C requests
//              according to TileLink channel priority rules (A ≤ B ≤ C ≤ D ≤ E)
// =============================================================================

module l2_request_arbiter (
    input  wire                     clk,
    input  wire                     rst_n,
    
    // Channel A request signals from each master
    input  wire [3:0]               a_valid_i,
    input  wire [11:0]              a_opcode_i,  // Packed array: {a_opcode_master3, a_opcode_master2, a_opcode_master1, a_opcode_master0} (4*3)
    output wire [3:0]               a_ready_o,
    
    // Channel C request signals from each master
    input  wire [3:0]               c_valid_i,
    input  wire [11:0]              c_opcode_i,  // Packed array: {c_opcode_master3, c_opcode_master2, c_opcode_master1, c_opcode_master0} (4*3)
    output wire [3:0]               c_ready_o,
    
    // Arbiter output signals
    output reg                      arb_valid,
    output reg  [1:0]               arb_channel,   // 0 = Channel A, 1 = Channel C
    output reg  [3:0]               arb_master_oh, // One-hot encoding of selected master
    output wire [1:0]               arb_master_id, // Binary encoding of selected master (log2(4) = 2 bits)
    
    // Arbiter control signals
    input  wire                     arb_ready,     // Indicates downstream logic is ready to accept the arbitrated request
    output reg                      arb_busy       // Indicates arbiter is busy processing a request
);

    // Constants
    localparam CHANNEL_A = 2'b00;
    localparam CHANNEL_C = 2'b01;
    
    // State definitions
    localparam STATE_IDLE    = 2'd0;
    localparam STATE_REQUEST = 2'd1;
    localparam STATE_WAIT    = 2'd2;
    
    // State machine registers
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Round-robin counters for fair arbitration within each channel
    reg [1:0] a_rr_ptr;
    reg [1:0] c_rr_ptr;
    
    // Request detection
    wire [3:0] a_req_pending;
    wire [3:0] c_req_pending;
    wire any_a_req;
    wire any_c_req;
    
    // Request selection
    wire [3:0] a_req_masked;
    wire [3:0] c_req_masked;
    wire [3:0] a_selected_oh;
    wire [3:0] c_selected_oh;
    wire [1:0] a_selected_id;
    wire [1:0] c_selected_id;
    
    // Generate binary ID from one-hot encoding
    function [1:0] oh_to_binary;
        input [3:0] one_hot;
        integer i;
        begin
            oh_to_binary = 0;
            for (i = 0; i < 4; i = i + 1) begin
                if (one_hot[i]) oh_to_binary = i[1:0];
            end
        end
    endfunction
    
    // Pending request detection
    assign a_req_pending = a_valid_i;
    assign c_req_pending = c_valid_i;
    assign any_a_req = |a_req_pending;
    assign any_c_req = |c_req_pending;
    
    // Round-robin request masking
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : gen_masked_reqs
            // For Channel A
            assign a_req_masked[i] = a_req_pending[i] && (i >= a_rr_ptr);
            
            // For Channel C
            assign c_req_masked[i] = c_req_pending[i] && (i >= c_rr_ptr);
        end
    endgenerate
    
    // Select first requestor in each channel
    assign a_selected_oh = |a_req_masked ? a_req_masked & -a_req_masked : // Select first set bit in masked requests
                                        a_req_pending & -a_req_pending;  // If no masked requests, select first in unmasked
    assign c_selected_oh = |c_req_masked ? c_req_masked & -c_req_masked : // Select first set bit in masked requests
                                        c_req_pending & -c_req_pending;  // If no masked requests, select first in unmasked
    
    // Convert one-hot to binary ID
    assign a_selected_id = oh_to_binary(a_selected_oh);
    assign c_selected_id = oh_to_binary(c_selected_oh);
    
    // Output master ID as binary
    assign arb_master_id = oh_to_binary(arb_master_oh);
    
    // Ready signals for incoming channels
    // Only assert ready for the selected master when arbiter is ready
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_ready_signals
            assign a_ready_o[i] = arb_ready && (state == STATE_REQUEST) && (arb_channel == CHANNEL_A) && arb_master_oh[i];
            assign c_ready_o[i] = arb_ready && (state == STATE_REQUEST) && (arb_channel == CHANNEL_C) && arb_master_oh[i];
        end
    endgenerate
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state <= STATE_IDLE;
            arb_busy <= 1'b0;
            
            // Reset arbitration signals
            arb_valid <= 1'b0;
            arb_channel <= CHANNEL_A;
            arb_master_oh <= 4'b0;
            
            // Reset round-robin pointers
            a_rr_ptr <= 2'b0;
            c_rr_ptr <= 2'b0;
        end
        else begin
            // Update state
            state <= next_state;
            
            // Default: clear valid signal
            arb_valid <= 1'b0;
            
            case (state)
                STATE_IDLE: begin
                    arb_busy <= 1'b0;
                    
                    // When entering REQUEST state, select a master based on priority
                    if (next_state == STATE_REQUEST) begin
                        arb_busy <= 1'b1;
                        
                        // Channel C has higher priority than Channel A
                        if (any_c_req) begin
                            arb_channel <= CHANNEL_C;
                            arb_master_oh <= c_selected_oh;
                        end
                        else begin
                            arb_channel <= CHANNEL_A;
                            arb_master_oh <= a_selected_oh;
                        end
                    end
                end
                
                STATE_REQUEST: begin
                    // Assert valid to signal selection is complete
                    arb_valid <= 1'b1;
                    
                    // If downstream logic accepts the request, update round-robin pointer for the selected channel
                    if (arb_ready) begin
                        if (arb_channel == CHANNEL_A) begin
                            // Update Channel A round-robin pointer for fairness
                            a_rr_ptr <= (a_selected_id + 1) % 4;
                        end
                        else begin
                            // Update Channel C round-robin pointer for fairness
                            c_rr_ptr <= (c_selected_id + 1) % 4;
                        end
                    end
                end
                
                STATE_WAIT: begin
                    // Wait state - keep busy signal asserted
                    arb_busy <= 1'b1;
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        // Default next state
        next_state = state;
        
        case (state)
            STATE_IDLE: begin
                if (any_a_req || any_c_req) begin
                    next_state = STATE_REQUEST;
                end
            end
            
            STATE_REQUEST: begin
                if (arb_ready) begin
                    // If there are still more requests pending, stay in REQUEST
                    // Otherwise go to IDLE
                    if (any_a_req || any_c_req) begin
                        next_state = STATE_REQUEST;
                    end
                    else begin
                        next_state = STATE_IDLE;
                    end
                end
                else begin
                    // If downstream is not ready, wait
                    next_state = STATE_WAIT;
                end
            end
            
            STATE_WAIT: begin
                if (arb_ready) begin
                    // Once downstream is ready, check if more requests are pending
                    if (any_a_req || any_c_req) begin
                        next_state = STATE_REQUEST;
                    end
                    else begin
                        next_state = STATE_IDLE;
                    end
                end
            end
        endcase
    end

endmodule 