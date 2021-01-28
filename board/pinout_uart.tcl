set_location_assignment PIN_G12 -to UART_RX_I
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_RX_I
set_instance_assignment -name IO_MAXIMUM_TOGGLE_RATE "1 MHz" -to UART_RX_I

set_location_assignment PIN_G9 -to UART_TX_O
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX_O
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to UART_TX_O
set_instance_assignment -name SLEW_RATE 2 -to UART_TX_O

