# Designing and Optimizing a 5-Stage Pipelined 64-Bit ALU from RTL to GDSII

A complete digital ASIC design project implementing a **64-bit Arithmetic Logic Unit (ALU)** and taking the design through RTL development, functional verification, FPGA-oriented synthesis, ASIC synthesis, physical design, timing analysis, physical verification, and final **GDSII generation** using the **SkyWater SKY130A** open-source technology.

The main design in this project is **`alu64_cp`**, a clocked and 5-stage pipelined 64-bit ALU developed as the next stage of the original non-clocked, non-pipelined `alu64` design.

---

## 1. Project Overview

The project was developed as a complete **RTL-to-GDSII digital ASIC flow**. The work started with a conventional combinational 64-bit ALU (`alu64`) to establish the basic functionality and architecture. The design was then developed into **`alu64_cp` — Clocked & Pipelined 64-bit ALU**

The pipelined design introduces:

- Synchronous clocking
- Active-low synchronous reset
- Five-stage pipeline architecture
- Valid transaction propagation
- Registered ALU outputs
- Timing-aware ASIC implementation
- Physical design using Sky130A
- Post-route static timing analysis
- Physical verification
- Final GDSII generation

The objective was not only to implement the ALU functionality, but to demonstrate a complete hardware implementation flow from **RTL source code to a manufacturable layout database**.

---

## 2. Design Flow

The overall project flow was:

```text
ALU Specification
       │
       ▼
64-bit Combinational ALU
       │
       ▼
Clocked & Pipelined ALU
       │
       ▼
RTL Functional Verification
       │
       ▼
Randomized Verification
       │
       ▼
Vivado Synthesis / Timing / Power
       │
       ▼
ASIC Top-Level Integration
       │
       ▼
SDC Timing Constraints
       │
       ▼
Yosys Synthesis
       │
       ▼
LibreLane + SKY130A
       │
       ▼
Floorplanning
       │
       ▼
Placement
       │
       ▼
Clock Tree Synthesis
       │
       ▼
Global Routing
       │
       ▼
Detailed Routing
       │
       ▼
Antenna Repair
       │
       ▼
DRC / LVS / Antenna / Power Grid
       │
       ▼
Post-Route STA
       │
       ▼
GDSII
```

---

# 3. ALU Specification

The ALU operates on two 64-bit operands:

```
operand_a[63:0]
operand_b[63:0]
```

and uses a 4-bit command:

```
cmd[3:0]
```

The complete operation set contains 16 instructions.

| OpcodeOperation |                        |
| --------------- | ---------------------- |
| `0000`          | ADD                    |
| `0001`          | SUBTRACT               |
| `0010`          | AND                    |
| `0011`          | OR                     |
| `0100`          | XOR                    |
| `0101`          | NOT                    |
| `0110`          | SHIFT LEFT             |
| `0111`          | SHIFT RIGHT            |
| `1000`          | ARITHMETIC SHIFT RIGHT |
| `1001`          | COMPARE EQUAL          |
| `1010`          | COMPARE LESS           |
| `1011`          | COMPARE GREATER        |
| `1100`          | INCREMENT              |
| `1101`          | DECREMENT              |
| `1110`          | PASS A                 |
| `1111`          | PASS B                 |

The ALU also supports:

-  Carry input 
-  Carry output 
-  Zero flag 
-  Negative flag 
-  Signed overflow flag 
-  Signed comparison operations 

---

# 4. `alu64_cp` Architecture

The main design is a **five-stage pipelined 64-bit ALU**.

```
                ┌──────────────────────────┐
operand_a ─────►│                          │
operand_b ─────►│        Stage 1           │
cmd ───────────►│      Input Capture       │
carry_in ──────►│                          │
                └────────────┬─────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │        Stage 2           │
                │   Operand / Command      │
                │        Registers          │
                └────────────┬─────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │        ALU Core           │
                │ Arithmetic / Logic /      │
                │ Shift / Compare / Pass    │
                └────────────┬─────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │        Stage 3           │
                │   Result / Carry /       │
                │      Overflow Registers   │
                └────────────┬─────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │        Stage 4           │
                │     Flag Generation      │
                │   Zero / Negative        │
                └────────────┬─────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │        Stage 5           │
                │      Output Registers    │
                └────────────┬─────────────┘
                             │
                             ▼
                    Registered Outputs
```

