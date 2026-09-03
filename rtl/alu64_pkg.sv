// -----------------------------------------------------------------------------
// alu64_pkg.sv
//
// Common command definitions for the 64-bit ALU.
// Keeping the operation codes in one place prevents magic numbers from
// being scattered throughout the RTL and testbench.
// -----------------------------------------------------------------------------

package alu64_pkg;

    // 6-bit command encoding.
    // Only the first 16 values are currently assigned to operations.
    typedef enum logic [5:0] {

        op_add  = 6'b000000,  // unsigned/signed addition
        op_sub  = 6'b000001,  // subtraction
        op_and  = 6'b000010,  // bitwise AND
        op_or   = 6'b000011,  // bitwise OR
        op_xor  = 6'b000100,  // bitwise XOR
        op_not  = 6'b000101,  // bitwise inversion
        op_inc  = 6'b000110,  // increment operand a
        op_dec  = 6'b000111,  // decrement operand a
        op_sll  = 6'b001000,  // logical left shift
        op_srl  = 6'b001001,  // logical right shift
        op_sra  = 6'b001010,  // arithmetic right shift
        op_eq   = 6'b001011,  // equality comparison
        op_ne   = 6'b001100,  // inequality comparison
        op_lt   = 6'b001101,  // signed less-than
        op_ltu  = 6'b001110,  // unsigned less-than
        op_pass = 6'b001111   // pass operand a unchanged

    } alu_cmd_t;

endpackage