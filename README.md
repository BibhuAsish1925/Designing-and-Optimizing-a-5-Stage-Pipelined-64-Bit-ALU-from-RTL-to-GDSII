# Designing and Optimizing a 5-Stage Pipelined 64-Bit ALU from RTL to GDSII

## Overview

This project presents the complete **RTL-to-GDSII implementation of a 64-bit Arithmetic Logic Unit (ALU)**, developed from SystemVerilog RTL through functional verification, FPGA analysis, ASIC synthesis, physical implementation, routing, and final layout generation.

The main objective was to build a practical digital datapath and understand how the same RTL design behaves across an FPGA-oriented flow and a standard-cell ASIC flow. The ASIC implementation targets the **Sky130A** technology using the `sky130_fd_sc_hd` standard-cell library and a Dockerized LibreLane/OpenROAD flow.

The project also focuses on practical **PPA analysis (Performance, Power, and Area)** and on understanding the effect of RTL structure, fanout, buffering, routing, and physical constraints on the final implementation.

---

## Design Specification

| Parameter | Description |
|---|---|
| **Architecture** | 64-bit ALU |
| **Data Width** | 64 bits |
| **Opcode Width** | 4 bits |
| **Operations** | 16 |
| **Inputs** | `operand_a`, `operand_b`, `cmd`, `carry_in`, `rst_n`, `clk` |
| **Outputs** | `result`, `carry_out`, `zero_flag`, `negative_flag`, `overflow_flag` |
| **RTL Language** | SystemVerilog |
| **ASIC Technology** | Sky130A |
| **Standard Cell Library** | `sky130_fd_sc_hd` |
| **FPGA Device** | `xc7a200tfbg676-2` |
| **FPGA Tool** | Vivado 2025.1 |
| **ASIC Flow** | LibreLane 3.0.11 + OpenROAD |
| **Environment** | Ubuntu/WSL2 + Docker |

---

## ALU Operations

The 4-bit command field provides 16 possible ALU operations:

| Opcode | Operation | Description |
|---|---|---|
| `0000` | ADD | 64-bit addition with carry-in |
| `0001` | SUBTRACT | 64-bit subtraction with carry-in |
| `0010` | AND | Bitwise AND |
| `0011` | OR | Bitwise OR |
| `0100` | XOR | Bitwise XOR |
| `0101` | NOT | Bitwise inversion of operand A |
| `0110` | SHIFT LEFT | Logical left shift |
| `0111` | SHIFT RIGHT | Logical right shift |
| `1000` | ARITHMETIC SHIFT | Signed right shift |
| `1001` | COMPARE EQUAL | Equality comparison |
| `1010` | COMPARE LESS | Less-than comparison |
| `1011` | COMPARE GREATER | Greater-than comparison |
| `1100` | INCREMENT | Increment operand A |
| `1101` | DECREMENT | Decrement operand A |
| `1110` | PASS A | Pass operand A |
| `1111` | PASS B | Pass operand B |

The ALU also generates arithmetic and status information through the carry, zero, negative, and overflow flags.

---

## System Architecture

The design is divided into small RTL blocks to keep the implementation easy to verify and synthesize.

<table align="center">
    <td align="center">
      <img width="1536" height="1024" alt="circuit diagram" src="https://github.com/user-attachments/assets/a817282d-197b-4dff-a462-203e9c57eeac" /><br/>
      <small> Fig. Complete System Architecture
    </td>
</table>

The RTL uses combinational ALU logic with dedicated handling for arithmetic operations, logical operations, shifts, comparisons, and status-flag generation.

The project is described as a pipelined ALU at the project level, while the final top-level implementation used for the Sky130A physical flow is effectively **combinational for timing analysis**, with no register-to-register timing paths. This distinction is important when interpreting the final timing results.

```text
             ┌───────────────────────┐
operand_a ──►│                       │
operand_b ──►│       64-bit ALU      │──► result[63:0]
cmd[3:0] ───►│                       │──► carry_out
carry_in ───►│   Arithmetic / Logic  │──► zero_flag
             │   Shift / Compare     │──► negative_flag
             │                       │──► overflow_flag
             └───────────────────────┘
```

---

## RTL Implementation

The main RTL components are:

| File | Purpose |
|---|---|
| `alu64_pkg.sv` | Shared ALU definitions and package information |
| `alu64_core.sv` | Main 64-bit ALU datapath and flag generation |
| `alu64_top.sv` | Top-level design wrapper |

