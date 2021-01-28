
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM.v
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/SRAM_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PB_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/VGA_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/convert_hex_to_seven_segment.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/UART_receive_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/UART_SRAM_interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/VGA_SRAM_interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/Multiplier.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/Interpolation.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/CSConversion.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/ColorspaceConversion_Interpolation.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/IDCT.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/LDD.sv
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM1.v
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM2.v
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM3.v
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/RAM_init0.mif
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/RAM_init1.mif
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/RAM_init2.mif
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/experiment4.sv

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_SRAM_Emulator.sv
# vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_project_v0.sv
# vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_project_v1.sv

