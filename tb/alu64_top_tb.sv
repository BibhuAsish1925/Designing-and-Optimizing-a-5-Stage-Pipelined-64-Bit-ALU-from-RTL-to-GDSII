// ============================================================
// 64-BIT ALU TOP-LEVEL TESTBENCH
// ============================================================
// This testbench verifies the complete top-level connectivity.
//
// The ALU core was already verified independently. Here we check
// that the top-level wrapper correctly transfers operands,
// command, carry input, result and flags.
//
// ============================================================

module alu64_top_tb;

    // --------------------------------------------------------
    // DUT inputs
    // --------------------------------------------------------

    logic        clk;
    logic        rst_n;

    logic [63:0] operand_a;
    logic [63:0] operand_b;

    logic [3:0]  cmd;
    logic        carry_in;


    // --------------------------------------------------------
    // DUT outputs
    // --------------------------------------------------------

    logic [63:0] result;

    logic        carry_out;
    logic        zero_flag;
    logic        negative_flag;
    logic        overflow_flag;


    // --------------------------------------------------------
    // Opcode definitions
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
    // DUT
    // --------------------------------------------------------

    alu64_top dut (

        .clk            (clk),
        .rst_n          (rst_n),

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


    // --------------------------------------------------------
    // Clock generation
    // --------------------------------------------------------
    // The current ALU datapath is combinational, but the clock
    // is retained at the top-level interface for future system
    // integration.
    // --------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // --------------------------------------------------------
    // Test counters
    // --------------------------------------------------------

    integer total_tests;
    integer passed_tests;
    integer failed_tests;


    // --------------------------------------------------------
    // Reference calculation task
    // --------------------------------------------------------

    task automatic check_operation;

        input logic [63:0] test_a;
        input logic [63:0] test_b;
        input logic [3:0]  test_cmd;
        input logic        test_carry;

        logic [63:0] expected_result;
        logic        expected_carry;
        logic        expected_zero;
        logic        expected_negative;
        logic        expected_overflow;

        logic [64:0] ext_value;

        begin

            operand_a = test_a;
            operand_b = test_b;
            cmd       = test_cmd;
            carry_in  = test_carry;

            #1;

            // ------------------------------------------------
            // Reference model
            // ------------------------------------------------

            expected_result   = 64'd0;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;
            ext_value         = 65'd0;


            case (test_cmd)

                cmd_add: begin

                    ext_value =
                        {1'b0, test_a} +
                        {1'b0, test_b} +
                        test_carry;

                    expected_result = ext_value[63:0];
                    expected_carry  = ext_value[64];

                    expected_overflow =
                        (~(test_a[63] ^ test_b[63])) &
                        (expected_result[63] ^ test_a[63]);

                end


                cmd_sub: begin

                    ext_value =
                        {1'b0, test_a} -
                        {1'b0, test_b} -
                        test_carry;

                    expected_result = ext_value[63:0];

                    expected_carry =
                        (test_a >= test_b + test_carry);

                    expected_overflow =
                        (test_a[63] ^ test_b[63]) &
                        (expected_result[63] ^ test_a[63]);

                end


                cmd_and: begin

                    expected_result = test_a & test_b;

                end


                cmd_or: begin

                    expected_result = test_a | test_b;

                end


                cmd_xor: begin

                    expected_result = test_a ^ test_b;

                end


                cmd_not: begin

                    expected_result = ~test_a;

                end


                cmd_sll: begin

                    expected_result =
                        test_a << test_b[5:0];

                    if (test_b[5:0] != 0)
                        expected_carry =
                            test_a[64 - test_b[5:0]];

                end


                cmd_srl: begin

                    expected_result =
                        test_a >> test_b[5:0];

                    if (test_b[5:0] != 0)
                        expected_carry =
                            test_a[test_b[5:0] - 1];

                end


                cmd_sra: begin

                    expected_result =
                        $signed(test_a) >>> test_b[5:0];

                    if (test_b[5:0] != 0)
                        expected_carry =
                            test_a[test_b[5:0] - 1];

                end


                cmd_cmp: begin

                    ext_value =
                        {1'b0, test_a} -
                        {1'b0, test_b};

                    expected_result = ext_value[63:0];

                    expected_carry =
                        (test_a >= test_b);

                    expected_overflow =
                        (test_a[63] ^ test_b[63]) &
                        (expected_result[63] ^ test_a[63]);

                end


                default: begin

                    expected_result   = 64'd0;
                    expected_carry    = 1'b0;
                    expected_overflow = 1'b0;

                end

            endcase


            expected_zero =
                (expected_result == 64'd0);

            expected_negative =
                expected_result[63];


            // ------------------------------------------------
            // Result comparison
            // ------------------------------------------------

            total_tests = total_tests + 1;


            if (
                result        !== expected_result ||
                carry_out     !== expected_carry ||
                zero_flag     !== expected_zero ||
                negative_flag !== expected_negative ||
                overflow_flag !== expected_overflow
            ) begin

                failed_tests = failed_tests + 1;

                $display("");
                $display("ERROR in top-level test");
                $display("A        = %h", test_a);
                $display("B        = %h", test_b);
                $display("CMD      = %h", test_cmd);
                $display("CARRY IN = %b", test_carry);

                $display("Expected result = %h",
                         expected_result);

                $display("Actual result   = %h",
                         result);

            end
            else begin

                passed_tests = passed_tests + 1;

            end

        end

    endtask


    // --------------------------------------------------------
    // Main test sequence
    // --------------------------------------------------------

    integer i;

    logic [63:0] random_a;
    logic [63:0] random_b;


    initial begin

        // ----------------------------------------------------
        // Initial conditions
        // ----------------------------------------------------

        rst_n     = 1'b0;
        operand_a = 64'd0;
        operand_b = 64'd0;
        cmd       = cmd_add;
        carry_in  = 1'b0;

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        #10;

        rst_n = 1'b1;


        // ====================================================
        // HEADER
        // ====================================================

        $display("");
        $display("============================================================");
        $display("              64-BIT ALU TOP-LEVEL VERIFICATION");
        $display("============================================================");


        // ====================================================
        // BASIC OPERATIONS
        // ====================================================

        $display("");
        $display("SECTION 1 : BASIC OPERATIONS");


        check_operation(
            64'd25,
            64'd15,
            cmd_add,
            1'b0
        );


        check_operation(
            64'd100,
            64'd25,
            cmd_sub,
            1'b0
        );


        check_operation(
            64'hffff_0000_ffff_0000,
            64'h0f0f_0f0f_0f0f_0f0f,
            cmd_and,
            1'b0
        );


        check_operation(
            64'hffff_0000_ffff_0000,
            64'h0f0f_0f0f_0f0f_0f0f,
            cmd_or,
            1'b0
        );


        check_operation(
            64'hffff_0000_ffff_0000,
            64'h0f0f_0f0f_0f0f_0f0f,
            cmd_xor,
            1'b0
        );


        check_operation(
            64'h0000_0000_0000_0000,
            64'd0,
            cmd_not,
            1'b0
        );


        // ====================================================
        // SHIFT TESTS
        // ====================================================

        $display("");
        $display("SECTION 2 : SHIFT OPERATIONS");


        check_operation(
            64'd1,
            64'd1,
            cmd_sll,
            1'b0
        );


        check_operation(
            64'd1,
            64'd32,
            cmd_sll,
            1'b0
        );


        check_operation(
            64'h8000_0000_0000_0000,
            64'd1,
            cmd_srl,
            1'b0
        );


        check_operation(
            64'h8000_0000_0000_0000,
            64'd1,
            cmd_sra,
            1'b0
        );


        // ====================================================
        // BOUNDARY TESTS
        // ====================================================

        $display("");
        $display("SECTION 3 : BOUNDARY TESTS");


        check_operation(
            64'd0,
            64'd0,
            cmd_add,
            1'b0
        );


        check_operation(
            64'hffff_ffff_ffff_ffff,
            64'd1,
            cmd_add,
            1'b0
        );


        check_operation(
            64'h7fff_ffff_ffff_ffff,
            64'd1,
            cmd_add,
            1'b0
        );


        check_operation(
            64'h8000_0000_0000_0000,
            64'd1,
            cmd_sub,
            1'b0
        );


        // ====================================================
        // COMPARE
        // ====================================================

        $display("");
        $display("SECTION 4 : COMPARE");


        check_operation(
            64'd100,
            64'd100,
            cmd_cmp,
            1'b0
        );


        check_operation(
            64'd100,
            64'd50,
            cmd_cmp,
            1'b0
        );


        check_operation(
            64'd50,
            64'd100,
            cmd_cmp,
            1'b0
        );


        // ====================================================
        // RANDOMIZED TOP-LEVEL TESTING
        // ====================================================

        $display("");
        $display("SECTION 5 : RANDOMIZED TESTING");

        $display("Random tests : 1000");


        for (i = 0; i < 1000; i = i + 1) begin

            random_a = {
                $random,
                $random
            };

            random_b = {
                $random,
                $random
            };

            check_operation(
                random_a,
                random_b,
                $random % 10,
                $random
            );


            if ((i + 1) % 250 == 0) begin

                $display(
                    "Random tests completed : %0d / 1000",
                    i + 1
                );

            end

        end


        // ====================================================
        // FINAL REPORT
        // ====================================================

        $display("");
        $display("============================================================");
        $display("                    TEST SUMMARY");
        $display("============================================================");

        $display("Total tests  : %0d", total_tests);
        $display("Tests passed : %0d", passed_tests);
        $display("Tests failed : %0d", failed_tests);


        if (failed_tests == 0) begin

            $display("");
            $display("============================================================");
            $display("             64-BIT ALU TOP-LEVEL TEST: PASS");
            $display("============================================================");

        end
        else begin

            $display("");
            $display("============================================================");
            $display("             64-BIT ALU TOP-LEVEL TEST: FAIL");
            $display("============================================================");

        end


        $finish;

    end

endmodule