The RTL was first developed and checked in **Vivado** before being transferred into the Linux-based ASIC flow.

The implementation includes arithmetic extension for carry handling, signed overflow detection, shift operations, comparison logic, and automatic zero/negative flag generation.

---

## Functional Verification

Verification was performed before physical implementation using dedicated self-checking SystemVerilog testbenches.

The verification strategy included:

- Directed tests for individual ALU operations.
- Corner-case testing for arithmetic and shift operations.
- Randomized operand and command testing.
- Automatic expected-value generation.
- Self-checking comparisons between expected and actual outputs.
- Separate package, core, and top-level verification.

### Verification Results

| Test | Result |
|---|---:|
| Package Tests | **PASS** |
| Core Verification | **2038 / 2038 PASS** |
| Top-Level Verification | **1017 / 1017 PASS** |
| Inferred Latches | **0** |
| Synthesis Check Errors | **0** |
| Lint Errors | **0** |
| Lint Warnings | **5** |

The verification environment was adapted for **Vivado XSim**, including the use of compatible deterministic randomization methods where required by the simulator.

---

## FPGA Analysis

After RTL verification, the design was analyzed in Vivado on the target FPGA device.

### Resource Utilization

| Resource | Usage |
|---|---:|
| Slice LUTs | **1061** |
| LUT as Logic | **1061** |
| Slice Registers | **0** |
| F7 Muxes | **16** |
| F8 Muxes | **4** |
| BRAM | **0** |
| DSP | **0** |
| Bonded I/O | **201** |
| CARRY4 | **87** |

The absence of registers is consistent with the final combinational ALU implementation.

---

### Vivado Power Estimate

| Metric | Result |
|---|---:|
| Total Power | **43.748 W** |
| Dynamic Power | **42.756 W** |
| Static Power | **0.992 W** |
| I/O Power | **31.815 W** |
| Junction Temperature | **106.8°C** |
| Thermal Margin | **-21.8°C** |

The FPGA power number is an implementation-specific estimate and is heavily dominated by I/O power. Therefore, it is not directly comparable with the later Sky130A ASIC power estimate.

---

# ASIC RTL-to-GDSII Flow

For the ASIC implementation, the verified RTL was moved to an Ubuntu/WSL2 environment and processed using a Dockerized **LibreLane 3.0.11** flow.

The implementation used:

```text
SystemVerilog RTL
        ↓
Yosys Synthesis
        ↓
Floorplanning
        ↓
Placement
        ↓
Timing / Fanout Repair
        ↓
Global Routing
        ↓
Detailed Routing
        ↓
Antenna Repair
        ↓
Physical Verification
        ↓
GDSII Generation
```

The Sky130A `sky130_fd_sc_hd` standard-cell library was used for mapping the synthesized design.

---

## Floorplanning and Placement

The initial floorplan was intentionally tested with a smaller die size. The first implementation encountered detailed-placement failures due to the available placement resources and utilization.

The floorplan was subsequently increased to a **250 µm × 250 µm** die, which allowed placement and subsequent routing to complete successfully.

The final implementation achieved:

| Metric | Result |
|---|---:|
| Die Size | **250 µm × 250 µm** |
| Die Area | **62,500 µm²** |
| Core Area | **53,897.9 µm²** |
| Utilization | **74.56%** |
| Total Instances | **9,085** |
| Standard Cells | **4,785** |
| Standard Cell Area | **40,188.5 µm²** |
| Macros | **0** |
| Pad Cells | **0** |
| Design I/O | **205** |

---

## Routing and Physical Optimization

The routing stage included global routing, detailed routing, timing/fanout repair, and antenna checking.

During routing, antenna violations were detected and subsequently repaired using diode insertion followed by detailed-route refinement.

### Final Routing Results

| Metric | Result |
|---|---:|
| Estimated Route Wirelength | **168,746 µm** |
| Global Route Wirelength | **295,223 µm** |
| Final Route Wirelength | **205,089 µm** |
| Route Nets | **4,117** |
| Route Vias | **41,023** |
| Final DRC Errors | **0** |
| Antenna Violating Nets | **0** |
| Antenna Diodes | **19** |

The final routed database completed with zero detailed-routing violations and clean antenna results.

---

# ASIC Power Results

The nominal post-route power report was evaluated at:

```text
nom_tt_025C_1v80
```

### Nominal Power

