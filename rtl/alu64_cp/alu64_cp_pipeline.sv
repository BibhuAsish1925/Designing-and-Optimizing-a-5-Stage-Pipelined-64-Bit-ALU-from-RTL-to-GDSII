`timescale 1ns/1ps

module alu64_cp_pipeline (
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

    // ============================================================
    // Stage 1
    // ============================================================

    logic [63:0] a_s1;
    logic [63:0] b_s1;
    logic [3:0]  cmd_s1;
    logic        carry_s1;
    logic        valid_s1;


    // ============================================================
    // Stage 2
    // ============================================================

    logic [63:0] a_s2;
    logic [63:0] b_s2;
    logic [3:0]  cmd_s2;
    logic        carry_s2;
    logic        valid_s2;


    // ============================================================
    // Combinational ALU
    // ============================================================

    logic [63:0] alu_result_comb;
    logic        alu_carry_comb;
    logic        alu_overflow_comb;


    alu64_cp_core u_alu_core (
        .operand_a     (a_s2),
        .operand_b     (b_s2),
        .cmd           (cmd_s2),
        .carry_in      (carry_s2),
        .result        (alu_result_comb),
        .carry_out     (alu_carry_comb),
        .overflow_flag (alu_overflow_comb)
    );


    // ============================================================
    // Stage 3
    // ============================================================

    logic [63:0] alu_result_s3;
    logic        alu_carry_s3;
    logic        alu_overflow_s3;
    logic        valid_s3;


    // ============================================================
    // Stage 4
    // ============================================================

    logic [63:0] result_s4;
    logic        carry_s4;
    logic        zero_s4;
    logic        negative_s4;
    logic        overflow_s4;
    logic        valid_s4;


    // ============================================================
    // Stage 5
    // ============================================================

    logic [63:0] result_s5;
    logic        carry_s5;
    logic        zero_s5;
    logic        negative_s5;
    logic        overflow_s5;
    logic        valid_s5;


    // ============================================================
    // Pipeline registers
    // ============================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            // Stage 1
            a_s1     <= 64'd0;
            b_s1     <= 64'd0;
            cmd_s1   <= 4'd0;
            carry_s1 <= 1'b0;
            valid_s1 <= 1'b0;

            // Stage 2
            a_s2     <= 64'd0;
            b_s2     <= 64'd0;
            cmd_s2   <= 4'd0;
            carry_s2 <= 1'b0;
            valid_s2 <= 1'b0;

            // Stage 3
            alu_result_s3   <= 64'd0;
            alu_carry_s3    <= 1'b0;
            alu_overflow_s3 <= 1'b0;
            valid_s3        <= 1'b0;

            // Stage 4
            result_s4   <= 64'd0;
            carry_s4    <= 1'b0;
            zero_s4     <= 1'b0;
            negative_s4 <= 1'b0;
            overflow_s4 <= 1'b0;
            valid_s4    <= 1'b0;

            // Stage 5
            result_s5   <= 64'd0;
            carry_s5    <= 1'b0;
            zero_s5     <= 1'b0;
            negative_s5 <= 1'b0;
            overflow_s5 <= 1'b0;
            valid_s5    <= 1'b0;

        end
        else begin

            // ----------------------------------------------------
            // Stage 1
            // ----------------------------------------------------

            a_s1     <= operand_a;
            b_s1     <= operand_b;
            cmd_s1   <= cmd;
            carry_s1 <= carry_in;
            valid_s1 <= valid_in;


            // ----------------------------------------------------
            // Stage 2
            // ----------------------------------------------------

            a_s2     <= a_s1;
            b_s2     <= b_s1;
            cmd_s2   <= cmd_s1;
            carry_s2 <= carry_s1;
            valid_s2 <= valid_s1;


            // ----------------------------------------------------
            // Stage 3
            // ----------------------------------------------------

            alu_result_s3   <= alu_result_comb;
            alu_carry_s3    <= alu_carry_comb;
            alu_overflow_s3 <= alu_overflow_comb;
            valid_s3        <= valid_s2;


            // ----------------------------------------------------
            // Stage 4
            // ----------------------------------------------------

            result_s4   <= alu_result_s3;
            carry_s4    <= alu_carry_s3;
            zero_s4     <= (alu_result_s3 == 64'd0);
            negative_s4 <= alu_result_s3[63];
            overflow_s4 <= alu_overflow_s3;
            valid_s4    <= valid_s3;


            // ----------------------------------------------------
            // Stage 5
            // ----------------------------------------------------

            result_s5   <= result_s4;
            carry_s5    <= carry_s4;
            zero_s5     <= zero_s4;
            negative_s5 <= negative_s4;
            overflow_s5 <= overflow_s4;
            valid_s5    <= valid_s4;

        end

    end


    // ============================================================
    // Outputs
    // ============================================================

    assign valid_out     = valid_s5;
    assign result        = result_s5;
    assign carry_out     = carry_s5;
    assign zero_flag     = zero_s5;
    assign negative_flag = negative_s5;
    assign overflow_flag = overflow_s5;

endmodule
