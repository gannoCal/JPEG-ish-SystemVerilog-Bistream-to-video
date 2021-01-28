# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {LDD high level signals}
add wave -bin UUT/LDD_unit/LDD_en
add wave -bin UUT/LDD_unit/done
add wave -bin UUT/LDD_unit/ERROR
add wave -bin UUT/LDD_unit/IDCT_TLS
add wave -bin UUT/IDCT_unit/LDD_TLS

add wave -divider -height 10 {IDCT high level + STATE signals}
add wave -bin UUT/IDCT_unit/top_level_state
add wave -bin UUT/IDCT_unit/LOAD_S_state
add wave -bin UUT/IDCT_unit/STORE_S_state
add wave -bin UUT/IDCT_unit/COMPUTE_T_state
add wave -bin UUT/IDCT_unit/COMPUTE_S_state


add wave -divider -height 10 {LDD state signals}
add wave -bin UUT/LDD_unit/top_level_state
add wave -bin UUT/LDD_unit/DEADBEEF_state
add wave -bin UUT/LDD_unit/PROCESS_state
add wave -bin UUT/LDD_unit/DECODE_state
add wave -bin UUT/LDD_unit/TRANSFER_state

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/LDD_unit/SRAM_address
add wave -hex UUT/LDD_unit/SRAM_read_data
add wave -uns UUT/LDD_unit/SRAM_we_n

add wave -divider -height 10 {COUNTER signals}
add wave -uns UUT/LDD_unit/counter
add wave -uns UUT/LDD_unit/shift_counter

add wave -divider -height 10 {OFFSET signals}
add wave -uns UUT/LDD_unit/shift_counter_offset

add wave -divider -height 10 {QUANTIZATION signals}
add wave -uns UUT/LDD_unit/Q_type

add wave -divider -height 10 {SERIALIZATION BUFFER signals}
add wave -hex UUT/LDD_unit/sBuffer

add wave -divider -height 10 {SERIALIZATION WRITE LINES signals}
add wave -hex UUT/LDD_unit/writeline0
add wave -hex UUT/LDD_unit/writeline1
add wave -hex UUT/LDD_unit/testline

add wave -divider -height 10 {SERIALIZATION ADDRESS LINE signals}
add wave -uns UUT/LDD_unit/sAddress
add wave -uns UUT/LDD_unit/sAddressNext

add wave -divider -height 10 {SERIALIZATION CLIP signals}
add wave -hex UUT/LDD_unit/sClip
add wave -hex UUT/LDD_unit/sClipNext

add wave -divider -height 10 {ZEROES signals}
add wave -hex UUT/LDD_unit/zeroes

add wave -divider -height 10 {DRAM signals}
add wave -uns UUT/LDD_unit/address_a3
add wave -uns UUT/LDD_unit/address_b3
add wave -hex UUT/LDD_unit/wren_a3
add wave -hex UUT/LDD_unit/wren_b3
add wave -hex UUT/LDD_unit/data_a3
add wave -hex UUT/LDD_unit/data_b3
add wave -hex UUT/LDD_unit/out_a3
add wave -hex UUT/LDD_unit/out_b3

add wave -divider -height 10 {IDCT DRAM signals}
add wave -uns UUT/IDCT_unit/LDD_dram_addy
add wave -hex UUT/IDCT_unit/LDD_dram_data
add wave -bin UUT/IDCT_unit/LDD_dram_wren


add wave -divider -height 10 {IDCT iop_level signals}
add wave -bin UUT/IDCT_I 

add wave -divider -height 10 {IDCT state signals}
add wave -uns UUT/IDCT_unit/ERROR
add wave -uns UUT/IDCT_unit/top_level_state
add wave -uns UUT/IDCT_unit/LOAD_S_state
add wave -uns UUT/IDCT_unit/STORE_S_state
add wave -uns UUT/IDCT_unit/COMPUTE_T_state
add wave -uns UUT/IDCT_unit/COMPUTE_S_state

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/IDCT_unit/SRAM_address
add wave -hex UUT/IDCT_unit/SRAM_write_data
add wave -hex UUT/IDCT_unit/SRAM_we_n

add wave -divider -height 10 {High-Level Flag signals}
add wave -bin UUT/IDCT_unit/first_megastate
add wave -bin UUT/IDCT_unit/done

