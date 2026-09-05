`timescale 1ns/1ps

module alu64_cp_top_tb;

    logic        clk;
    logic        rst_n;

    logic        valid_in;
    logic [63:0] operand_a;
    logic [63:0] operand_b;
    logic [3:0]  cmd;
    logic        carry_in;

    logic        valid_out;
    logic [63:0] result;
    logic        carry_out;
    logic        zero_flag;
    logic        negative_flag;
    logic        overflow_flag;

    integer tests;
    integer passed;
    integer failed;

    localparam [3:0] CMD_ADD    = 4'b0000;
    localparam [3:0] CMD_SUB    = 4'b0001;
    localparam [3:0] CMD_AND    = 4'b0010;
    localparam [3:0] CMD_OR     = 4'b0011;
    localparam [3:0] CMD_XOR    = 4'b0100;
    localparam [3:0] CMD_NOT    = 4'b0101;
    localparam [3:0] CMD_SLL    = 4'b0110;
    localparam [3:0] CMD_SRL    = 4'b0111;
    localparam [3:0] CMD_SRA    = 4'b1000;
    localparam [3:0] CMD_CMP_EQ = 4'b1001;
    localparam [3:0] CMD_CMP_LT = 4'b1010;
    localparam [3:0] CMD_CMP_GT = 4'b1011;
    localparam [3:0] CMD_INC    = 4'b1100;
    localparam [3:0] CMD_DEC    = 4'b1101;
    localparam [3:0] CMD_PASS_A = 4'b1110;
    localparam [3:0] CMD_PASS_B = 4'b1111;

    alu64_cp_top dut (
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

    always #5 clk = ~clk;

    task automatic apply_and_check;
        input [63:0] a;
        input [63:0] b;
        input [3:0]  operation;
        input        cin;
        input [63:0] expected_result;
        input        expected_carry;
        input        expected_zero;
        input        expected_negative;
        input        expected_overflow;

        begin
            @(negedge clk);

            operand_a = a;
            operand_b = b;
            cmd       = operation;
            carry_in  = cin;
            valid_in  = 1'b1;

            @(posedge clk);
            #1;

            valid_in = 1'b0;

            repeat (4) @(posedge clk);
            #1;

            tests = tests + 1;

            if ((valid_out          === 1'b1) &&
                (result             === expected_result) &&
                (carry_out          === expected_carry) &&
                (zero_flag          === expected_zero) &&
                (negative_flag      === expected_negative) &&
                (overflow_flag      === expected_overflow)) begin

                passed = passed + 1;

                $display(
                    "PASS | CMD=%b | RESULT=%016h | C=%b Z=%b N=%b V=%b",
                    operation,
                    result,
                    carry_out,
                    zero_flag,
                    negative_flag,
                    overflow_flag
                );
            end
            else begin
                failed = failed + 1;

                $display(
                    "FAIL | CMD=%b | GOT=%016h C=%b Z=%b N=%b V=%b | EXPECTED=%016h C=%b Z=%b N=%b V=%b",
                    operation,
                    result,
                    carry_out,
                    zero_flag,
                    negative_flag,
                    overflow_flag,
                    expected_result,
                    expected_carry,
                    expected_zero,
                    expected_negative,
                    expected_overflow
                );
            end
        end
    endtask

    initial begin

        clk       = 1'b0;
        rst_n     = 1'b0;
        valid_in  = 1'b0;
        operand_a = 64'b0;
        operand_b = 64'b0;
        cmd       = 4'b0;
        carry_in  = 1'b0;

        tests  = 0;
        passed = 0;
        failed = 0;

        $display("");
        $display("===============================================");
        $display("       ALU64_CP TOP-LEVEL INTEGRATION TEST");
        $display("===============================================");

        /*
         * Synchronous reset.
         */
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        /*
         * ADD
         * 10 + 20 = 30
         */
        apply_and_check(
            64'd10,
            64'd20,
            CMD_ADD,
            1'b0,
            64'd30,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * SUB
         * 50 - 20 = 30
         */
        apply_and_check(
            64'd50,
            64'd20,
            CMD_SUB,
            1'b0,
            64'd30,
            1'b1,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * AND
         */
        apply_and_check(
            64'hFFFF0000FFFF0000,
            64'h0F0F0F0F0F0F0F0F,
            CMD_AND,
            1'b0,
            64'h0F0F00000F0F0000,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * XOR
         */
        apply_and_check(
            64'hFFFF0000FFFF0000,
            64'h0F0F0F0F0F0F0F0F,
            CMD_XOR,
            1'b0,
            64'hF0F00F0FF0F00F0F,
            1'b0,
            1'b0,
            1'b1,
            1'b0
        );

        /*
         * SLL
         * 1 << 8 = 256
         */
        apply_and_check(
            64'd1,
            64'd8,
            CMD_SLL,
            1'b0,
            64'd256,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * SRA
         * -8 >>> 1 = -4
         */
        apply_and_check(
            64'hFFFFFFFFFFFFFFF8,
            64'd1,
            CMD_SRA,
            1'b0,
            64'hFFFFFFFFFFFFFFFC,
            1'b0,
            1'b0,
            1'b1,
            1'b0
        );

        /*
         * CMP_EQ
         */
        apply_and_check(
            64'h123456789ABCDEF0,
            64'h123456789ABCDEF0,
            CMD_CMP_EQ,
            1'b0,
            64'd1,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * INC
         */
        apply_and_check(
            64'd99,
            64'b0,
            CMD_INC,
            1'b0,
            64'd100,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * DEC
         */
        apply_and_check(
            64'd100,
            64'b0,
            CMD_DEC,
            1'b0,
            64'd99,
            1'b1,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * PASS A
         */
        apply_and_check(
            64'h123456789ABCDEF0,
            64'hAAAAAAAAAAAAAAAA,
            CMD_PASS_A,
            1'b0,
            64'h123456789ABCDEF0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        /*
         * PASS B
         */
        apply_and_check(
            64'h1111111111111111,
            64'h2222222222222222,
            CMD_PASS_B,
            1'b0,
            64'h2222222222222222,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        $display("");
        $display("===============================================");
        $display("          ALU64_CP TOP TEST RESULT");
        $display("===============================================");
        $display("Tests  : %0d", tests);
        $display("Passed : %0d", passed);
        $display("Failed : %0d", failed);
        $display("===============================================");

        if (failed == 0) begin
            $display("ALU64_CP top-level test: PASS");
        end
        else begin
            $display("ALU64_CP top-level test: FAIL");
        end

        $display("===============================================");
        $display("");

        $finish;
    end

endmodule
