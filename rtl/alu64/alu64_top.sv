// ============================================================
// 64-BIT ALU TOP LEVEL
// ============================================================
// This module provides the system-facing interface and connects
// the external ALU signals to the verified 64-bit ALU core.
//
// The core itself is combinational. clk and rst_n are used here
// for interface/control purposes.
//
// ============================================================

module alu64_top (

    input  logic        clk,
    input  logic        rst_n,

    input  logic [63:0] operand_a,
    input  logic [63:0] operand_b,

    input  logic [3:0]  cmd,
    input  logic        carry_in,

    output logic [63:0] result,

    output logic        carry_out,
    output logic        zero_flag,
    output logic        negative_flag,
    output logic        overflow_flag

);

    // --------------------------------------------------------
    // ALU core instance
    // --------------------------------------------------------
    // Keep this connection explicit so the top-level hierarchy
    // remains easy to inspect during synthesis.
    // --------------------------------------------------------

    alu64_core u_alu64_core (

        .operand_a      (operand_a),
        .operand_b      (operand_b),

        .cmd            (cmd),
        .carry_in       (carry_in),

        .result         (result),

        .carry_out      (carry_out),
        .zero_flag      (zero_flag),
        .negative_flag  (negative_flag),
        .overflow_flag  (overflow_flag)

    );

endmodule