> The pipeline provides a fixed latency of **5 clock cycles**

> The `valid_in` signal travels through the pipeline together with the transaction and produces `valid_out` at the corresponding output cycle.

---

## 5. Pipeline Interface

### Inputs

```
clk
rst_n
valid_in

operand_a[63:0]
operand_b[63:0]

cmd[3:0]
carry_in
```

### Outputs

```
valid_out

result[63:0]
carry_out
zero_flag
negative_flag
overflow_flag
```

The reset is:

> **Active-low synchronous reset**

During reset, pipeline state, valid state, and registered outputs are cleared.

---

# 6. ALU Core Operations

### Arithmetic

The arithmetic datapath implements:

-  Addition 
-  Subtraction 
-  Increment 
-  Decrement 

Carry handling is explicitly defined for unsigned arithmetic.

For subtraction and decrement, the carry output represents the **no-borrow condition**.

Signed overflow detection is implemented for operations where signed overflow is meaningful.

---

### Logic

The ALU implements:

```
AND
OR
XOR
NOT
```

These operations produce a 64-bit result.

---

### Shift Operations

Three shift operations are supported:

```
Shift Left
Logical Shift Right
Arithmetic Shift Right
```

The shift amount is derived from the lower six bits of `operand_b`.

This allows all shift distances from:

```
0 through 63
```

---

### Comparisons

The ALU implements:

```
Equal
Less Than
Greater Than
```

The less-than and greater-than operations use **signed comparison semantics**.

Comparison results are represented through the ALU result and associated flags.

---

### Pass Operations

Two direct data-transfer operations are provided:

```
PASS A
PASS B
```

These allow either input operand to be forwarded directly to the result.

---

# 7. Verification

Verification was performed at multiple levels.

## Package Verification

The opcode package was checked to ensure that all 16 command encodings map correctly to the specified operations.

---

## ALU Core Verification

The combinational ALU core was tested for:

-  All 16 operations 
-  Arithmetic correctness 
-  Carry behavior 
-  Overflow behavior 
-  Shift behavior 
-  Signed comparisons 
-  Pass operations 
-  Flag generation 

---

## Pipeline Verification

The pipeline testbench verifies:

-  Five-cycle latency 
-  Transaction ordering 
-  Pipeline valid propagation 
-  Reset behavior 
-  Output correctness 
-  Bubble handling 

---

## Randomized Verification

A deterministic randomized verification environment was also used.

The randomized tests exercised:

-  Multiple operand combinations 
-  All 16 ALU operations 
-  Carry-in variations 
-  Pipeline bubbles 
-  Reset behavior 
-  Result ordering 
-  Carry flags 
-  Zero flag 
-  Negative flag 
-  Overflow flag 

The final randomized verification completed successfully with:

```
Transactions generated : 1007
Checks generated       : 1184
Passed                 : 1184
Failed                 : 0

ALU64_CP Step 6 randomized verification: PASS
```

---

# 8. RTL Simulation

The RTL was simulated using:

```
Icarus Verilog
```

with SystemVerilog support enabled using:

```
-g2012
```

Example verification flow:

```
iverilog -g2012 \
  -o /tmp/alu64_cp_core_tb \
  src/alu64_cp_pkg.sv \
  src/alu64_cp_core.sv \
  tb/alu64_cp_core_tb.sv

vvp /tmp/alu64_cp_core_tb
```

Equivalent tests were performed for:

-  Core 
-  Pipeline 
-  Top-level design 

---

# 9. FPGA-Oriented Verification and Analysis

The design was also taken through:

> **Xilinx Vivado 2025.1**

Target device:

```
xc7a200tfbg676-2
```

Vivado was used for:

-  RTL synthesis 
-  Resource utilization 
-  Timing analysis 
-  Power estimation 

The design synthesized successfully with approximately:

```
1181 LUTs
489 FFs
0 BRAM
0 DSP
```

At the 100 MHz analysis point, the design showed positive setup and hold timing margins in Vivado.

Vivado power analysis reported approximately:

