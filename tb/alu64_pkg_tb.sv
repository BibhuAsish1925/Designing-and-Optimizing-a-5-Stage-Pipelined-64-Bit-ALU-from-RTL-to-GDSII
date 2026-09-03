// -----------------------------------------------------------------------------
// alu64_pkg_tb.sv
//
// Small compile-time/simulation sanity check for the command package.
// The purpose here is simply to verify that the command definitions are
// visible and have the expected encoded values.
// -----------------------------------------------------------------------------

module alu64_pkg_tb;

    import alu64_pkg::*;

    initial begin

        // Check a few representative command encodings.
        assert (op_add  == 6'b000000);
        assert (op_sub  == 6'b000001);
        assert (op_sra  == 6'b001010);
        assert (op_pass == 6'b001111);

        $display("========================================");
        $display(" alu64 package test: PASS");
        $display("========================================");

        $finish;
    end

endmodule