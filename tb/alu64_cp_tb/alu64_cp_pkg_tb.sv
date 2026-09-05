`timescale 1ns/1ps

module alu64_cp_pkg_tb;

    import alu64_cp_pkg::*;

    initial begin

        // Verify every opcode has the intended 4-bit encoding.
        assert (CMD_ADD    == 4'b0000) else $fatal("CMD_ADD encoding error");
        assert (CMD_SUB    == 4'b0001) else $fatal("CMD_SUB encoding error");
        assert (CMD_AND    == 4'b0010) else $fatal("CMD_AND encoding error");
        assert (CMD_OR     == 4'b0011) else $fatal("CMD_OR encoding error");
        assert (CMD_XOR    == 4'b0100) else $fatal("CMD_XOR encoding error");
        assert (CMD_NOT    == 4'b0101) else $fatal("CMD_NOT encoding error");

        assert (CMD_SLL    == 4'b0110) else $fatal("CMD_SLL encoding error");
        assert (CMD_SRL    == 4'b0111) else $fatal("CMD_SRL encoding error");
        assert (CMD_SRA    == 4'b1000) else $fatal("CMD_SRA encoding error");

        assert (CMD_CMP_EQ == 4'b1001) else $fatal("CMD_CMP_EQ encoding error");
        assert (CMD_CMP_LT == 4'b1010) else $fatal("CMD_CMP_LT encoding error");
        assert (CMD_CMP_GT == 4'b1011) else $fatal("CMD_CMP_GT encoding error");

        assert (CMD_INC    == 4'b1100) else $fatal("CMD_INC encoding error");
        assert (CMD_DEC    == 4'b1101) else $fatal("CMD_DEC encoding error");

        assert (CMD_PASS_A == 4'b1110) else $fatal("CMD_PASS_A encoding error");
        assert (CMD_PASS_B == 4'b1111) else $fatal("CMD_PASS_B encoding error");

        $display("");
        $display("========================================");
        $display("   ALU64_CP PACKAGE TEST");
        $display("========================================");
        $display("All 16 opcode definitions verified.");
        $display("ALU64_CP package test: PASS");
        $display("========================================");
        $display("");

        $finish;
    end

endmodule