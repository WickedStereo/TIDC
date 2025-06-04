// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: Directory
// Description: Stores and manages the global coherence state for each cache line
// =============================================================================

// Include shared parameter definitions
`include "tidc_params.v"

module directory (
    input  wire                       clk,
    input  wire                       rst_n,
    
    // Directory lookup interface
    input  wire                       lookup_req,
    input  wire [31:0]                lookup_addr,
    output reg                        lookup_valid,
    output reg  [2:0]                 lookup_state,  // DIR_STATE_*
    output reg  [3:0]                 lookup_presence,  // Bit vector of L1s with this line
    output reg  [3:0]                 lookup_tip_state, // Bit vector of L1s with Tip permission
    
    // Directory update interface
    input  wire                       update_req,
    input  wire [31:0]                update_addr,
    input  wire [2:0]                 update_state,  // New directory state (DIR_STATE_*)
    input  wire [3:0]                 update_presence,  // New presence vector
    input  wire [3:0]                 update_tip_state, // New Tip state vector
    output reg                        update_done
);

    // Directory parameters
    localparam DIR_SIZE = 64;  // Small directory for testing
    localparam DIR_INDEX_WIDTH = 6;  // 6 bits for 64 entries
    localparam DIR_TAG_WIDTH = 32 - DIR_INDEX_WIDTH; // 26 bits
    
    // Directory entry structure
    reg [DIR_TAG_WIDTH-1:0]       dir_tags [DIR_SIZE-1:0];
    reg [2:0]                     dir_states [DIR_SIZE-1:0];
    reg [3:0]                     dir_presence [DIR_SIZE-1:0];
    reg [3:0]                     dir_tip_state [DIR_SIZE-1:0];
    reg                           dir_valid [DIR_SIZE-1:0];
    
    // Extract index and tag from address
    function [DIR_INDEX_WIDTH-1:0] get_index;
        input [31:0] addr;
        begin
            get_index = addr[DIR_INDEX_WIDTH-1:0];
        end
    endfunction
    
    function [DIR_TAG_WIDTH-1:0] get_tag;
        input [31:0] addr;
        begin
            get_tag = addr[31:DIR_INDEX_WIDTH];
        end
    endfunction
    
    // State machine for directory operations
    localparam STATE_IDLE     = 2'd0;
    localparam STATE_LOOKUP   = 2'd1;
    localparam STATE_UPDATE   = 2'd2;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Processed request storage
    reg [31:0] req_addr;
    
    // Reset and initialization
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize directory
            for (i = 0; i < DIR_SIZE; i = i + 1) begin
                dir_valid[i] <= 1'b0;
                dir_tags[i] <= {DIR_TAG_WIDTH{1'b0}};
                dir_states[i] <= DIR_STATE_INVALID;
                dir_presence[i] <= 4'b0;
                dir_tip_state[i] <= 4'b0;
            end
            
            // Initialize outputs
            lookup_valid <= 1'b0;
            lookup_state <= 3'b000;
            lookup_presence <= 4'b0;
            lookup_tip_state <= 4'b0;
            
            update_done <= 1'b0;
            
            // Initialize state machine
            state <= STATE_IDLE;
            req_addr <= 32'b0;
        end
        else begin
            // Default values
            lookup_valid <= 1'b0;
            update_done <= 1'b0;
            
            // State machine transitions
            state <= next_state;
            
            // Save request address
            if ((state == STATE_IDLE && lookup_req) || (state == STATE_IDLE && update_req)) begin
                req_addr <= lookup_req ? lookup_addr : update_addr;
            end
            
            // Handle directory operations
            case (state)
                STATE_IDLE: begin
                    // No operation in IDLE, transitions handled in next_state logic
                end
                
                STATE_LOOKUP: begin
                    // Perform directory lookup
                    if (dir_valid[get_index(req_addr)] && dir_tags[get_index(req_addr)] == get_tag(req_addr)) begin
                        // Directory hit
                        lookup_valid <= 1'b1;
                        lookup_state <= dir_states[get_index(req_addr)];
                        lookup_presence <= dir_presence[get_index(req_addr)];
                        lookup_tip_state <= dir_tip_state[get_index(req_addr)];
                    end
                    else begin
                        // Directory miss (entry not present)
                        lookup_valid <= 1'b1;
                        lookup_state <= DIR_STATE_INVALID;
                        lookup_presence <= 4'b0;
                        lookup_tip_state <= 4'b0;
                    end
                end
                
                STATE_UPDATE: begin
                    // Perform directory update
                    dir_valid[get_index(req_addr)] <= 1'b1;
                    dir_tags[get_index(req_addr)] <= get_tag(req_addr);
                    dir_states[get_index(req_addr)] <= update_state;
                    dir_presence[get_index(req_addr)] <= update_presence;
                    dir_tip_state[get_index(req_addr)] <= update_tip_state;
                    
                    // Signal update completion
                    update_done <= 1'b1;
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
                if (lookup_req) begin
                    next_state = STATE_LOOKUP;
                end
                else if (update_req) begin
                    next_state = STATE_UPDATE;
                end
            end
            
            STATE_LOOKUP: begin
                next_state = STATE_IDLE;
            end
            
            STATE_UPDATE: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

endmodule 