###############################################################################
# ALU64_CP TOP-LEVEL VIVADO CONSTRAINTS
# Target clock: 100 MHz
# Clock period: 10 ns
###############################################################################

create_clock -name clk -period 10.000 [get_ports clk]

###############################################################################
# Clock uncertainty
###############################################################################

set_clock_uncertainty -setup 0.200 [get_clocks clk]
set_clock_uncertainty -hold  0.100 [get_clocks clk]

###############################################################################
# Input delays
#
# These represent an external synchronous source launching data relative
# to the same clock.
###############################################################################

set_input_delay -clock clk -max 2.000 \
    [get_ports {valid_in operand_a[*] operand_b[*] cmd[*] carry_in}]

set_input_delay -clock clk -min 0.500 \
    [get_ports {valid_in operand_a[*] operand_b[*] cmd[*] carry_in}]

###############################################################################
# Output delays
#
# These represent an external synchronous destination receiving the ALU
# result and flags.
###############################################################################

set_output_delay -clock clk -max 2.000 \
    [get_ports {valid_out result[*] carry_out zero_flag negative_flag overflow_flag}]

set_output_delay -clock clk -min 0.500 \
    [get_ports {valid_out result[*] carry_out zero_flag negative_flag overflow_flag}]

###############################################################################
# Reset
#
# rst_n is a synchronous reset, so it is NOT treated as asynchronous.
# Give it a normal input timing relationship.
###############################################################################

set_input_delay -clock clk -max 2.000 [get_ports rst_n]
set_input_delay -clock clk -min 0.500 [get_ports rst_n]

###############################################################################
# Input/output electrical assumptions
###############################################################################

set_false_path -from [get_ports rst_n] -to [get_ports {valid_out result[*] carry_out zero_flag negative_flag overflow_flag}]