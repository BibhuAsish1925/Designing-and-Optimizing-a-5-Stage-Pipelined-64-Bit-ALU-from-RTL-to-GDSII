`timescale 1ns / 1ps

// ============================================================================
// 64-bit ALU - Step 5 Verification Testbench
//
// Verification features:
//   1. Independent reference model
//   2. Directed functional tests
//   3. 64-bit boundary tests
//   4. Comparison tests
//   5. Randomized testing using XSim-compatible $random
//   6. Immediate assertions
//   7. Result and flag checking
//   8. Pass/fail statistics
//
// IMPORTANT:
// This testbench is written for Vivado XSim.
// $urandom is intentionally NOT used because XSim reports:
//   "urandom system task is not supported."
// ============================================================================

module alu64_core_tb;

    // =========================================================================
    // DUT INPUTS
    // =========================================================================

    logic [63:0] a;
    logic [63:0] b;
    logic [3:0]  cmd;


    // =========================================================================
    // DUT OUTPUTS
    // =========================================================================

    logic [63:0] result;
    logic        zero;
    logic        carry;
    logic        overflow;
    logic        negative;


    // =========================================================================
    // REFERENCE MODEL OUTPUTS
    //
    // These signals contain the values calculated independently by the
    // verification model.
    // =========================================================================

    logic [63:0] expected_result;
    logic        expected_zero;
    logic        expected_carry;
    logic        expected_overflow;
    logic        expected_negative;


    // =========================================================================
    // TEST STATISTICS
    // =========================================================================

    integer tests_passed;
    integer tests_failed;
    integer total_tests;

    integer random_tests;


    // =========================================================================
    // RANDOM NUMBER SEED
    //
    // $random is supported by Vivado XSim.
    // A fixed seed makes the randomized test sequence reproducible.
    // =========================================================================

    integer random_seed;


    // =========================================================================
    // DEVICE UNDER TEST
    // =========================================================================

    alu64_core dut (
        .a        (a),
        .b        (b),
        .cmd      (cmd),
        .result   (result),
        .zero     (zero),
        .carry    (carry),
        .overflow (overflow),
        .negative (negative)
    );


    // =========================================================================
    // REFERENCE MODEL
    //
    // This model intentionally does NOT instantiate or reuse the ALU logic.
    //
    // The purpose is to independently calculate the expected answer and
    // compare it against the actual hardware implementation.
    // =========================================================================

    task automatic reference_model;

        logic [64:0] ref_ext;

        logic [63:0] ref_result;

        logic ref_carry;
        logic ref_overflow;

        logic signed [63:0] signed_a;
        logic signed [63:0] signed_b;

        begin

            // -----------------------------------------------------------------
            // Default values
            // -----------------------------------------------------------------

            ref_ext      = 65'b0;
            ref_result   = 64'b0;
            ref_carry    = 1'b0;
            ref_overflow = 1'b0;


            // -----------------------------------------------------------------
            // Signed aliases for signed comparison operations.
            // -----------------------------------------------------------------

            signed_a = $signed(a);
            signed_b = $signed(b);


            // -----------------------------------------------------------------
            // Opcode selection
            // -----------------------------------------------------------------

            case (cmd)

                // =============================================================
                // 0x0 : ADD
                // =============================================================

                4'h0: begin

                    // Extra bit preserves the unsigned carry-out.
                    ref_ext = {1'b0, a} + {1'b0, b};

                    ref_result = ref_ext[63:0];

                    ref_carry = ref_ext[64];

                    // Signed overflow occurs when:
                    // same-sign inputs produce an opposite-sign result.
                    ref_overflow =
                        (~(a[63] ^ b[63])) &
                        (ref_result[63] ^ a[63]);

                end


                // =============================================================
                // 0x1 : SUB
                // =============================================================

                4'h1: begin

                    ref_ext = {1'b0, a} - {1'b0, b};

                    ref_result = ref_ext[63:0];

                    // Carry is defined as "no borrow".
                    ref_carry = (a >= b);

                    // Signed subtraction overflow.
                    ref_overflow =
                        (a[63] ^ b[63]) &
                        (ref_result[63] ^ a[63]);

                end


                // =============================================================
                // 0x2 : AND
                // =============================================================

                4'h2: begin

                    ref_result = a & b;

                end


                // =============================================================
                // 0x3 : OR
                // =============================================================

                4'h3: begin

                    ref_result = a | b;

                end


                // =============================================================
                // 0x4 : XOR
                // =============================================================

                4'h4: begin

                    ref_result = a ^ b;

                end


                // =============================================================
                // 0x5 : NOT A
                // =============================================================

                4'h5: begin

                    ref_result = ~a;

                end


                // =============================================================
                // 0x6 : SHIFT LEFT
                // =============================================================

                4'h6: begin

                    // Only six bits are required to represent 0-63.
                    ref_result = a << b[5:0];

                end


                // =============================================================
                // 0x7 : LOGICAL SHIFT RIGHT
                // =============================================================

                4'h7: begin

                    ref_result = a >> b[5:0];

                end


                // =============================================================
                // 0x8 : ARITHMETIC SHIFT RIGHT
                // =============================================================

                4'h8: begin

                    // $signed preserves the sign during right shifting.
                    ref_result = $signed(a) >>> b[5:0];

                end


                // =============================================================
                // 0x9 : SIGNED LESS THAN
                // =============================================================

                4'h9: begin

                    if (signed_a < signed_b)
                        ref_result = 64'd1;
                    else
                        ref_result = 64'd0;

                end


                // =============================================================
                // 0xA : UNSIGNED LESS THAN
                // =============================================================

                4'hA: begin

                    if (a < b)
                        ref_result = 64'd1;
                    else
                        ref_result = 64'd0;

                end


                // =============================================================
                // 0xB : EQUAL
                // =============================================================

                4'hB: begin

                    if (a == b)
                        ref_result = 64'd1;
                    else
                        ref_result = 64'd0;

                end


                // =============================================================
                // 0xC : PASS A
                // =============================================================

                4'hC: begin

                    ref_result = a;

                end


                // =============================================================
                // 0xD : PASS B
                // =============================================================

                4'hD: begin

                    ref_result = b;

                end


                // =============================================================
                // 0xE : ZERO
                // =============================================================

                4'hE: begin

                    ref_result = 64'b0;

                end


                // =============================================================
                // 0xF : ALL ONES
                // =============================================================

                4'hF: begin

                    ref_result = 64'hFFFF_FFFF_FFFF_FFFF;

                end


                // =============================================================
                // DEFAULT
                // =============================================================

                default: begin

                    ref_result   = 64'b0;
                    ref_carry    = 1'b0;
                    ref_overflow = 1'b0;

                end

            endcase


            // -----------------------------------------------------------------
            // Common flag generation
            // -----------------------------------------------------------------

            expected_result  = ref_result;

            expected_carry   = ref_carry;

            expected_overflow = ref_overflow;

            // Zero is asserted whenever the result contains all zeroes.
            expected_zero = (ref_result == 64'b0);

            // Negative reflects the MSB of the 64-bit result.
            expected_negative = ref_result[63];

        end

    endtask


    // =========================================================================
    // CHECK ONE TEST CASE
    //
    // This task:
    //   1. Applies the input vector.
    //   2. Generates the reference answer.
    //   3. Waits for combinational propagation.
    //   4. Checks result.
    //   5. Checks every flag.
    //   6. Updates statistics.
    // =========================================================================

    task automatic check_case(
        input logic [3:0]  test_cmd,
        input logic [63:0] test_a,
        input logic [63:0] test_b
    );

        bit case_passed;

        begin

            case_passed = 1'b1;


            // -----------------------------------------------------------------
            // Apply inputs to DUT.
            // -----------------------------------------------------------------

            a   = test_a;
            b   = test_b;
            cmd = test_cmd;


            // -----------------------------------------------------------------
            // Calculate expected output.
            // -----------------------------------------------------------------

            reference_model();


            // -----------------------------------------------------------------
            // Allow combinational logic to settle.
            // -----------------------------------------------------------------

            #1;


            total_tests = total_tests + 1;


            // =================================================================
            // RESULT CHECK
            // =================================================================

            assert (result === expected_result)
            else begin

                case_passed = 1'b0;

                $display("");
                $display("RESULT ERROR");
                $display("CMD      = %h", test_cmd);
                $display("A        = %h", test_a);
                $display("B        = %h", test_b);
                $display("EXPECTED = %h", expected_result);
                $display("ACTUAL   = %h", result);

            end


            // =================================================================
            // ZERO FLAG CHECK
            // =================================================================

            assert (zero === expected_zero)
            else begin

                case_passed = 1'b0;

                $display("");
                $display("ZERO FLAG ERROR");
                $display("CMD      = %h", test_cmd);
                $display("EXPECTED = %b", expected_zero);
                $display("ACTUAL   = %b", zero);

            end


            // =================================================================
            // CARRY FLAG CHECK
            // =================================================================

            assert (carry === expected_carry)
            else begin

                case_passed = 1'b0;

                $display("");
                $display("CARRY FLAG ERROR");
                $display("CMD      = %h", test_cmd);
                $display("EXPECTED = %b", expected_carry);
                $display("ACTUAL   = %b", carry);

            end


            // =================================================================
            // OVERFLOW FLAG CHECK
            // =================================================================

            assert (overflow === expected_overflow)
            else begin

                case_passed = 1'b0;

                $display("");
                $display("OVERFLOW FLAG ERROR");
                $display("CMD      = %h", test_cmd);
                $display("EXPECTED = %b", expected_overflow);
                $display("ACTUAL   = %b", overflow);

            end


            // =================================================================
            // NEGATIVE FLAG CHECK
            // =================================================================

            assert (negative === expected_negative)
            else begin

                case_passed = 1'b0;

                $display("");
                $display("NEGATIVE FLAG ERROR");
                $display("CMD      = %h", test_cmd);
                $display("EXPECTED = %b", expected_negative);
                $display("ACTUAL   = %b", negative);

            end


            // -----------------------------------------------------------------
            // Update counters.
            // -----------------------------------------------------------------

            if (case_passed) begin

                tests_passed = tests_passed + 1;

            end
            else begin

                tests_failed = tests_failed + 1;

            end

        end

    endtask


    // =========================================================================
    // MAIN TEST SEQUENCE
    // =========================================================================

    initial begin

        // ---------------------------------------------------------------------
        // Initialize counters.
        // ---------------------------------------------------------------------

        tests_passed = 0;
        tests_failed = 0;
        total_tests  = 0;
        random_tests = 2000;


        // ---------------------------------------------------------------------
        // Initialize random seed.
        //
        // $random(seed) is used instead of $urandom because it is supported
        // by Vivado XSim.
        // ---------------------------------------------------------------------

        random_seed = 32'h64A1_2026;


        // ---------------------------------------------------------------------
        // Initialize DUT inputs.
        // ---------------------------------------------------------------------

        a   = 64'b0;
        b   = 64'b0;
        cmd = 4'h0;

        #1;


        // =====================================================================
        // TEST HEADER
        // =====================================================================

        $display("");
        $display("============================================================");
        $display("              64-BIT ALU VERIFICATION");
        $display("============================================================");
        $display("");


        // =====================================================================
        // SECTION 1 : BASIC DIRECTED TESTS
        // =====================================================================

        $display("------------------------------------------------------------");
        $display("SECTION 1 : BASIC DIRECTED TESTS");
        $display("------------------------------------------------------------");


        // ADD
        check_case(
            4'h0,
            64'd10,
            64'd20
        );


        // SUB
        check_case(
            4'h1,
            64'd50,
            64'd20
        );


        // AND
        check_case(
            4'h2,
            64'hFFFF_0000_FFFF_0000,
            64'h0F0F_0F0F_0F0F_0F0F
        );


        // OR
        check_case(
            4'h3,
            64'hFFFF_0000_0000_FFFF,
            64'h0000_FFFF_FFFF_0000
        );


        // XOR
        check_case(
            4'h4,
            64'hFFFF_0000_FFFF_0000,
            64'h0F0F_0F0F_0F0F_0F0F
        );


        // NOT
        check_case(
            4'h5,
            64'hFFFF_0000_FFFF_0000,
            64'b0
        );


        // SHIFT LEFT
        check_case(
            4'h6,
            64'd1,
            64'd4
        );


        // LOGICAL SHIFT RIGHT
        check_case(
            4'h7,
            64'd64,
            64'd3
        );


        // ARITHMETIC SHIFT RIGHT
        check_case(
            4'h8,
            64'h8000_0000_0000_0000,
            64'd4
        );


        // SIGNED LESS THAN
        check_case(
            4'h9,
            64'hFFFF_FFFF_FFFF_FFFF,
            64'd1
        );


        // UNSIGNED LESS THAN
        check_case(
            4'hA,
            64'd1,
            64'd2
        );


        // EQUAL
        check_case(
            4'hB,
            64'h1234_5678_9ABC_DEF0,
            64'h1234_5678_9ABC_DEF0
        );


        // PASS A
        check_case(
            4'hC,
            64'h1234_5678_9ABC_DEF0,
            64'b0
        );


        // PASS B
        check_case(
            4'hD,
            64'b0,
            64'hFEDC_BA98_7654_3210
        );


        // ZERO
        check_case(
            4'hE,
            64'h1234,
            64'h5678
        );


        // ALL ONES
        check_case(
            4'hF,
            64'b0,
            64'b0
        );


        // =====================================================================
        // SECTION 2 : 64-BIT BOUNDARY TESTS
        // =====================================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("SECTION 2 : 64-BIT BOUNDARY TESTS");
        $display("------------------------------------------------------------");


        // Maximum unsigned value + 1.
        check_case(
            4'h0,
            64'hFFFF_FFFF_FFFF_FFFF,
            64'd1
        );


        // Zero minus one.
        check_case(
            4'h1,
            64'd0,
            64'd1
        );


        // Maximum positive signed value.
        check_case(
            4'hC,
            64'h7FFF_FFFF_FFFF_FFFF,
            64'b0
        );


        // Minimum negative signed value.
        check_case(
            4'hC,
            64'h8000_0000_0000_0000,
            64'b0
        );


        // Signed addition overflow.
        check_case(
            4'h0,
            64'h7FFF_FFFF_FFFF_FFFF,
            64'd1
        );


        // Signed subtraction overflow.
        check_case(
            4'h1,
            64'h8000_0000_0000_0000,
            64'd1
        );


        // Shift by zero.
        check_case(
            4'h6,
            64'h1234_5678_9ABC_DEF0,
            64'd0
        );


        // Shift by 63.
        check_case(
            4'h6,
            64'd1,
            64'd63
        );


        // Logical right shift by 63.
        check_case(
            4'h7,
            64'h8000_0000_0000_0000,
            64'd63
        );


        // Arithmetic right shift by 63.
        check_case(
            4'h8,
            64'h8000_0000_0000_0000,
            64'd63
        );


        // =====================================================================
        // SECTION 3 : COMPARISON TESTS
        // =====================================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("SECTION 3 : COMPARISON TESTS");
        $display("------------------------------------------------------------");


        // Signed: -1 < +1.
        check_case(
            4'h9,
            64'hFFFF_FFFF_FFFF_FFFF,
            64'd1
        );


        // Signed: +1 is not less than -1.
        check_case(
            4'h9,
            64'd1,
            64'hFFFF_FFFF_FFFF_FFFF
        );


        // Unsigned: 1 < maximum.
        check_case(
            4'hA,
            64'd1,
            64'hFFFF_FFFF_FFFF_FFFF
        );


        // Unsigned: maximum is not less than 1.
        check_case(
            4'hA,
            64'hFFFF_FFFF_FFFF_FFFF,
            64'd1
        );


        // Equal values.
        check_case(
            4'hB,
            64'hDEAD_BEEF_1234_5678,
            64'hDEAD_BEEF_1234_5678
        );


        // Different values.
        check_case(
            4'hB,
            64'hDEAD_BEEF_1234_5678,
            64'hDEAD_BEEF_1234_5679
        );


        // =====================================================================
        // SECTION 4 : ADDITIONAL FLAG TESTS
        // =====================================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("SECTION 4 : FLAG TESTS");
        $display("------------------------------------------------------------");


        // Zero result from ADD.
        check_case(
            4'h0,
            64'd0,
            64'd0
        );


        // Zero result from SUB.
        check_case(
            4'h1,
            64'd12345,
            64'd12345
        );


        // Negative result.
        check_case(
            4'h1,
            64'd0,
            64'd1
        );


        // Positive result after signed addition.
        check_case(
            4'h0,
            64'd100,
            64'd200
        );


        // Carry generation.
        check_case(
            4'h0,
            64'hFFFF_FFFF_FFFF_FFFF,
            64'h0000_0000_0000_0001
        );


        // No carry.
        check_case(
            4'h0,
            64'h0000_0000_0000_0010,
            64'h0000_0000_0000_0001
        );


        // =====================================================================
        // SECTION 5 : RANDOMIZED TESTING
        // =====================================================================

        $display("");
        $display("------------------------------------------------------------");
        $display("SECTION 5 : RANDOMIZED TESTING");
        $display("------------------------------------------------------------");

        $display("Random seed  : %h", random_seed);
        $display("Random tests : %0d", random_tests);
        $display("");


        // ---------------------------------------------------------------------
        // Generate 2000 randomized test vectors.
        //
        // Each 64-bit operand is assembled from two 32-bit $random values.
        //
        // cmd is generated from the lower four bits of $random so that the
        // resulting command is always in the range 0x0 to 0xF.
        // ---------------------------------------------------------------------

        for (integer i = 0; i < random_tests; i = i + 1) begin

            a = {
                $random(random_seed),
                $random(random_seed)
            };

            b = {
                $random(random_seed),
                $random(random_seed)
            };

            cmd = $random(random_seed) & 4'hF;


            check_case(
                cmd,
                a,
                b
            );


            // Print progress every 500 randomized vectors.
            if (((i + 1) % 500) == 0) begin

                $display(
                    "Random tests completed : %0d / %0d",
                    i + 1,
                    random_tests
                );

            end

        end


        // =====================================================================
        // FINAL REPORT
        // =====================================================================

        $display("");
        $display("============================================================");
        $display("                    TEST SUMMARY");
        $display("============================================================");
        $display("Total tests  : %0d", total_tests);
        $display("Tests passed : %0d", tests_passed);
        $display("Tests failed : %0d", tests_failed);
        $display("============================================================");
        $display("");


        // ---------------------------------------------------------------------
        // Final verification decision.
        // ---------------------------------------------------------------------

        if (tests_failed == 0) begin

            $display("============================================================");
            $display("             64-BIT ALU VERIFICATION: PASS");
            $display("============================================================");

        end
        else begin

            $display("============================================================");
            $display("             64-BIT ALU VERIFICATION: FAIL");
            $display("============================================================");

        end


        $display("");

        $finish; //type a Tcl command here - 10us if it runs for 1000ns and limited test case passes

    end

endmodule