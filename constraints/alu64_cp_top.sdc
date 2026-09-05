# ALU64_CP ASIC TIMING CONSTRAINTS

create_clock -name clk -period 10.000 [get_ports clk]

set_clock_uncertainty 0.200 [get_clocks clk]

set_clock_transition 0.100 [get_clocks clk]

# Input delays
set_input_delay -clock clk -max 2.000 \
    [get_ports {valid_in operand_a[*] operand_b[*] cmd[*] carry_in}]

set_input_delay -clock clk -min 0.500 \
    [get_ports {valid_in operand_a[*] operand_b[*] cmd[*] carry_in}]

# Synchronous active-low reset
set_input_delay -clock clk -max 2.000 [get_ports rst_n]
set_input_delay -clock clk -min 0.500 [get_ports rst_n]

# Output delays
set_output_delay -clock clk -max 2.000 \
    [get_ports {valid_out result[*] carry_out zero_flag negative_flag overflow_flag}]

set_output_delay -clock clk -min 0.500 \
    [get_ports {valid_out result[*] carry_out zero_flag negative_flag overflow_flag}]
