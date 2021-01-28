# Constrain clock port CLOCK_50_I with a 20 ns requirement

# Constrain the register-to-register paths
create_clock -name clk_50 -period 20 [get_ports {CLOCK_50_I}]

# Use phase-locked loops (PLLs) instance parameters 
# for the generated clocks on the outputs of the PLL

derive_pll_clocks
derive_clock_uncertainty

# Constrain the input-to-register paths

set_input_delay -clock clk_50 -max 3 [all_inputs]
set_input_delay -clock clk_50 -min 2 [all_inputs]

# Constrain the output-to-register paths 

set_output_delay -clock clk_50 -max 3 [all_outputs]
set_output_delay -clock clk_50 -min 2 [all_outputs]

# Specify the false paths

set_false_path -from [get_ports {UART_RX_I}] -to clk_50
set_false_path -from [get_ports {SWITCH*}] -to clk_50
set_false_path -from [get_ports {PUSH_BUTTON*}] -to clk_50

set_false_path -from clk_50 -to [get_ports {LED_GREEN*}]
set_false_path -from clk_50 -to [get_ports {SEVEN_SEGMENT*}]
set_false_path -from clk_50 -to [get_ports {VGA_RED*}]
set_false_path -from clk_50 -to [get_ports {VGA_GREEN*}]
set_false_path -from clk_50 -to [get_ports {VGA_BLUE*}]