| Power Component | Power |
|---|---:|
| Internal | **0.2863 mW** |
| Switching | **0.4154 mW** |
| Leakage | **0.0000147 mW** |
| Clock | **0.0000098 mW** |
| **Total** | **0.7017 mW** |

This result represents the nominal post-route ASIC estimate and is fundamentally different from the FPGA power estimate because the implementation technology, cell library, voltage, routing, and I/O assumptions are different.

---

# Timing Analysis

Because the final top-level ALU implementation is combinational, there are **no register-to-register paths**. Timing was therefore analyzed using interface delays and a virtual-clock based constraint model.

### Final Timing Summary

| Metric | Result |
|---|---:|
| Hold WNS | **+16.2754 ns** |
| Hold TNS | **0 ns** |
| Hold Violations | **0** |
| Setup WNS | **-3.8183 ns** |
| Setup TNS | **-3.9432 ns** |
| Setup Violations | **5** |
| Register-to-Register Paths | **0** |

The hold analysis is clean, while setup timing still has violations. Therefore, the final physical implementation should **not be described as timing-closed**.

### Worst Setup Path

| Parameter | Result |
|---|---|
| Startpoint | `operand_b[1]` |
| Endpoint | `zero_flag` |
| Corner | `max_ss_100C_1v60` |
| Input External Delay | **8 ns** |
| Required Time | **31.75 ns** |
| Arrival Time | **35.5683 ns** |
| Worst Slack | **-3.8183 ns** |

The critical path is dominated by the large combinational logic and high-fanout buffering between the input and status/output logic. This path provides the main opportunity for future timing optimization.

---

# Physical Sign-Off Results

The final design passed the major physical verification checks.

| Check | Result |
|---|---:|
| DRC | **0 errors** |
| Magic DRC | **0 errors** |
| KLayout DRC | **0 errors** |
| LVS | **0 errors** |
| XOR Comparison | **0 differences** |
| Antenna | **0 violations** |
| Power Grid | **0 violations** |
| Critical Disconnected Pins | **0** |
| GDSII Generation | **PASS** |

These results indicate that the final physical database and extracted layout are consistent and pass the implemented physical verification checks, although setup timing still requires optimization.

---

# Final Layout Outputs

The final ASIC implementation generated the following deliverables:

| File | Description |
|---|---|
| `alu64_top.gds` | Final GDSII layout |
| `alu64_top.def` | Final routed physical database |
| `alu64_top.lef` | Abstract physical layout |
| `alu64_top.nl.v` | Gate-level netlist |
| `alu64_top.spice` | Extracted SPICE netlist |

The main final layout files are stored in:

```text
asic/reports/08_final_layout/
```

---

# Layout Preview

### Final ASIC Layout

<table align="center">
    <td align="center">
      <img width="1105" height="857" alt="layout_ss2" src="https://github.com/user-attachments/assets/e6e4560f-28f9-4feb-b58d-8c6109152b05" /><br/>
      <small> Fig. Final ASIC Layout
    </td>
</table>
        
### Additional Layout View

<table align="center">
    <td align="center">
      <img width="1917" height="1017" alt="layout_ss1" src="https://github.com/user-attachments/assets/e43d6f5b-22c6-4649-8bdd-104a0868e1f1" /><br/>
      <small> Fig. Additional Layout View window
    </td>
</table>

---

## Final PPA & Performance Metrics

The following metrics summarize the final **Sky130A post-route implementation** of the 64-bit ALU. Area, power, routing, timing, and physical sign-off results were collected from the final LibreLane/OpenROAD reports.

