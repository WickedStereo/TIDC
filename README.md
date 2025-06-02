# TileLink Inclusive Directory Coherence (TIDC) System

This repository contains a Verilog implementation of a TileLink Inclusive Directory Coherence system, designed to provide cache coherence among four L1 caches and a unified L2 cache using the SiFive TileLink Cached (TL-C) protocol.

## System Overview

The TIDC system implements a **directory-based cache coherence protocol** using TileLink TL-C specification:

- **Inclusive Coherence Policy**: Any cache line present in an L1 cache must also be present in the L2 cache
- **Directory-Based Coherence**: The L2 cache maintains a directory of L1 cache line states
- **Multiple Transaction Support**: Each L1 can have multiple outstanding transactions 
- **Protocol Compliance**: Follows the TileLink Cached (TL-C) protocol with five channels (A, B, C, D, E)

### Architecture Components

| Component | Count | Description |
|-----------|-------|-------------|
| **L1 TileLink Adapters** | 4 | Convert cache requests to TileLink messages |
| **L2 TileLink Adapter** | 1 | Central coherence manager with directory |
| **Directory** | 1 | 64-entry direct-mapped coherence tracking |
| **Request Arbiter** | 1 | Round-robin arbitration with channel priority |
| **Source ID Managers** | 4 | Transaction ID allocation for L1s |
| **Sink ID Manager** | 1 | Response ID tracking for L2 |

## 📁 Directory Structure

```
TIDC/
├── rtl/                           # RTL Design Files
│   ├── tidc_params.vh             # System parameters & TileLink constants
│   ├── tidc_top.v                 # Top-level system integration
│   ├── l1_tilelink_adapter.v      # L1 cache TileLink interface
│   ├── l2_tilelink_adapter.v      # L2 cache TileLink interface
│   ├── l2_request_arbiter.v       # Request arbitration logic 
│   ├── directory.v                # Directory-based coherence tracking
│   ├── source_id_manager.v        # Transaction ID management
│   └── sink_id_manager.v          # Response ID management
├── tb/                            # Testbench & Simulation
│   ├── tidc_system_tb.v           # Original testbench 
│   ├── tidc_system_tb_verilator.v # Verilator-compatible testbench
│   └── main.cpp                   # C++ simulation wrapper 
├── docs/                          # Documentation
├── Makefile                       # Comprehensive build system 
└── README.md                      # This file
```

## 🔧 Building and Testing

### Prerequisites
- **Verilator** (primary simulation target)
- **GTKWave** (for waveform viewing)
- **Make** (build automation)

### Quick Start
```bash
# Build and run simulation
make sim

# Build and view waveforms
make waves

# Run lint check
make lint

# Clean build files
make clean
```

### Available Make Targets

| Target | Description |
|--------|-------------|
| `make sim` | Build and run Verilator simulation |
| `make waves` | Run simulation and open GTKWave |
| `make lint` | Run Verilator lint check |
| `make clean` | Clean all build artifacts |
| `make help` | Show available targets |


## Test Scenarios

The testbench validates basic TileLink protocol transactions:

### Test Sequence
1. **L1_0 Read Miss (NtoB)** → ADDR_A → Shared access
2. **L1_1 Read Miss (NtoB)** → ADDR_A → Shared access (coherence)  
3. **L1_0 Write Miss (NtoT)** → ADDR_B → Exclusive access
4. **L1_2 Read Miss (NtoB)** → ADDR_C → Independent access

### Expected Results
- ✅ Successful TileLink handshakes on all channels
- ✅ Correct data patterns returned (0xFF...FF, 0xFF...00, alternating)
- ✅ Proper coherence state transitions
- ✅ Directory updates reflecting cache line ownership

## System Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `NUM_L1_CACHES` | 4 | Number of L1 cache interfaces |
| `WDATA` | 8 bytes | TileLink data width |
| `WADDR` | 32 bits | Address width |
| `CACHE_LINE_BITS` | 256 bits | Cache line size |
| `WSOURCE` | 4 bits | Source ID width (16 IDs) |
| `WSINK` | 4 bits | Sink ID width (16 IDs) |

## TileLink Protocol Implementation

### Supported Operations
- **Channel A**: `AcquireBlock`, `Get`, `PutFullData`
- **Channel B**: `ProbeBlock`  
- **Channel C**: `ProbeAck`, `ProbeAckData`, `Release`, `ReleaseData`
- **Channel D**: `Grant`, `GrantData`, `ReleaseAck`, `AccessAck`, `AccessAckData`
- **Channel E**: `GrantAck`

### Permission States
- **None (N)**: No access permissions
- **Branch/Shared (B)**: Read-only access, shareable
- **Tip/Exclusive (T)**: Read-write exclusive access

### State Transitions
- **NtoB**: None → Branch (read miss)
- **NtoT**: None → Tip (write miss)  
- **BtoT**: Branch → Tip (upgrade)
- **TtoB**: Tip → Branch (downgrade)
- **TtoN**: Tip → None (invalidate)
- **BtoN**: Branch → None (invalidate)

## Waveform Analysis

Generated VCD files include comprehensive signal tracking:
- TileLink channel handshakes (valid/ready)
- Request/response data payloads
- Directory state transitions
- Arbitration decisions
- Source/Sink ID allocation

## Future Enhancements

- **Performance Monitoring**: Transaction latency counters
- **Advanced Directory**: Configurable replacement policies  
- **Atomic Operations**: TileLink atomic message support
- **Multi-Level Hierarchy**: L3 cache integration
- **Enhanced Testing**: Randomized transaction patterns

## Contributing

This is a reference implementation demonstrating TileLink coherence protocols. Contributions welcome for:
- Additional test scenarios
- Performance optimizations  
- Protocol extensions
- Documentation improvements
