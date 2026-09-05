`timescale 1ns/1ps

module alu64_cp_pipeline_tb;

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

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    alu64_cp_pipeline dut (
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

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Expected-value storage
    // 5-stage scoreboard
    // ------------------------------------------------------------

    logic [63:0] exp_result [0:4];
    logic        exp_carry  [0:4];
    logic        exp_zero   [0:4];
    logic        exp_neg    [0:4];
    logic        exp_ovf    [0:4];
    logic        exp_valid  [0:4];

    integer tests;
    integer passed;
    integer failed;

    integer cycle_count;
    integer transaction_count;

    // ------------------------------------------------------------
    // Deterministic pseudo-random generator
    // ------------------------------------------------------------

    logic [63:0] random_state;

    function automatic [63:0] next_random64;
        input [63:0] current_state;

        logic [63:0] x;

        begin
            x = current_state;

            x = x ^ (x << 13);
            x = x ^ (x >> 17);
            x = x ^ (x << 5);

            next_random64 = x;
        end
    endfunction

    // ------------------------------------------------------------
    // Reference ALU model
    // ------------------------------------------------------------

    task automatic calculate_expected;

        input  [63:0] a;
        input  [63:0] b;
        input  [3:0]  operation;
        input         cin;

        output [63:0] expected_result;
        output        expected_carry;
        output        expected_zero;
        output        expected_negative;
        output        expected_overflow;

        reg [64:0] arithmetic_ext;
        reg [5:0]  shift_amount;

        begin

            expected_result   = 64'b0;
            expected_carry   = 1'b0;
            expected_zero    = 1'b0;
            expected_negative = 1'b0;
            expected_overflow = 1'b0;

            arithmetic_ext = 65'b0;
            shift_amount   = b[5:0];

            case (operation)

                // ADD
                4'b0000: begin
                    arithmetic_ext =
                        {1'b0, a} +
                        {1'b0, b} +
                        cin;

                    expected_result = arithmetic_ext[63:0];
                    expected_carry  = arithmetic_ext[64];

                    expected_overflow =
                        (~(a[63] ^ b[63])) &
                        (expected_result[63] ^ a[63]);
                end

                // SUB
                4'b0001: begin
                    arithmetic_ext =
                        {1'b0, a} -
                        {1'b0, b} -
                        cin;

                    expected_result = arithmetic_ext[63:0];

                    if ({1'b0, a} >=
                        ({1'b0, b} + cin))
                        expected_carry = 1'b1;
                    else
                        expected_carry = 1'b0;

                    expected_overflow =
                        (a[63] ^ b[63]) &
                        (expected_result[63] ^ a[63]);
                end

                // AND
                4'b0010:
                    expected_result = a & b;

                // OR
                4'b0011:
                    expected_result = a | b;

                // XOR
                4'b0100:
                    expected_result = a ^ b;

                // NOT
                4'b0101:
                    expected_result = ~a;

                // SHIFT LEFT
                4'b0110: begin
                    expected_result = a << shift_amount;

                    if (shift_amount != 0)
                        expected_carry = a[64 - shift_amount];
                end

                // SHIFT RIGHT
                4'b0111: begin
                    expected_result = a >> shift_amount;

                    if (shift_amount != 0)
                        expected_carry = a[shift_amount - 1];
                end

                // ARITHMETIC SHIFT RIGHT
                4'b1000: begin
                    expected_result =
                        $signed(a) >>> shift_amount;

                    if (shift_amount != 0)
                        expected_carry = a[shift_amount - 1];
                end

                // COMPARE EQUAL
                4'b1001: begin
                    if (a == b)
                        expected_result = 64'd1;
                    else
                        expected_result = 64'd0;
                end

                // COMPARE LESS - signed
                4'b1010: begin
                    if ($signed(a) < $signed(b))
                        expected_result = 64'd1;
                    else
                        expected_result = 64'd0;
                end

                // COMPARE GREATER - signed
                4'b1011: begin
                    if ($signed(a) > $signed(b))
                        expected_result = 64'd1;
                    else
                        expected_result = 64'd0;
                end

                // INCREMENT
                4'b1100: begin
                    arithmetic_ext =
                        {1'b0, a} + 65'd1;

                    expected_result = arithmetic_ext[63:0];
                    expected_carry  = arithmetic_ext[64];

                    expected_overflow =
                        (~a[63]) &
                        expected_result[63];
                end

                // DECREMENT
                4'b1101: begin
                    arithmetic_ext =
                        {1'b0, a} - 65'd1;

                    expected_result = arithmetic_ext[63:0];

                    if (a != 64'b0)
                        expected_carry = 1'b1;
                    else
                        expected_carry = 1'b0;

                    expected_overflow =
                        a[63] &
                        ~expected_result[63];
                end

                // PASS A
                4'b1110:
                    expected_result = a;

                // PASS B
                4'b1111:
                    expected_result = b;

                default: begin
                    expected_result  = 64'b0;
                    expected_carry   = 1'b0;
                    expected_overflow = 1'b0;
                end

            endcase

            if (expected_result == 64'b0)
                expected_zero = 1'b1;
            else
                expected_zero = 1'b0;

            expected_negative = expected_result[63];

        end

    endtask

    // ------------------------------------------------------------
    // Scoreboard
    // ------------------------------------------------------------

    task automatic check_output;

        integer i;
        reg mismatch;

        begin

            // Shift scoreboard
            for (i = 4; i > 0; i = i - 1) begin
                exp_result[i] = exp_result[i-1];
                exp_carry[i]  = exp_carry[i-1];
                exp_zero[i]   = exp_zero[i-1];
                exp_neg[i]    = exp_neg[i-1];
                exp_ovf[i]    = exp_ovf[i-1];
                exp_valid[i]  = exp_valid[i-1];
            end

            // Insert current transaction into stage 0
            if (valid_in) begin

                calculate_expected(
                    operand_a,
                    operand_b,
                    cmd,
                    carry_in,

                    exp_result[0],
                    exp_carry[0],
                    exp_zero[0],
                    exp_neg[0],
                    exp_ovf[0]
                );

                exp_valid[0] = 1'b1;

            end
            else begin

                exp_result[0] = 64'b0;
                exp_carry[0]  = 1'b0;
                exp_zero[0]   = 1'b0;
                exp_neg[0]    = 1'b0;
                exp_ovf[0]    = 1'b0;
                exp_valid[0]  = 1'b0;

            end

            // Compare output
            #1;

            tests = tests + 1;

            mismatch = 1'b0;

            if (valid_out !== exp_valid[4]) begin

                mismatch = 1'b1;

                $display(
                    "FAIL @ %0t ns | VALID mismatch | expected=%b actual=%b",
                    $time,
                    exp_valid[4],
                    valid_out
                );

            end

            // Only compare data/flags when transaction is valid
            if (exp_valid[4]) begin

                if (result !== exp_result[4]) begin
                    mismatch = 1'b1;

                    $display(
                        "FAIL @ %0t ns | RESULT | expected=%h actual=%h",
                        $time,
                        exp_result[4],
                        result
                    );
                end

                if (carry_out !== exp_carry[4]) begin
                    mismatch = 1'b1;

                    $display(
                        "FAIL @ %0t ns | CARRY | expected=%b actual=%b",
                        $time,
                        exp_carry[4],
                        carry_out
                    );
                end

                if (zero_flag !== exp_zero[4]) begin
                    mismatch = 1'b1;

                    $display(
                        "FAIL @ %0t ns | ZERO | expected=%b actual=%b",
                        $time,
                        exp_zero[4],
                        zero_flag
                    );
                end

                if (negative_flag !== exp_neg[4]) begin
                    mismatch = 1'b1;

                    $display(
                        "FAIL @ %0t ns | NEGATIVE | expected=%b actual=%b",
                        $time,
                        exp_neg[4],
                        negative_flag
                    );
                end

                if (overflow_flag !== exp_ovf[4]) begin
                    mismatch = 1'b1;

                    $display(
                        "FAIL @ %0t ns | OVERFLOW | expected=%b actual=%b",
                        $time,
                        exp_ovf[4],
                        overflow_flag
                    );
                end

            end

            if (mismatch) begin
                failed = failed + 1;
            end
            else begin
                passed = passed + 1;
            end

        end

    endtask

    // ------------------------------------------------------------
    // Drive one transaction
    // ------------------------------------------------------------

    task automatic send_transaction;

        input [63:0] a;
        input [63:0] b;
        input [3:0]  operation;
        input        cin;

        begin

            @(negedge clk);

            valid_in = 1'b1;
            operand_a = a;
            operand_b = b;
            cmd       = operation;
            carry_in  = cin;

            transaction_count =
                transaction_count + 1;

        end

    endtask

    // ------------------------------------------------------------
    // Drive bubble
    // ------------------------------------------------------------

    task automatic send_bubble;

        begin

            @(negedge clk);

            valid_in = 1'b0;
            operand_a = 64'b0;
            operand_b = 64'b0;
            cmd       = 4'b0;
            carry_in  = 1'b0;

        end

    endtask

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    integer k;
    integer opcode_index;

    reg [63:0] rand_a;
    reg [63:0] rand_b;
    reg [63:0] rand_c;
    reg        rand_carry;

    initial begin

        tests = 0;
        passed = 0;
        failed = 0;

        cycle_count = 0;
        transaction_count = 0;

        random_state = 64'h1234_5678_9ABC_DEF1;

        valid_in = 1'b0;
        operand_a = 64'b0;
        operand_b = 64'b0;
        cmd = 4'b0;
        carry_in = 1'b0;

        for (k = 0; k < 5; k = k + 1) begin
            exp_result[k] = 64'b0;
            exp_carry[k]  = 1'b0;
            exp_zero[k]   = 1'b0;
            exp_neg[k]    = 1'b0;
            exp_ovf[k]    = 1'b0;
            exp_valid[k]  = 1'b0;
        end

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        rst_n = 1'b0;

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out !== 1'b0) begin
            $display("FAIL: RESET | valid_out should be 0");
            failed = failed + 1;
        end
        else begin
            $display("PASS: RESET | valid_out=0");
        end

        rst_n = 1'b1;

        // --------------------------------------------------------
        // Header
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("       ALU64_CP STEP 6 RANDOMIZED TEST");
        $display("================================================");
        $display("1000 deterministic pseudo-random transactions");
        $display("All 16 opcodes + bubbles + flags + ordering");
        $display("================================================");

        // --------------------------------------------------------
        // Directed corner cases first
        // --------------------------------------------------------

        send_transaction(
            64'h7FFF_FFFF_FFFF_FFFF,
            64'h0000_0000_0000_0001,
            4'b0000,
            1'b0
        );

        send_transaction(
            64'h8000_0000_0000_0000,
            64'h0000_0000_0000_0001,
            4'b0001,
            1'b0
        );

        send_transaction(
            64'hFFFF_FFFF_FFFF_FFFF,
            64'h0000_0000_0000_0001,
            4'b1100,
            1'b0
        );

        send_transaction(
            64'h0000_0000_0000_0000,
            64'h0000_0000_0000_0001,
            4'b1101,
            1'b0
        );

        send_transaction(
            64'h8000_0000_0000_0000,
            64'h0000_0000_0000_0001,
            4'b1000,
            1'b0
        );

        send_transaction(
            64'h7FFF_FFFF_FFFF_FFFF,
            64'h8000_0000_0000_0000,
            4'b1010,
            1'b0
        );

        send_transaction(
            64'h8000_0000_0000_0000,
            64'h7FFF_FFFF_FFFF_FFFF,
            4'b1011,
            1'b0
        );

        // --------------------------------------------------------
        // Randomized traffic
        // --------------------------------------------------------

        for (k = 0; k < 1000; k = k + 1) begin

            // Generate deterministic random values
            random_state = next_random64(random_state);
            rand_a = random_state;

            random_state = next_random64(random_state);
            rand_b = random_state;

            random_state = next_random64(random_state);
            rand_c = random_state;

            rand_carry = rand_c[0];

            // Guarantee all 16 opcodes are exercised repeatedly
            opcode_index = k % 16;

            // Insert deterministic bubbles
            if ((k % 17) == 0) begin
                send_bubble;
            end
            else if ((k % 29) == 0) begin
                send_bubble;
                send_bubble;
            end

            send_transaction(
                rand_a,
                rand_b,
                opcode_index[3:0],
                rand_carry
            );

            // Occasionally insert another bubble
            if ((k % 23) == 0)
                send_bubble;

        end

        // --------------------------------------------------------
        // Drain pipeline
        // --------------------------------------------------------

        repeat (8) begin
            send_bubble;
        end

        // Allow final scoreboard checks
        repeat (3)
            @(posedge clk);

        #2;

        // --------------------------------------------------------
        // Final report
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("       ALU64_CP STEP 6 VERIFICATION RESULT");
        $display("================================================");
        $display("Transactions generated : %0d", transaction_count);
        $display("Checks generated       : %0d", tests);
        $display("Passed                 : %0d", passed);
        $display("Failed                 : %0d", failed);
        $display("================================================");

        if (failed == 0) begin

            $display("ALU64_CP Step 6 randomized verification: PASS");

        end
        else begin

            $display("ALU64_CP Step 6 randomized verification: FAIL");

        end

        $display("================================================");

        $finish;

    end

    // ------------------------------------------------------------
    // Scoreboard clock process
    // ------------------------------------------------------------

    always @(posedge clk) begin

        cycle_count = cycle_count + 1;

        if (rst_n)
            check_output;

    end

endmodule
