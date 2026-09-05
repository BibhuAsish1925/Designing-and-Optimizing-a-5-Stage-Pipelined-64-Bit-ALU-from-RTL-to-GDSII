package alu64_cp_pkg;

    // 4-bit command encoding.
    // These values are shared by the ALU core, pipeline, and testbench.
    typedef enum logic [3:0] {

        CMD_ADD = 4'b0000,
        CMD_SUB = 4'b0001,
        CMD_AND = 4'b0010,
        CMD_OR  = 4'b0011,
        CMD_XOR = 4'b0100,
        CMD_NOT = 4'b0101,

        CMD_SLL = 4'b0110,
        CMD_SRL = 4'b0111,
        CMD_SRA = 4'b1000,

        CMD_CMP_EQ = 4'b1001,
        CMD_CMP_LT = 4'b1010,
        CMD_CMP_GT = 4'b1011,

        CMD_INC = 4'b1100,
        CMD_DEC = 4'b1101,

        CMD_PASS_A = 4'b1110,
        CMD_PASS_B = 4'b1111

    } alu_cmd_t;

endpackage
