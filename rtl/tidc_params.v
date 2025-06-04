// =============================================================================
// Project: TileLink Inclusive Directory Coherence (TIDC) System
// Module: TIDC System Parameters
// Description: Shared parameter definitions for the TIDC system
// =============================================================================

`ifndef TIDC_PARAMS_V
`define TIDC_PARAMS_V

// TileLink Protocol Constants
// Channel A opcodes (Master → Slave)
localparam A_OPCODE_PUT_FULL_DATA       = 0;   // PutFullData
localparam A_OPCODE_PUT_PARTIAL_DATA    = 1;   // PutPartialData
localparam A_OPCODE_ARITHMETIC_DATA     = 2;   // ArithmeticData
localparam A_OPCODE_LOGICAL_DATA        = 3;   // LogicalData
localparam A_OPCODE_GET                 = 4;   // Get
localparam A_OPCODE_INTENT              = 5;   // Intent
localparam A_OPCODE_ACQUIRE_BLOCK       = 6;   // Acquire

// Channel B opcodes (Slave → Master)
localparam B_OPCODE_PUT_FULL_DATA       = 0;   // PutFullData
localparam B_OPCODE_PUT_PARTIAL_DATA    = 1;   // PutPartialData
localparam B_OPCODE_ARITHMETIC_DATA     = 2;   // ArithmeticData
localparam B_OPCODE_LOGICAL_DATA        = 3;   // LogicalData
localparam B_OPCODE_GET                 = 4;   // Get
localparam B_OPCODE_INTENT              = 5;   // Intent
localparam B_OPCODE_PROBE_BLOCK         = 6;   // Probe

// Channel C opcodes (Master → Slave)
localparam C_OPCODE_ACCESS_ACK          = 0;   // AccessAck
localparam C_OPCODE_ACCESS_ACK_DATA     = 1;   // AccessAckData
localparam C_OPCODE_HINT_ACK            = 2;   // HintAck
localparam C_OPCODE_PROBE_ACK           = 4;   // ProbeAck
localparam C_OPCODE_PROBE_ACK_DATA      = 5;   // ProbeAckData
localparam C_OPCODE_RELEASE             = 6;   // Release
localparam C_OPCODE_RELEASE_DATA        = 7;   // ReleaseData

// Channel D opcodes (Slave → Master)
localparam D_OPCODE_ACCESS_ACK          = 0;   // AccessAck
localparam D_OPCODE_ACCESS_ACK_DATA     = 1;   // AccessAckData
localparam D_OPCODE_HINT_ACK            = 2;   // HintAck
localparam D_OPCODE_GRANT               = 4;   // Grant
localparam D_OPCODE_GRANT_DATA          = 5;   // GrantData
localparam D_OPCODE_RELEASE_ACK         = 6;   // ReleaseAck

// Channel E opcode (Master → Slave)
localparam E_OPCODE_GRANT_ACK           = 0;   // GrantAck

// Permission parameters (for a_param, b_param, c_param, and d_param)
// Grow permissions (NtoB, NtoT, BtoT)
localparam PARAM_NtoB                   = 0;   // None to Branch
localparam PARAM_NtoT                   = 1;   // None to Tip
localparam PARAM_BtoT                   = 2;   // Branch to Tip

// Cap permissions (TtoB, TtoN, BtoN)
localparam PARAM_TtoB                   = 0;   // Tip to Branch
localparam PARAM_TtoN                   = 1;   // Tip to None
localparam PARAM_BtoN                   = 2;   // Branch to None

// Report permissions (TtoT, BtoB, NtoN)
localparam PARAM_TtoT                   = 3;   // Tip to Tip (no change)
localparam PARAM_BtoB                   = 4;   // Branch to Branch (no change)
localparam PARAM_NtoN                   = 5;   // None to None (no change)

// Probe permissions (toN, toB, toT)
localparam PARAM_toN                    = 0;   // to None (invalidate)
localparam PARAM_toB                    = 1;   // to Branch (downgrade)
localparam PARAM_toT                    = 2;   // to Tip (no change of permission)

// L1 Cache Controller request types
localparam L1_REQ_READ_MISS             = 0;   // Read miss
localparam L1_REQ_WRITE_MISS            = 1;   // Write miss
localparam L1_REQ_WRITE_BACK            = 2;   // Write-back
localparam L1_REQ_UNCACHED_READ         = 3;   // Uncached read
localparam L1_REQ_UNCACHED_WRITE        = 4;   // Uncached write

// L2 Cache Controller command types
localparam L2_CMD_READ                  = 0;   // Read operation
localparam L2_CMD_WRITE                 = 1;   // Write operation
localparam L2_CMD_INVALIDATE            = 2;   // Invalidate operation
localparam L2_CMD_WRITE_BACK            = 3;   // Write-back operation

// Directory states
localparam DIR_STATE_INVALID            = 0;   // Line not present in any L1 cache
localparam DIR_STATE_SHARED             = 1;   // Line present in 1+ L1s as Branch (shared)
localparam DIR_STATE_EXCLUSIVE          = 2;   // Line present in exactly 1 L1 as Tip (exclusive)
localparam DIR_STATE_PENDING_PROBE      = 3;   // In process of probing L1s
localparam DIR_STATE_PENDING_GRANT      = 4;   // In process of granting to L1

// System Configuration Parameters
localparam NUM_L1_CACHES               = 4;    // Number of L1 cache interfaces
localparam WDATA                       = 8;    // TileLink data width in bytes
localparam WADDR                       = 32;   // Address width in bits
localparam CACHE_LINE_BITS             = 256;  // Cache line size in bits
localparam WSOURCE                     = 4;    // Source ID width in bits (16 IDs)
localparam WSINK                       = 4;    // Sink ID width in bits (16 IDs)
localparam WSIZE                       = 4;    // Size field width in bits
localparam NUM_MASTERS                 = 4;    // Number of masters (L1 caches)

`endif // TIDC_PARAMS_V