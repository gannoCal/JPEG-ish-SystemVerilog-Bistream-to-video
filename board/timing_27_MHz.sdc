# Constrain clock port CLOCK_27_I with a 27 MHz requirement

# Constrain the register-to-register paths
create_clock -name clk_27 -period 37.03 [get_ports {CLOCK_27_I}]

# Use phase-locked loops (PLLs) instance parameters 
# for the generated clocks on the outputs of the PLL

derive_pll_clocks
derive_clock_uncertainty

# Define false paths between clock domains

set_false_path -from [all_inputs] -to [get_clocks {UART_clock_inst|altpll_component|auto_generated|pll1|clk[0]}]
set_false_path -from [get_keepers {dual_port_RAM*}] -to [get_clocks {UART_clock_inst|altpll_component|auto_generated|pll1|clk[0]}]

set_false_path -from [get_clocks {UART_clock_inst|altpll_component|auto_generated|pll1|clk[0]}] -to [get_keepers {dual_port_RAM*}]
set_false_path -from [get_clocks {UART_clock_inst|altpll_component|auto_generated|pll1|clk[0]}] -to [all_outputs]


