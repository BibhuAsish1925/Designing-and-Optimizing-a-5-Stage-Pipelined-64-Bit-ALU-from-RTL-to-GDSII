`timescale 1ns/1ps

module alu64_cp_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic [63:0] operand_a,
    input  logic [63:0] operand_b,
    input  logic [3:0]  cmd,
    input  logic        carry_in,

    output logic        valid_out,
    output logic [63:0] result,
    output logic        carry_out,
    output logic        zero_flag,
    output logic        negative_flag,
    output logic        overflow_flag
);

    alu64_cp_pipeline u_pipeline (
        .clk           (clk),
        .rst_n         (rst_n),
        .valid_in      (valid_in),
        .operand_a     (operand_a),
        .operand_b     (operand_b),
        .cmd           (cmd),
        .carry_in      (carry_in),
        .valid_out     (valid_out),
        .result        (result),
        .carry_out     (carry_out),
        .zero_flag     (zero_flag),
        .negative_flag (negative_flag),
        .overflow_flag (overflow_flag)
    );

endmodule
