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

```text
             ┌───────────────────────┐
operand_a ──►│                       │
operand_b ──►│       64-bit ALU      │──► result[63:0]
cmd[3:0] ───►│                       │──► carry_out
carry_in ───►│   Arithmetic / Logic  │──► zero_flag
             │   Shift / Compare     │──► negative_flag
             │                       │──► overflow_flag
             └───────────────────────┘
