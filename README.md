# Designing and Optimizing a 5-Stage Pipelined 64-Bit ALU from RTL to GDSII

[![Architecture](https://img.shields.io/badge/Architecture-5--Stage%20Pipeline-blue)](#)
[![HDL](https://img.shields.io/badge/HDL-SystemVerilog-purple)](#)
[![Data Width](https://img.shields.io/badge/Data%20Width-64--bit-blueviolet)](#)
[![Operations](https://img.shields.io/badge/ALU%20Operations-16-green)](#)
[![Latency](https://img.shields.io/badge/Latency-5%20Cycles-blue)](#)
[![Verification](https://img.shields.io/badge/Verification-1184%2F1184%20PASS-brightgreen)](#)
[![Synthesis](https://img.shields.io/badge/Synthesis-Yosys-orange)](#)
[![ASIC Flow](https://img.shields.io/badge/ASIC%20Flow-LibreLane%20%7C%20OpenROAD-orange)](#)
[![PDK](https://img.shields.io/badge/PDK-SKY130A-red)](#)
[![DRC](https://img.shields.io/badge/DRC-0%20Violations-brightgreen)](#)
[![LVS](https://img.shields.io/badge/LVS-PASS-brightgreen)](#)
[![Antenna](https://img.shields.io/badge/Antenna-0%20Violations-brightgreen)](#)
[![GDSII](https://img.shields.io/badge/GDSII-Generated-success)](#)

A complete **RTL-to-GDSII digital ASIC implementation** of a **64-bit ALU**, covering RTL design, functional/randomized verification, FPGA synthesis, ASIC synthesis, physical design, STA, physical verification, and GDSII generation using **SkyWater SKY130A**.

The primary design, **`alu64_cp`**, is a clocked **5-stage pipelined** version of the original combinational `alu64`.

---

# Project Overview

The project progresses from a basic 64-bit combinational ALU to a complete ASIC implementation.

### Key Features

- 64-bit datapath with 16 operations
- 5-stage pipeline with 5-cycle latency
- Synchronous clocking and active-low synchronous reset
- Valid transaction propagation
- Registered outputs and status flags
- RTL and randomized verification
- Vivado synthesis, timing, and power analysis
- Yosys + LibreLane + OpenROAD ASIC flow
- SKY130A physical implementation
- DRC, LVS, antenna, power-grid, and post-route STA
- Final GDSII generation

---

# Tools and Technologies

| CategoryTool | Technology | 
| ------------------------- | ------------------------ |
| RTL                       | SystemVerilog            |
| RTL Simulation            | Icarus Verilog           |
| FPGA Synthesis            | Xilinx Vivado 2025.1     |
| FPGA Target               | XC7A200T                 |
| ASIC Synthesis            | Yosys                    |
| ASIC Flow                 | LibreLane 3.0.11         |
| Physical Design           | OpenROAD                 |
| PDK                       | SkyWater SKY130A         |
| Standard Cells            | sky130_fd_sc_hd          |
| Layout Viewer             | KLayout                  |
| Physical Verification     | Magic / KLayout / Netgen |
| Environment               | Ubuntu / WSL             |
| Container                 | Docker                   |

---

# `alu64_cp` Architecture

The main design is a **5-stage pipelined 64-bit ALU**.

<table align="center">
  <tr>
    <td align="center">
      <img width="1536" height="1024" alt="alu64_cp" src="https://github.com/user-attachments/assets/eab71580-7b59-4e73-990d-d46a602964e3" /><br/>
      <small>Fig. `alu64_cp` Architecture</small>
    </td>
    <td align="center">
      <img width="347" height="762" alt="image" src="https://github.com/user-attachments/assets/e4195d4e-5ce5-4ce5-ad2d-11c38d307c9a" /><br/>
      <small>Fig. all 16 upcodes </small>
    </td>
  <\tr>
</table>

**Latency:** 5 clock cycles.

`valid_in` propagates with each transaction and produces the corresponding `valid_out`.

Reset: **active-low synchronous**. Pipeline state, valid state, and registered outputs are cleared during reset.

---

# ALU Core Operations

### Arithmetic

Supports ADD, SUBTRACT, INCREMENT, and DECREMENT with explicit unsigned carry handling and signed overflow detection. For subtraction/decrement, `carry_out` represents the **no-borrow condition**.

### Logic

```text
AND
OR
XOR
NOT
```

All produce 64-bit results.

### Shift

```text
Shift Left
Logical Shift Right
Arithmetic Shift Right
```

Shift amount = `operand_b[5:0]`, supporting shifts from **0–63**.

### Comparisons

```text
Equal
Less Than
Greater Than
```

Less-than and greater-than use **signed comparison semantics**.

### Pass

```text
PASS A
PASS B
```

Forwards either operand directly to the result.

---

# Verification

Verification was performed at package, ALU-core, pipeline, and randomized levels.

### Package

Verified all 16 opcode encodings.

### ALU Core

Verified:

- All 16 operations
- Arithmetic, carry, and overflow behavior
- Shifts and signed comparisons
- Pass operations
- Flag generation

### Pipeline

Verified:

- 5-cycle latency
- Transaction ordering
- Valid propagation
- Reset behavior
- Output correctness
- Bubble handling

### Randomized Verification

Tests covered operands, all operations, carry-in, bubbles, reset, ordering, and all status flags.

```text
Transactions generated : 1007
Checks generated       : 1184
Passed                 : 1184
Failed                 : 0

ALU64_CP Step 6 randomized verification: ✅ PASS
```

---

# RTL Simulation

RTL simulation used **Icarus Verilog** with SystemVerilog enabled using `-g2012`.

```bash
iverilog -g2012 \
  -o /tmp/alu64_cp_core_tb \
  src/alu64_cp_pkg.sv \
  src/alu64_cp_core.sv \
  tb/alu64_cp_core_tb.sv

vvp /tmp/alu64_cp_core_tb
```

Equivalent verification was performed for the core, pipeline, and top-level design.

---

# FPGA-Oriented Verification and Analysis

The design was synthesized and analyzed using **Xilinx Vivado 2025.1**.

Target: `xc7a200tfbg676-2`

Vivado was used for RTL synthesis, utilization, timing, and power estimation.

Approximate utilization:

```text
1181 LUTs
489 FFs
0 BRAM
0 DSP
```

At 100 MHz, setup and hold timing were positive.

Power estimate:

```text
Total On-Chip Power : 0.190 W
Dynamic Power       : 0.059 W
Static Power        : 0.131 W
```

The power estimate was vectorless with low confidence.

---

# ASIC Implementation

ASIC implementation used:

```text
Yosys
LibreLane 3.0.11
OpenROAD
SkyWater SKY130A
sky130_fd_sc_hd
```

Environment:

```text
Ubuntu / WSL
Docker
```

Docker image: `ghcr.io/librelane/librelane:3.0.11`

The PDK was supplied through the CIEL installation.

---

# ASIC Synthesis

Yosys synthesized and mapped the RTL to the Sky130 standard-cell library.

```text
RTL Elaboration
      ↓
Process Conversion
      ↓
Logic Optimization
      ↓
FSM / Memory Processing
      ↓
Technology Mapping
      ↓
ABC Optimization
      ↓
Sky130 Cell Mapping
```

Final V11 synthesis:

```text
Total cells       : 3753
Sequential cells  : 471
Combinational     : 3282
```

---

# Timing Constraints

A dedicated SDC was used for physical implementation and signoff.

```text
Clock period : 10 ns
Frequency    : 100 MHz
```

Constraints include:

- Clock definition
- Clock uncertainty and transition
- Input/output delays
- Reset timing

Applied through:

```text
PNR_SDC_FILE
SIGNOFF_SDC_FILE
```

---

# Physical Design Flow

- Floorplanning (`Die Area = 350 µm × 350 µm = 122,500 µm²`)

- Placement (Standard cells were placed within core region with timing-aware optimization where applicable ✅)

- Clock Tree Synthesis (CTS generated and analyzed the clock network for the 5-stage pipeline ✅)

- Routing (Global and detailed routing were completed successfully ✅)

- Antenna Repair (Antenna checking and repair were completed successfully ✅)

---

# Final Physical Results

Official frozen run: `RUN_2026-09-05_10-52-32`

| Parameters | Final Result | Review |
| --------------------- | ------------ | ------------ |
| RTL | V11 | Final frozen RTL candidate |
| Pipeline | 5-stage | Balanced latency and complexity |
| Latency | 5 cycles | Fixed and deterministic |
| Die Size | 350 × 350 µm | Fixed implementation die |
| Die Area | 122,500 µm² | Defined by selected die dimensions |
| Instance Area | 110,506 µm² | Final placed design area |
| Standard-cell Area | 53,035.9 µm² | Area occupied by active standard cells |
| Total Power | 6.162 mW | Low post-route power estimate |
| Route Wirelength | 217,570 µm | Final routed interconnect length |
| Route Vias | 38,822 | Final routed via count |
| Setup WNS | -4.812 ns | 100 MHz target not timing-closed |
| Setup TNS | -190.529 ns | Setup violations remain across critical paths |
| Hold WNS | 0 ns | No hold violations |
| DRC | PASS | Layout is DRC clean |
| LVS | PASS | Layout matches the synthesized netlist |
| Antenna | PASS | No antenna violations |
| Power Grid | PASS | No power-grid violations reported |
| GDSII | Generated | Final physical layout successfully exported |

---

# Static Timing Analysis

Post-route STA confirmed: `Hold timing: ✅ PASS`. No hold violations were reported.

The 100 MHz setup target remains open:

```text
WNS = -4.811867 ns
TNS = -190.528544 ns
```

The critical path is primarily between the second and third pipeline stages and contains deep Boolean/multiplexer logic involving:

- Operand bits
- Opcode decode
- Result selection
- Arithmetic/logic selection
- Shift/compare logic

The timing limitation is primarily due to **combinational depth and fanout** rather than clock skew.

Approximate minimum clock period: `14.81 ns`

Equivalent frequency: `67.5 MHz`

⚠️ **Final status:** Functionally verified and physically signoff-clean, but **100 MHz setup timing is not closed**.

---

# Physical Verification

- DRC: `DRC: ✅ PASS`

- LVS: `Circuits match uniquely. LVS: ✅ PASS`

- Antenna: `Violating nets : 0, Violating pins : 0 and Antenna: ✅ PASS`

- Power Grid: ` VPWR worst drop : 0.594 mV, VGND worst drop : 0.493 mV`. Approximately **0.03%** of nominal supply, with no reported power-grid violations.

---

# Final GDSII Layout

Final GDSII: `runs/RUN_2026-09-05_10-52-32/final/gds/alu64_cp_top.gds`

The final `alu64_cp_top` layout can be viewed using **KLayout**. It contains the complete physical implementation including standard cells, routing, power structures, clock network, I/O connectivity, hierarchy, and technology layers.
    
# Recommended Project Images

### RTL Schematic / Architecture

<table align="center">
    <tr>
    <td align="center">
      <img width="377" height="1060" alt="image" src="https://github.com/user-attachments/assets/cf1651b5-ad96-43ca-9162-99784d9e621d" /><br/>
      <small>Fig. vivado synthesis design </small>
    </td>
    <td align="center">
      <img width="500" height="1025" alt="image" src="https://github.com/user-attachments/assets/ffadcce0-f305-4315-8a81-46cfedb2a533" /><br/>
      <small>Fig. vivado implementation design </small>
    </td>
  <\tr>
</table>

---

### RTL Simulation

<table align="center">
<td align="center">
      <img width="1357" height="917" alt="image" src="https://github.com/user-attachments/assets/895f6737-8273-403e-971b-32bbc97899aa" /><br/>
      <small>Fig. alu64_cp rtl simulations</small>
    </td>
</table>

---

### Vivado Results

<table>
  <tr>
    <td align="center">
      <img width="1200" height="545" alt="power_rpt (2)" src="https://github.com/user-attachments/assets/8b59c297-d9e9-42ce-a738-41e113d99890" /><br/>
      <small>Power summary (synthesis)</small>
    </td>
    <td align="center">
      <img width="1200" height="558" alt="power_rpt (2)" src="https://github.com/user-attachments/assets/955ba506-330b-41ad-aa87-6002c778b878" /><br/>
      <small>Power summary (implementation)</small>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="1877" height="540" alt="timing_rpt (2)" src="https://github.com/user-attachments/assets/138d0041-ee02-4820-a694-cd9f1695dda4" /><br/>
      <small>Timing Summary (synthesis)</small>
    </td>
    <td align="center">
      <img width="2236" height="540" alt="timing_rpt (2)" src="https://github.com/user-attachments/assets/2cd667a6-0b92-45e9-8a98-c578f26bd7a8" /><br/>
      <small>Timing Summary (implementation)</small>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="961" height="540" alt="utilization_summary (2)" src="https://github.com/user-attachments/assets/056b3cd3-76e4-45c6-bfb3-29b4001bf615" /><br/>
      <small>Utilization summary (synthesis)</small>
    </td>
    <td align="center">
      <img width="969" height="540" alt="utilization_rpt (2)" src="https://github.com/user-attachments/assets/33b401e1-e87f-47c6-b320-a250dc66642c" /><br/>
      <small>Utilization summary (implementation)</small>
    </td>
  </tr>
</table>

---

### ASIC Floorplan

<table align="center">
<td align="center">
      <img width="883" height="887" alt="floorplanning_ss2" src="https://github.com/user-attachments/assets/e895e0f6-427e-4e12-86b0-e46482ad5faf" /><br/>
      <small>Fig. alu64_cp Floorplanning </small>
    </td>
</table>

---

### Placement

<table align="center">
<td align="center">
      <img width="934" height="887" alt="placement_ss2" src="https://github.com/user-attachments/assets/4fd39cfa-af8e-432c-a168-c8ddfb9c15e3" /><br/>
      <small>Fig. alu64_cp Placement</small>
    </td>
</table>

---

### Routing

<table align="center">
<td align="center">
      <img width="921" height="890" alt="routing_ss2" src="https://github.com/user-attachments/assets/d6ed4d1e-e8d1-4642-9c77-bfb21ca01b92" /><br/>
      <small>Fig. alu64_cp Routing</small>
    </td>
</table>

---

### Final GDSII

<table align="center">
<td align="center">
      <img width="1117" height="851" alt="layout_ss2" src="https://github.com/user-attachments/assets/14b75020-a12a-4063-bd8a-a25b78fb1325" /><br/>
      <small>Fig. alu64_cp final GDSII layout</small>
    </td>
</table>

---

# Final Project Status

```text
RTL Specification          COMPLETE
ALU Core                   ✅ PASS
5-Stage Pipeline           ✅ PASS
Functional Verification    ✅ PASS
Randomized Verification    ✅ PASS
Vivado Synthesis           ✅ PASS
Vivado Timing              ✅ PASS
Vivado Power               ✅ PASS

ASIC Top-Level             COMPLETE
SDC Constraints            COMPLETE
Yosys Synthesis            ✅ PASS
Floorplanning              COMPLETE
Placement                  COMPLETE
CTS                        COMPLETE
Global Routing             COMPLETE
Detailed Routing           COMPLETE
Antenna Repair             COMPLETE

DRC                         ✅ PASS
LVS                         ✅ PASS
Antenna                     ✅ PASS
Power Grid                  ✅ PASS
Hold STA                    ✅ PASS
GDSII                       ✅ GENERATED

Setup Timing @ 100 MHz      ⚠️ OPEN
```

---

# Final Result

The project demonstrates a complete **64-bit ALU RTL-to-GDSII flow**. The final `alu64_cp` provides:

- 64-bit datapath
- 16 ALU operations
- Arithmetic, logic, shift, and comparison operations
- Carry and overflow handling
- Status flags
- 5-stage pipelining
- 5-cycle latency
- Valid transaction propagation
- Synchronous reset
- ASIC synthesis and physical implementation
- CTS and routing
- Antenna repair
- DRC/LVS verification
- Power-grid analysis
- Post-route STA
- GDSII generation

The implementation is **functionally verified, physically clean, and GDSII-complete**. DRC, LVS, antenna, power-grid, and hold checks pass. The only open item is the **100 MHz setup target**, with critical paths dominated by the result-selection/decode logic between pipeline stages. This limitation is documented transparently as part of the final implementation.

---

# Key Final Numbers

```text
Design              : alu64_cp_top
Architecture        : 5-stage pipelined 64-bit ALU
Latency             : 5 cycles

Technology          : SkyWater SKY130A
Standard Cells      : sky130_fd_sc_hd

Die Size            : 350 × 350 µm
Die Area            : 122,500 µm²
Instance Area       : 110,506 µm²
Std-cell Area       : 53,035.9 µm²

Total Power         : ~6.162 mW

Route Wirelength    : ~217,570 µm
Route Vias          : 38,822

Setup WNS           : -4.812 ns
Setup TNS           : -190.529 ns
Hold WNS            : 0 ns

DRC                 : ✅ PASS
LVS                 : ✅ PASS
Antenna             : ✅ PASS
Power Grid          : 0 violations
GDSII               : ✅ GENERATED
```

---

# Conclusion

This project demonstrates the complete progression from a **64-bit combinational ALU** to a **clocked 5-stage pipelined ALU** and finally to a physically implemented **Sky130A ASIC layout**.

The `alu64_cp` design was verified at RTL, synthesized using FPGA and ASIC tools, physically implemented with LibreLane/OpenROAD, routed, and subjected to post-route physical verification.

The final result is a complete **RTL-to-GDSII 5-stage pipelined 64-bit ALU** with verified functionality and clean physical signoff checks, while transparently documenting the remaining 100 MHz setup-timing limitation.

```text
Digital Design
      +
RTL Verification
      +
Synthesis
      +
Physical Design
      +
Timing Analysis
      +
Physical Verification
      +
GDSII Generation
```

## ✅ Project Status

**RTL-to-GDSII Flow: COMPLETE**

**Functional Verification: PASS**

**Physical Verification: PASS**

**GDSII Generation: COMPLETE**

**100 MHz Setup Timing: ⚠️ OPEN**
