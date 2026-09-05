`timescale 1ns/1ps

module alu64_cp_core (
    input  logic [63:0] operand_a,
    input  logic [63:0] operand_b,
    input  logic [3:0]  cmd,
    input  logic        carry_in,

    output logic [63:0] result,
    output logic        carry_out,
    output logic        overflow_flag
);

    logic [64:0] arithmetic_ext;
    logic [64:0] subtract_ext;

    logic [5:0] shift_amount;

    /*
     * V11:
     *
     * Conservative optimization based on the proven V2/V3
     * implementation.
     *
     * Main target:
     *   - keep the single opcode-controlled datapath
     *   - avoid parallel full-width operation datapaths
     *   - simplify the arithmetic cases
     *   - keep the result[63] cone as close as possible to
     *     the selected operation
     *
     * Zero/negative flags are intentionally not generated here.
     * The pipeline derives them from the registered result.
     */

    always_comb begin

        result        = 64'd0;
        carry_out     = 1'b0;
        overflow_flag = 1'b0;

        arithmetic_ext = 65'd0;
        subtract_ext   = 65'd0;

        shift_amount = operand_b[5:0];

        case (cmd)

            /* =====================================================
             * ADD
             * ===================================================== */
            alu64_cp_pkg::CMD_ADD: begin

                arithmetic_ext =
                    {1'b0, operand_a} +
                    {1'b0, operand_b} +
                    carry_in;

                result = arithmetic_ext[63:0];

                carry_out = arithmetic_ext[64];

                overflow_flag =
                    (~(operand_a[63] ^ operand_b[63])) &
                    (result[63] ^ operand_a[63]);

            end


            /* =====================================================
             * SUBTRACT
             *
             * carry_out = 1 -> no unsigned borrow
             * ===================================================== */
            alu64_cp_pkg::CMD_SUB: begin

                subtract_ext =
                    {1'b0, operand_a} -
                    {1'b0, operand_b} -
                    carry_in;

                result = subtract_ext[63:0];

                /*
                 * Explicit comparison avoids using a second
                 * 65-bit arithmetic expression for borrow.
                 */
                if (carry_in)
                    carry_out = (operand_a > operand_b);
                else
                    carry_out = (operand_a >= operand_b);

                overflow_flag =
                    (operand_a[63] ^ operand_b[63]) &
                    (result[63] ^ operand_a[63]);

            end


            /* =====================================================
             * AND
             * ===================================================== */
            alu64_cp_pkg::CMD_AND: begin
                result = operand_a & operand_b;
            end


            /* =====================================================
             * OR
             * ===================================================== */
            alu64_cp_pkg::CMD_OR: begin
                result = operand_a | operand_b;
            end


            /* =====================================================
             * XOR
             * ===================================================== */
            alu64_cp_pkg::CMD_XOR: begin
                result = operand_a ^ operand_b;
            end


            /* =====================================================
             * NOT
             * ===================================================== */
            alu64_cp_pkg::CMD_NOT: begin
                result = ~operand_a;
            end


            /* =====================================================
             * SHIFT LEFT
             * ===================================================== */
            alu64_cp_pkg::CMD_SLL: begin

                result = operand_a << shift_amount;

                if (shift_amount != 0)
                    carry_out = operand_a[64 - shift_amount];

            end


            /* =====================================================
             * SHIFT RIGHT
             * ===================================================== */
            alu64_cp_pkg::CMD_SRL: begin

                result = operand_a >> shift_amount;

                if (shift_amount != 0)
                    carry_out = operand_a[shift_amount - 1];

            end


            /* =====================================================
             * ARITHMETIC SHIFT RIGHT
             * ===================================================== */
            alu64_cp_pkg::CMD_SRA: begin

                result = $signed(operand_a) >>> shift_amount;

                if (shift_amount != 0)
                    carry_out = operand_a[shift_amount - 1];

            end


            /* =====================================================
             * COMPARE EQUAL
             *
             * Boolean result is naturally zero-extended.
             * ===================================================== */
            alu64_cp_pkg::CMD_CMP_EQ: begin

                result = 64'd0;

                if (operand_a == operand_b)
                    result[0] = 1'b1;

            end


            /* =====================================================
             * COMPARE LESS THAN - SIGNED
             * ===================================================== */
            alu64_cp_pkg::CMD_CMP_LT: begin

                result = 64'd0;

                if ($signed(operand_a) < $signed(operand_b))
                    result[0] = 1'b1;

            end


            /* =====================================================
             * COMPARE GREATER THAN - SIGNED
             * ===================================================== */
            alu64_cp_pkg::CMD_CMP_GT: begin

                result = 64'd0;

                if ($signed(operand_a) > $signed(operand_b))
                    result[0] = 1'b1;

            end


            /* =====================================================
             * INCREMENT
             * ===================================================== */
            alu64_cp_pkg::CMD_INC: begin

                arithmetic_ext =
                    {1'b0, operand_a} + 65'd1;

                result = arithmetic_ext[63:0];

                carry_out = arithmetic_ext[64];

                overflow_flag =
                    (~operand_a[63]) & result[63];

            end


            /* =====================================================
             * DECREMENT
             * ===================================================== */
            alu64_cp_pkg::CMD_DEC: begin

                subtract_ext =
                    {1'b0, operand_a} - 65'd1;

                result = subtract_ext[63:0];

                carry_out = (operand_a != 64'd0);

                overflow_flag =
                    operand_a[63] & ~result[63];

            end


            /* =====================================================
             * PASS A
             * ===================================================== */
            alu64_cp_pkg::CMD_PASS_A: begin
                result = operand_a;
            end


            /* =====================================================
             * PASS B
             * ===================================================== */
            alu64_cp_pkg::CMD_PASS_B: begin
                result = operand_b;
            end


            /* =====================================================
             * DEFAULT
             * ===================================================== */
            default: begin

                result        = 64'd0;
                carry_out     = 1'b0;
                overflow_flag = 1'b0;

            end

        endcase

    end

endmodule