add wave -divider -height 10 {Block Trackers signals}
add wave -hex UUT/IDCT_unit/Pre_address_tracker
add wave -hex UUT/IDCT_unit/Pre_row_tracker
add wave -hex UUT/IDCT_unit/post_address_tracker
add wave -hex UUT/IDCT_unit/post_row_tracker

add wave -divider -height 10 {DRAM0 signals}
add wave -uns UUT/IDCT_unit/address_a0
add wave -uns UUT/IDCT_unit/address_b0
add wave -hex UUT/IDCT_unit/wren_a0
add wave -hex UUT/IDCT_unit/wren_b0
add wave -hex UUT/IDCT_unit/data_a0
add wave -hex UUT/IDCT_unit/data_b0
add wave -hex UUT/IDCT_unit/out_a0
add wave -hex UUT/IDCT_unit/out_b0

add wave -divider -height 10 {DRAM1 signals}
add wave -uns UUT/IDCT_unit/address_a1
add wave -uns UUT/IDCT_unit/address_b1
add wave -hex UUT/IDCT_unit/wren_a1
add wave -hex UUT/IDCT_unit/wren_b1
add wave -hex UUT/IDCT_unit/data_a1
add wave -hex UUT/IDCT_unit/data_b1
add wave -hex UUT/IDCT_unit/out_a1
add wave -hex UUT/IDCT_unit/out_b1

add wave -divider -height 10 {DRAM2 signals}
add wave -uns UUT/IDCT_unit/address_a2
add wave -uns UUT/IDCT_unit/address_b2
add wave -hex UUT/IDCT_unit/wren_a2
add wave -hex UUT/IDCT_unit/wren_b2
add wave -hex UUT/IDCT_unit/data_a2
add wave -hex UUT/IDCT_unit/data_b2
add wave -hex UUT/IDCT_unit/out_a2
add wave -hex UUT/IDCT_unit/out_b2

add wave -divider -height 10 {Load DRAM signals}
add wave -uns UUT/IDCT_unit/i_block_counter
add wave -uns UUT/IDCT_unit/j_block_counter
add wave -uns UUT/IDCT_unit/j_internal_counter
add wave -uns UUT/IDCT_unit/internal_load_counter

add wave -divider -height 10 {store DRAM signals}
add wave -uns UUT/IDCT_unit/row_counter
add wave -uns UUT/IDCT_unit/read_counter
add wave -uns UUT/IDCT_unit/write_buffer

add wave -divider -height 10 {accumulator signals}
add wave -uns UUT/IDCT_unit/accumlator0
add wave -uns UUT/IDCT_unit/accumlator1
add wave -uns UUT/IDCT_unit/accumlator2
add wave -uns UUT/IDCT_unit/accumlator3

add wave -divider -height 10 {counter signals}
add wave -uns UUT/IDCT_unit/state_counter
add wave -uns UUT/IDCT_unit/S_grab_counter
add wave -uns UUT/IDCT_unit/C_grab_counter0
add wave -uns UUT/IDCT_unit/C_grab_counter1
add wave -uns UUT/IDCT_unit/T_write_counter

add wave -divider -height 10 {buffer signals}
add wave -hex UUT/IDCT_unit/T_write_buffer0
add wave -hex UUT/IDCT_unit/T_write_buffer1
add wave -hex UUT/IDCT_unit/T_write_buffer2

add wave -divider -height 10 {flag signals}
add wave -bin UUT/IDCT_unit/initial_compute_T

add wave -divider -height 10 {flip-flop signals}
add wave -bin UUT/IDCT_unit/flip_flop

add wave -divider -height 10 {mult_unit_0 signals}
add wave -uns UUT/IDCT_unit/op1_0
add wave -uns UUT/IDCT_unit/op2_0
add wave -uns UUT/IDCT_unit/mult_result_0

add wave -divider -height 10 {mult_unit_1 signals}
add wave -uns UUT/IDCT_unit/op1_1
add wave -uns UUT/IDCT_unit/op2_1
add wave -uns UUT/IDCT_unit/mult_result_1

add wave -divider -height 10 {mult_unit_2 signals}
add wave -uns UUT/IDCT_unit/op1_2
add wave -uns UUT/IDCT_unit/op2_2
add wave -uns UUT/IDCT_unit/mult_result_2

add wave -divider -height 10 {mult_unit_3 signals}
add wave -uns UUT/IDCT_unit/op1_3
add wave -uns UUT/IDCT_unit/op2_3
add wave -uns UUT/IDCT_unit/mult_result_3