| Metric | Result | Description / Context |
| :--- | :--- | :--- |
| **Architecture** | **64-bit ALU** | Combinational top-level implementation |
| **Opcodes** | **16** | 4-bit command field |
| **Technology** | **Sky130A** | `sky130_fd_sc_hd` standard-cell library |
| **Die Size** | **250 × 250 µm** | Final floorplan |
| **Die Area** | **62,500 µm²** | Final physical die area |
| **Core Area** | **53,897.9 µm²** | Final core area |
| **Standard Cell Area** | **40,188.5 µm²** | Synthesized standard-cell area |
| **Total Instances** | **9,085** | Final implemented instances |
| **Standard Cells** | **4,785** | Final standard-cell count |
| **Cell Utilization** | **74.56%** | Final placement utilization |
| **Nominal ASIC Power** | **0.7017 mW** | `nom_tt_025C_1v80`, post-route |
| **Hold WNS** | **+16.2754 ns** | Hold timing margin |
| **Hold TNS** | **0 ns** | No hold violations |
| **Setup WNS** | **-3.8183 ns** | Worst setup slack |
| **Setup TNS** | **-3.9432 ns** | Total setup negative slack |
| **Setup Violations** | **5** | Timing closure not achieved |
| **Register-to-Register Paths** | **0** | Combinational top-level design |
| **Final Route Wirelength** | **205,089 µm** | Post-route wirelength |
| **Route Nets** | **4,117** | Final routed nets |
| **Route Vias** | **41,023** | Final routed vias |
| **Antenna Violations** | **0** | After antenna repair |
| **DRC Errors** | **0** | Final physical verification |
| **LVS Errors** | **0** | Layout-versus-schematic verification |
| **XOR Differences** | **0** | Layout comparison |
| **Power Grid Violations** | **0** | Final power-grid check |
| **GDSII** | **Generated** | Final `alu64_top.gds` |

> **Note:** Unlike the reference pipelined ASIC design, this implementation does not have a meaningful operating-frequency, throughput, pipeline-latency, energy/op, or clock-tree-power figure because the final top-level design is combinational and has no register-to-register timing paths. The most relevant performance metric is therefore the **interface-based setup timing**, with a current worst-case slack of **-3.8183 ns**.
---

# Project Structure

```text
├── asic/
│   ├── config.yaml
│   ├── layout_ss1.png
│   ├── layout_ss2.png
│   └── reports/
│       ├── 01_metrics/
│       ├── 02_timing/
│       ├── 03_power/
│       ├── 04_area/
│       ├── 05_routing/
│       ├── 06_ir_drop/
│       ├── 07_drc_lvs/
│       ├── 08_final_layout/
│       └── 09_summary/
│
├── rtl/
│   ├── alu64_core.sv
│   ├── alu64_pkg.sv
│   └── alu64_top.sv
│
├── tb/
│   ├── alu64_core_tb.sv
│   ├── alu64_pkg_tb.sv
│   └── alu64_top_tb.sv
│
├── scripts/
│   ├── collect_reports.py
│   └── collect_reports.tcl
│
├── vivado/
│   └── reports/
│
├── docs/
├── README.md
└── LICENSE
```

---

# Automation

Two report-collection utilities are included to organize the LibreLane outputs:

- `scripts/collect_reports.py` — Python-based report collection.
- `scripts/collect_reports.tcl` — Tcl-based report collection.

These scripts collect important timing, power, area, routing, physical-verification, and final-layout outputs into an organized report structure for easier analysis and repository management.

---

# Development Environment

The project was developed across Windows and Linux environments:

```text
Windows
   ↓
Vivado 2025.1
   ↓
WSL2 / Ubuntu
   ↓
Docker
   ↓
LibreLane 3.0.11
   ↓
Yosys + OpenROAD
   ↓
Sky130A
   ↓
GDSII
```

This setup allows the RTL to be verified using Vivado before moving the same design into an open-source ASIC implementation flow.

---

# Project Status

| Stage | Status |
|---|---|
| RTL Design | ✅ Complete |
| Functional Verification | ✅ Passed |
| Randomized Verification | ✅ Passed |
| Vivado Analysis | ✅ Complete |
| ASIC Synthesis | ✅ Complete |
| Floorplanning | ✅ Complete |
| Placement | ✅ Complete |
| Routing | ✅ Complete |
| Antenna Repair | ✅ Complete |
| DRC | ✅ Passed |
| LVS | ✅ Passed |
| IR Drop | ✅ Passed |
| GDSII Generation | ✅ Complete |
| Setup Timing Closure | ⚠️ Requires Optimization |

---

## Conclusion

This project demonstrates a complete practical flow from **64-bit SystemVerilog RTL to a routed Sky130A GDSII layout**. The design was functionally verified, synthesized, placed, routed, antenna-repaired, and physically verified with clean DRC, LVS, XOR, antenna, and power-grid checks.

The final implementation occupies **62,500 µm² of die area**, uses **74.56% utilization**, and has a nominal post-route power estimate of **0.7017 mW**.

The main remaining optimization target is **setup timing**, with a worst-case setup slack of **-3.8183 ns**. Future work can focus on reducing the critical combinational path, controlling high-fanout nets, improving buffering and routing, and exploring alternative synthesis and floorplanning strategies to improve the overall PPA.

---