```
Total On-Chip Power : 0.190 W
Dynamic Power       : 0.059 W
Static Power        : 0.131 W
```

The power estimate was vectorless, so the reported confidence was low.

---

# 10. ASIC Implementation

After RTL and FPGA-oriented verification, the design was prepared for ASIC implementation.

The ASIC flow used:

```
Yosys
LibreLane 3.0.11
OpenROAD
SkyWater SKY130A
sky130_fd_sc_hd
```

The implementation was executed under:

```
Ubuntu / WSL
```

with the LibreLane environment running inside Docker.

The Docker image used was:


```
ghcr.io/librelane/librelane:3.0.11
```

The PDK was supplied through the CIEL installation.

---

# 11. ASIC Synthesis

Yosys was used to synthesize the RTL and map it to the Sky130 standard-cell library.

The synthesis flow included:


```
RTL elaboration
    ↓
Process conversion
    ↓
Logic optimization
    ↓
FSM processing
    ↓
Memory processing
    ↓
Technology mapping
    ↓
ABC optimization
    ↓
Sky130 standard-cell mapping
```

The final V11 RTL synthesized to approximately:

```
Total cells       : 3753
Sequential cells  : 471
Combinational     : 3282
```

The synthesized design was then used as the basis for physical implementation.

---

# 12. Timing Constraints

A dedicated SDC file was created for the ASIC implementation.

The main clock constraint is:

```
Clock period : 10 ns
Frequency    : 100 MHz
```

The constraint file includes:

-  Clock definition 
-  Clock uncertainty 
-  Clock transition 
-  Input delays 
-  Output delays 
-  Reset timing constraints 

The custom SDC was integrated into both:

```
PNR_SDC_FILE
SIGNOFF_SDC_FILE
```

This ensured that the physical implementation and signoff timing analysis used the project-specific constraints.

---

# 13. Physical Design Flow

The final `alu64_cp` design was taken through the complete physical implementation flow.

### Floorplanning

The final implementation used an absolute die size of:

```
350 µm × 350 µm
```

giving:

```
Die area = 122,500 µm²
```

### Placement

Standard cells were placed within the core region. Timing-aware physical optimization was used during implementation where appropriate.

### Clock Tree Synthesis

A clock tree was generated for the registered five-stage pipeline. Clock distribution and skew were analyzed during the physical implementation flow.

### Global Routing

The design was globally routed and congestion was evaluated.

### Detailed Routing

Detailed routing was performed after global routing. The final routed design was successfully completed and produced the required physical database.

### Antenna Repair

Antenna checking and repair were performed during the physical flow. The final design passed antenna verification.

---

# 14. Final Physical Results

The official frozen final implementation is:

```
RUN_2026-09-05_10-52-32
```

The final physical results are approximately:

| ParameterFinal Result |              |
| --------------------- | ------------ |
| RTL                   | V11          |
| Pipeline              | 5-stage      |
| Latency               | 5 cycles     |
| Die Size              | 350 × 350 µm |
| Die Area              | 122,500 µm²  |
| Instance Area         | 110,506 µm²  |
| Standard-cell Area    | 53,035.9 µm² |
| Total Power           | 6.162 mW     |
| Route Wirelength      | 217,570 µm   |
| Route Vias            | 38,822       |
| Setup WNS             | -4.812 ns    |
| Setup TNS             | -190.529 ns  |
| Hold WNS              | 0 ns         |
| DRC                   | PASS         |
| LVS                   | PASS         |
| Antenna               | PASS         |
| Power Grid            | PASS         |
| GDSII                 | Generated    |

---

# 15. Static Timing Analysis

Post-route STA was performed using the physical implementation flow.

The final implementation achieved:

```
Hold timing:
PASS
```

with no hold violations. The 10 ns setup target, however, was not fully closed.

Final worst-case setup result:

```
WNS = -4.811867 ns
TNS = -190.528544 ns
```

The worst setup path is primarily associated with the result-generation logic between the second and third pipeline stages.

The critical path contains a deep Boolean/multiplexer network involving:

-  Operand bits 
-  Opcode decode 
-  Result selection 
-  Arithmetic/logic selection 
-  Shift/compare logic 

