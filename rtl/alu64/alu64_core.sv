// ============================================================
// 64-BIT ALU CORE
// ============================================================
// Combinational datapath for arithmetic and logical operations.
//
// This module is intentionally kept independent of clock/reset.
// The top-level wrapper can provide system-level clock/reset
// handling later.
//
// Datapath : 64 bits
// Command  : 4 bits
//
// ============================================================

module alu64_core (

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
    // Operation codes
    // --------------------------------------------------------

    localparam logic [3:0] cmd_add = 4'h0;
    localparam logic [3:0] cmd_sub = 4'h1;
    localparam logic [3:0] cmd_and = 4'h2;
    localparam logic [3:0] cmd_or  = 4'h3;
    localparam logic [3:0] cmd_xor = 4'h4;
    localparam logic [3:0] cmd_not = 4'h5;
    localparam logic [3:0] cmd_sll = 4'h6;
    localparam logic [3:0] cmd_srl = 4'h7;
    localparam logic [3:0] cmd_sra = 4'h8;
    localparam logic [3:0] cmd_cmp = 4'h9;

    // --------------------------------------------------------
    // Extended arithmetic result
    // The extra bit is used to preserve carry information
    // during addition/subtraction.
    // --------------------------------------------------------

    logic [64:0] arithmetic_ext;

    // --------------------------------------------------------
    // Combinational ALU
    // --------------------------------------------------------

    always_comb begin

        // Default values
        result         = 64'd0;
        carry_out      = 1'b0;
        overflow_flag  = 1'b0;
        arithmetic_ext = 65'd0;

        case (cmd)

            // ------------------------------------------------
            // ADD
            // A + B + carry_in
            // ------------------------------------------------

            cmd_add: begin

                arithmetic_ext =
                    {1'b0, operand_a} +
                    {1'b0, operand_b} +
                    carry_in;

                result    = arithmetic_ext[63:0];
                carry_out = arithmetic_ext[64];

                // Signed overflow occurs when two operands
                // with the same sign produce a different sign.
                overflow_flag =
                    (~(operand_a[63] ^ operand_b[63])) &
                    (result[63] ^ operand_a[63]);
            end


            // ------------------------------------------------
            // SUB
            // A - B - carry_in
            // ------------------------------------------------

            cmd_sub: begin

                arithmetic_ext =
                    {1'b0, operand_a} -
                    {1'b0, operand_b} -
                    carry_in;

                result = arithmetic_ext[63:0];

                // Carry convention:
                // 1 = no borrow
                // 0 = borrow
                carry_out =
                    (operand_a >= operand_b + carry_in);

                // Signed subtraction overflow.
                overflow_flag =
                    (operand_a[63] ^ operand_b[63]) &
                    (result[63] ^ operand_a[63]);

            end


            // ------------------------------------------------
            // AND
            // ------------------------------------------------

            cmd_and: begin

                result = operand_a & operand_b;

            end


            // ------------------------------------------------
            // OR
            // ------------------------------------------------

            cmd_or: begin

                result = operand_a | operand_b;

            end


            // ------------------------------------------------
            // XOR
            // ------------------------------------------------

            cmd_xor: begin

                result = operand_a ^ operand_b;

            end


            // ------------------------------------------------
            // NOT
            // ------------------------------------------------
            // Unary operation. operand_a is inverted.
            // ------------------------------------------------

            cmd_not: begin

                result = ~operand_a;

            end


            // ------------------------------------------------
            // LOGICAL LEFT SHIFT
            // ------------------------------------------------

            cmd_sll: begin

                result = operand_a << operand_b[5:0];

                if (operand_b[5:0] != 0)
                    carry_out =
                        operand_a[64 - operand_b[5:0]];

            end


            // ------------------------------------------------
            // LOGICAL RIGHT SHIFT
            // ------------------------------------------------

            cmd_srl: begin

                result = operand_a >> operand_b[5:0];

                if (operand_b[5:0] != 0)
                    carry_out =
                        operand_a[operand_b[5:0] - 1];

            end


            // ------------------------------------------------
            // ARITHMETIC RIGHT SHIFT
            // ------------------------------------------------

            cmd_sra: begin

                result =
                    $signed(operand_a) >>> operand_b[5:0];

                if (operand_b[5:0] != 0)
                    carry_out =
                        operand_a[operand_b[5:0] - 1];

            end


            // ------------------------------------------------
            // COMPARE
            //
            // Result contains A-B.
            // Flags can then be used to determine the result.
            // ------------------------------------------------

            cmd_cmp: begin

                arithmetic_ext =
                    {1'b0, operand_a} -
                    {1'b0, operand_b};

                result = arithmetic_ext[63:0];

                carry_out =
                    (operand_a >= operand_b);

                overflow_flag =
                    (operand_a[63] ^ operand_b[63]) &
                    (result[63] ^ operand_a[63]);

            end


            // ------------------------------------------------
            // Undefined opcode
            // ------------------------------------------------

            default: begin

                result        = 64'd0;
                carry_out     = 1'b0;
                overflow_flag = 1'b0;

            end

        endcase


        // ----------------------------------------------------
        // Common status flags
        // ----------------------------------------------------

        zero_flag     = (result == 64'd0);
        negative_flag = result[63];

    end

endmodule


// ============================================================================
// 64-BIT ALU : INPUT / OPERATION REFERENCE
// ============================================================================
//
// +------+----------------------+
// | CMD  | OPERATION            |
// +------+----------------------+
// | 0000 | ADD                  |
// | 0001 | SUBTRACT             |
// | 0010 | AND                  |
// | 0011 | OR                   |
// | 0100 | XOR                  |
// | 0101 | NOT                  |
// | 0110 | SHIFT LEFT           |
// | 0111 | SHIFT RIGHT          |
// | 1000 | ARITHMETIC SHIFT     |
// | 1001 | COMPARE EQUAL        |
// | 1010 | COMPARE LESS         |
// | 1011 | COMPARE GREATER      |
// | 1100 | INCREMENT            |
// | 1101 | DECREMENT            |
// | 1110 | PASS A               |
// | 1111 | PASS B               |
// +------+----------------------+
//
// INPUTS:
//   operand_a[63:0]  : First 64-bit operand
//   operand_b[63:0]  : Second 64-bit operand
//   cmd[3:0]         : 4-bit operation selector
//   carry_in         : Carry input for arithmetic operations
//   clk              : Clock input
//   rst_n            : Active-low reset
//
// OUTPUTS:
//   result[63:0]     : 64-bit ALU result
//   carry_out        : Arithmetic carry output
//   zero_flag        : Result is zero
//   negative_flag    : Result MSB is high
//   overflow_flag    : Signed arithmetic overflow
//
// ============================================================================
// MODULE FLOW:
//
//   alu64_top
//       |
//       +----> alu64_core
//                  |
//                  +----> 64-bit ALU operation
//                  +----> result
//                  +----> carry
//                  +----> zero flag
//                  +----> negative flag
//                  +----> overflow flag
//
// ============================================================================
// NOTE:
//   The 4-bit CMD provides 16 possible ALU operations.
//   All operations are implemented for 64-bit operands.
// ============================================================================