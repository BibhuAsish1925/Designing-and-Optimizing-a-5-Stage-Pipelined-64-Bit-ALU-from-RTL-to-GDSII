`timescale 1ns/1ps

module alu64_cp_core_tb;

    logic [63:0] operand_a;
    logic [63:0] operand_b;
    logic [3:0]  cmd;
    logic        carry_in;

    logic [63:0] result;
    logic        carry_out;
    logic        overflow_flag;

    integer checks;
    integer passed;
    integer failed;

    alu64_cp_core dut (
        .operand_a     (operand_a),
        .operand_b     (operand_b),
        .cmd           (cmd),
        .carry_in      (carry_in),
        .result        (result),
        .carry_out     (carry_out),
        .overflow_flag (overflow_flag)
    );

    task check_result;
        input [63:0] expected_result;
        input        expected_carry;
        input        expected_overflow;

        begin
            checks = checks + 1;

            if ((result !== expected_result) ||
                (carry_out !== expected_carry) ||
                (overflow_flag !== expected_overflow)) begin

                failed = failed + 1;

                $display("FAIL cmd=%b A=%h B=%h cin=%b",
                         cmd, operand_a, operand_b, carry_in);

                $display("     result=%h expected=%h",
                         result, expected_result);

                $display("     carry=%b expected=%b",
                         carry_out, expected_carry);

                $display("     overflow=%b expected=%b",
                         overflow_flag, expected_overflow);

            end
            else begin
                passed = passed + 1;
            end
        end
    endtask

    initial begin

        checks = 0;
        passed = 0;
        failed = 0;

        operand_a = 64'd0;
        operand_b = 64'd0;
        cmd       = 4'd0;
        carry_in  = 1'b0;

        #1;

        // 1. ADD
        operand_a = 64'd10;
        operand_b = 64'd20;
        carry_in  = 1'b0;
        cmd       = 4'b0000;
        #1;
        check_result(64'd30, 1'b0, 1'b0);

        // 2. SUB
        operand_a = 64'd50;
        operand_b = 64'd20;
        carry_in  = 1'b0;
        cmd       = 4'b0001;
        #1;
        check_result(64'd30, 1'b1, 1'b0);

        // 3. AND
        operand_a = 64'h000000000000F0F0;
        operand_b = 64'h0000000000000FF0;
        cmd       = 4'b0010;
        #1;
        check_result(64'h00000000000000F0, 1'b0, 1'b0);

        // 4. OR
        cmd = 4'b0011;
        #1;
        check_result(64'h000000000000FFF0, 1'b0, 1'b0);

        // 5. XOR
        cmd = 4'b0100;
        #1;
        check_result(64'h000000000000FF00, 1'b0, 1'b0);

        // 6. NOT
        operand_a = 64'd0;
        operand_b = 64'd0;
        cmd       = 4'b0101;
        #1;
        check_result(64'hFFFFFFFFFFFFFFFF, 1'b0, 1'b0);

        // 7. SHIFT LEFT
        operand_a = 64'd1;
        operand_b = 64'd4;
        cmd       = 4'b0110;
        #1;
        check_result(64'd16, 1'b0, 1'b0);

        // 8. SHIFT RIGHT
        operand_a = 64'd16;
        operand_b = 64'd2;
        cmd       = 4'b0111;
        #1;
        check_result(64'd4, 1'b0, 1'b0);

        // 9. ARITHMETIC SHIFT
        operand_a = 64'h8000000000000000;
        operand_b = 64'd4;
        cmd       = 4'b1000;
        #1;
        check_result(64'hF800000000000000, 1'b0, 1'b0);

        // 10. COMPARE EQUAL
        operand_a = 64'd123;
        operand_b = 64'd123;
        cmd       = 4'b1001;
        #1;
        check_result(64'd1, 1'b0, 1'b0);

        // 11. COMPARE LESS signed
        operand_a = 64'hFFFFFFFFFFFFFFFF;
        operand_b = 64'd1;
        cmd       = 4'b1010;
        #1;
        check_result(64'd1, 1'b0, 1'b0);

        // 12. COMPARE GREATER signed
        operand_a = 64'd10;
        operand_b = 64'd5;
        cmd       = 4'b1011;
        #1;
        check_result(64'd1, 1'b0, 1'b0);

        // 13. INCREMENT
        operand_a = 64'd41;
        operand_b = 64'd0;
        cmd       = 4'b1100;
        #1;
        check_result(64'd42, 1'b0, 1'b0);

        // 14. DECREMENT
        operand_a = 64'd42;
        operand_b = 64'd0;
        cmd       = 4'b1101;
        #1;
        check_result(64'd41, 1'b1, 1'b0);

        // 15. PASS A
        operand_a = 64'h123456789ABCDEF0;
        operand_b = 64'd0;
        cmd       = 4'b1110;
        #1;
        check_result(64'h123456789ABCDEF0, 1'b0, 1'b0);

        // 16. PASS B
        operand_a = 64'd0;
        operand_b = 64'hFEDCBA9876543210;
        cmd       = 4'b1111;
        #1;
        check_result(64'hFEDCBA9876543210, 1'b0, 1'b0);

        // Additional zero-result test
        operand_a = 64'd0;
        operand_b = 64'd0;
        carry_in  = 1'b0;
        cmd       = 4'b0000;
        #1;
        check_result(64'd0, 1'b0, 1'b0);

        // Additional negative-result test
        operand_a = 64'h8000000000000000;
        operand_b = 64'd0;
        cmd       = 4'b1110;
        #1;
        check_result(64'h8000000000000000, 1'b0, 1'b0);

        $display("");
        $display("Checks generated : %0d", checks);
        $display("Passed           : %0d", passed);
        $display("Failed           : %0d", failed);

        if (failed == 0)
            $display("ALU64_CP V8 core verification: PASS");
        else
            $display("ALU64_CP V8 core verification: FAIL");

        $finish;

    end

endmodule