The post-route analysis indicates that the design's main timing limitation is the depth and fanout of this combinational result-generation cone rather than clock skew.

The corresponding minimum clock period is approximately:

```
14.81 ns
```

or approximately:

```
67.5 MHz
```

based on the worst setup path. Therefore, the final physical design is:

> **Functionally verified and physically signoff-clean, but not setup-timing closed at the 100 MHz target.**

This timing limitation is explicitly retained in the project results rather than hidden or overstated.

---

# 16. Physical Verification

The final physical design was checked using multiple verification stages.

## DRC

Design Rule Checking was completed successfully. ` DRC: PASS`

## LVS

Layout-versus-schematic verification was completed successfully. The final LVS result reported `Circuits match uniquely.` Therefore `LVS: PASS`

## Antenna

Antenna verification was completed successfully. Final antenna verification showed 

```
Violating nets : 0
Violating pins : 0
```

Therefore `Antenna: PASS`

## Power Grid

The power-grid analysis completed without reported violations. The final IR-drop analysis showed approximately:

```
VPWR worst drop : 0.594 mV
VGND worst drop : 0.493 mV
```

Both correspond to approximately `0.03%` of the nominal supply.

---

# 17. Final GDSII

The physical implementation successfully generated the final GDSII layout. Official final GDS:

```
runs/RUN_2026-09-05_10-52-32/final/gds/alu64_cp_top.gds
```

The final implementation also contains related physical-design views including:

```
DEF
GDS
LEF
SPICE
Netlists
KLayout GDS
Magic GDS
```

These files are retained as part of the final ASIC implementation data.

---

# 18. Final Layout

The generated GDSII can be viewed using `KLayout`

The final layout contains the complete physical implementation of `alu64_cp_top`

including:

-  Standard cells 
-  Routing 
-  Power structures 
-  Clock network 
-  Input/output connectivity 
-  Physical hierarchy 
-  Technology layers 

### Final GDSII Layout

> **[Insert KLayout screenshot here]**

 \<br> 

```
[ PROJECT IMAGE / KLAYOUT SCREENSHOT ]
```

---

# 19. Recommended Project Images

The following screenshots can be added to document the implementation visually.

### RTL / Architecture

