# ============================================================
# ALU64_CP - Vivado Synthesis Constraints
# 64-bit, 5-stage pipelined ALU
# ============================================================

# 100 MHz target clock
create_clock -name clk -period 10.000 [get_ports clk]

# Input/output timing assumptions
set_input_delay  2.000 -clock clk [get_ports {operand_a[*] operand_b[*] cmd[*] carry_in valid_in rst_n}]
set_output_delay 2.000 -clock clk [get_ports {result[*] carry_out zero_flag negative_flag overflow_flag valid_out}]