> **[Insert 5-stage pipeline architecture diagram here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### RTL Simulation

> **[Insert RTL simulation waveform here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### Vivado Results

> **[Insert Vivado utilization/timing screenshot here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### ASIC Floorplan

> **[Insert floorplan screenshot here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### Placement

> **[Insert placement screenshot here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### Routing

> **[Insert routed layout screenshot here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

### Final GDSII

> **[Insert final KLayout GDSII screenshot here]**

 \<br> 

```
[ IMAGE PLACEHOLDER ]
```

---

# 20. Automation Scripts

The project includes reusable Python, Tcl, Yosys, and LibreLane scripts. The script collection is organized as:

```
scripts/
├── python/
│   ├── run_rtl_verify.py
│   ├── run_yosys.py
│   └── collect_ppa.py
│
├── tcl/
│   ├── vivado_create_project.tcl
│   └── vivado_synth_reports.tcl
│
├── yosys/
│   └── synth.ys
│
└── librelane/
    └── config_v11_final.yaml
```

These scripts are intended to make the project easier to reproduce and maintain.

---

# 21. Python Automation

Python scripts are used for:

-  RTL verification automation 
-  Yosys synthesis automation 
-  PPA report extraction 
-  Reproducible project execution 

Example: `python3 scripts/python/run_rtl_verify.py`

Yosys automation: `python3 scripts/python/run_yosys.py`

PPA collection: `python3 scripts/python/collect_ppa.py <LibreLane-run-directory>`

---

# 22. Vivado Tcl Automation

Vivado Tcl scripts are provided for:

### Project creation

```
scripts/tcl/vivado_create_project.tcl
```

### Synthesis and reports

```
scripts/tcl/vivado_synth_reports.tcl
```

This allows the Vivado project and synthesis reports to be generated without manually recreating the project setup.

---

# 23. Yosys Automation

The Yosys synthesis script is located at: `scripts/yosys/synth.ys`
It contains the synthesis flow used to elaborate and map the RTL to the Sky130 standard-cell library.

---

# 24. LibreLane Configuration

The final ASIC implementation configuration is maintained under: `scripts/librelane/config_v11_final.yaml`

The configuration defines:

-  Design name 
-  RTL source files 
-  PDK 
-  Standard-cell library 
-  Clock port 
-  Clock period 
-  Synthesis strategy 
-  Physical die dimensions 
-  PNR SDC 
-  Signoff SDC 
-  Post-global-route timing optimization

---

# 25. Tools and Technologies

| CategoryTool / Technology |                          |
| ------------------------- | ------------------------ |
| RTL                       | SystemVerilog            |
| RTL Simulation            | Icarus Verilog           |
| FPGA Synthesis            | Xilinx Vivado 2025.1     |
| FPGA Target               | XC7A200T                 |
| ASIC Synthesis            | Yosys                    |
| ASIC Flow                 | LibreLane 3.0.11         |
| Physical Design           | OpenROAD                 |
| PDK                       | SkyWater SKY130A         |
| Standard Cells            | sky130\_fd\_sc\_hd       |
| Layout Viewer             | KLayout                  |
| Physical Verification     | Magic / KLayout / Netgen |
| Environment               | Ubuntu / WSL             |
| Container                 | Docker                   |

---

# 26. Final Project Status

The final status of the project is:

```
RTL Specification          COMPLETE
ALU Core                   PASS
5-Stage Pipeline           PASS
Functional Verification    PASS
Randomized Verification    PASS
Vivado Synthesis           PASS
Vivado Timing              PASS
Vivado Power               PASS

ASIC Top-Level              COMPLETE
SDC Constraints             COMPLETE
Yosys Synthesis             PASS
Floorplanning               COMPLETE
Placement                   COMPLETE
CTS                         COMPLETE
Global Routing              COMPLETE
Detailed Routing            COMPLETE
Antenna Repair              COMPLETE

DRC                         PASS
LVS                         PASS
Antenna                     PASS
Power Grid                  PASS
Hold STA                    PASS
GDSII                       GENERATED

Setup Timing @ 100 MHz      OPEN
```

---

# 27. Final Result

The project successfully demonstrates a complete **64-bit ALU RTL-to-GDSII implementation flow**.

The final `alu64_cp` design provides:

-  64-bit datapath 
-  16 ALU operations 
-  Arithmetic and logical operations 
-  Shift operations 
-  Signed comparisons 
-  Carry handling 
-  Overflow detection 
-  Status flags 
-  Five-stage pipelining 
-  Five-cycle latency 
-  Valid transaction propagation 
-  Synchronous reset 
-  ASIC synthesis 
-  Physical implementation 
-  Clock tree synthesis 
-  Global and detailed routing 
-  Antenna repair 
-  DRC verification 
-  LVS verification 
-  Antenna verification 
-  Power-grid analysis 
-  Post-route STA 
-  Final GDSII generation 

The final implementation is **physically clean and GDSII-complete**, with DRC, LVS, antenna, power-grid, and hold checks passing.

The remaining limitation is the **100 MHz setup timing target**, which is not fully closed in the final physical implementation. The critical timing paths are dominated by the deep combinational result-selection and decode logic between pipeline stages. Rather than changing the established five-stage architecture, the project preserves the verified architecture and documents the physical timing result as part of the final implementation.

---

# 29. Key Final Numbers

```
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

DRC                 : PASS
LVS                 : PASS
Antenna             : PASS
Power Grid          : 0 violations
GDSII               : GENERATED
```

---

# 30. Conclusion

This project demonstrates the progression from a basic 64-bit combinational ALU to a clocked and pipelined implementation and finally to a physically implemented ASIC layout.

The `alu64_cp` design was verified at the RTL level, synthesized using both FPGA and ASIC tools, implemented using the Sky130A technology, physically routed, and subjected to post-route physical verification.

The final result is a complete **RTL-to-GDSII 5-stage pipelined 64-bit ALU implementation** with verified functionality and clean physical signoff checks, while transparently documenting the remaining setup-timing limitation at the original 100 MHz target.

The project therefore provides a practical example of:

```
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

from a single SystemVerilog RTL design.



