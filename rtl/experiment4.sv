/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[19:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O,                    // UART transmit signal
		
		/////// CSC
		input logic CSI_I,                    // CSC receive signal
		output logic [8:0] CSI_x,
		output logic [7:0] CSI_y,
		
		///////IDCT
		input logic IDCT_I,                    // IDCT receive signal
		
		///////IDCT
		input logic LDD_I,                    // IDCT receive signal
		
		output logic whatsTheAddy
		
);
	
logic resetn;

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

assign resetn = ~SWITCH_I[17] && SRAM_ready;


//////CSI Reg/Wire
wire CSI_enable;
wire [17:0] CSI_SRAM_address;
wire [15:0] CSI_SRAM_write_data;
wire CSI_SRAM_we_n;
reg [2:0] CSI_errorCode;
reg CSI_done;



//////IDCT Var
wire IDCT_enable;
wire [17:0] IDCT_SRAM_address;
wire [15:0] IDCT_SRAM_write_data;
wire IDCT_SRAM_we_n;
reg IDCT_done;
logic [1:0] IDCT_TLS;


//////LDD Var
wire LDD_enable;
wire [17:0] LDD_SRAM_address;
wire [15:0] LDD_SRAM_write_data;
wire LDD_SRAM_we_n;
reg LDD_done;
logic [6:0] LDD_dram_addy;
logic [31:0] LDD_dram_data;
logic LDD_dram_wren;
logic [1:0] LDD_TLS;
logic [1:0] LDD_DECODE_S;


/////Its Lit Var
logic sayLessFam;


LDD LDD_unit(
.Clock(CLOCK_50_I),
.Resetn(resetn),
.LDD_en(LDD_enable),

.SRAM_address_o(LDD_SRAM_address),
.SRAM_write_data_o(LDD_SRAM_write_data),
.SRAM_read_data(SRAM_read_data),
.SRAM_we_n_o(LDD_SRAM_we_n),

.external_dram_addy(LDD_dram_addy),
.external_dram_data(LDD_dram_data),
.external_dram_wren(LDD_dram_wren),

.top_level_state(LDD_TLS),
.IDCT_TLS(IDCT_TLS),
.IDCT_done(IDCT_done),
.DECODE_state(LDD_DECODE_S),

.done(LDD_done)


);



//IDCT
IDCT IDCT_unit(
.Clock(CLOCK_50_I),
.Resetn(resetn),
.IDCT_en(IDCT_enable),

.SRAM_address_o(IDCT_SRAM_address),
.SRAM_write_data_o(IDCT_SRAM_write_data),
.SRAM_read_data(SRAM_read_data),
.SRAM_we_n_o(IDCT_SRAM_we_n),

.LDD_dram_addy(LDD_dram_addy),
.LDD_dram_data(LDD_dram_data),
.LDD_dram_wren(LDD_dram_wren),

.integrated(whatsTheAddy),

.top_level_state(IDCT_TLS),
.LDD_TLS(LDD_TLS),

.LDD_DECODE_S(LDD_DECODE_S),

.LDD_sram_addy(LDD_SRAM_address),

.done(IDCT_done)



);

//Colorspace_interpolation
ColorspaceConversion_Interpolation CSI_unit(
.Clock(CLOCK_50_I),
.Resetn(resetn),
.CSI_en(CSI_enable),
.SRAM_address_o(CSI_SRAM_address),
.SRAM_write_data_o(CSI_SRAM_write_data),
.SRAM_read_data(SRAM_read_data),
.SRAM_we_n_o(CSI_SRAM_we_n),
.errorCode(CSI_errorCode),
	
.done(CSI_done),

.CSC_x(CSI_x),
.CSC_y(CSI_y)

);



// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error),
	
	.integrated(whatsTheAddy)
);

// SRAM unit
SRAM_controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O[17:0]),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

assign SRAM_ADDRESS_O[19:18] = 2'b00;

always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		VGA_enable <= 1'b1;
		
		sayLessFam <= 0;
		whatsTheAddy <= 1; ///integrated
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
		//address_a3 <= 7'd24;
			VGA_enable <= 1'b1;  
			if (~UART_RX_I) begin
				// Start bit on the UART line is detected
				UART_rx_initialize <= 1'b1;
				UART_timer <= 26'd0;
				VGA_enable <= 1'b0;
				top_state <= S_UART_RX;
			end
			
			if(CSI_I && !CSI_done)begin
				top_state <= S_CSC;
			
			end
			
			if(IDCT_I && !IDCT_done)begin
				top_state <= S_IDCT;
			end
			
			if(LDD_I && !LDD_done)begin
				top_state <= S_LDD;
			end
		end

		S_UART_RX: begin
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			if (UART_rx_initialize == 1'b1) 
				UART_rx_enable <= 1'b1;

			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) 
				UART_timer <= 26'd0;

			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				if (whatsTheAddy)
					top_state <= S_LDD;
				else
					top_state <= S_IDCT;
				
				UART_timer <= 26'd0;
			end
		end
		S_CSC:begin
			if(CSI_done)
				top_state <= S_IDLE;
			
		
		
		
		end
		S_IDCT:begin
			if(IDCT_done)
				top_state <= S_CSC;
		
		
		end
		
		S_LDD:begin
			if(IDCT_done)begin
				top_state <= S_CSC;
				sayLessFam <= 1;
			end
		
		
		end

		default: top_state <= S_IDLE;

		endcase
	end
end

assign CSI_enable = (top_state == S_CSC) && (!CSI_done) ? 1'd1 : 1'd0;
assign IDCT_enable = (top_state == S_IDCT) && (!IDCT_done) ? 1'd1 : 1'd0;
assign LDD_enable = (top_state == S_LDD) && (!LDD_done) && (!sayLessFam) ? 1'd1 : 1'd0;

// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd146944;

// Give access to SRAM for UART and VGA at appropriate time

/*assign SRAM_address = (top_state == S_UART_RX) ? UART_SRAM_address : (top_state == S_CSC) ? CSI_SRAM_address : VGA_SRAM_address;

assign SRAM_write_data = (top_state == S_UART_RX) ? UART_SRAM_write_data : (top_state == S_CSC) ? CSI_SRAM_write_data : 16'd0;

assign SRAM_we_n = (top_state == S_UART_RX) ? UART_SRAM_we_n : (top_state == S_CSC) ? CSI_SRAM_we_n : 1'b1;*/

always_comb begin
	case(top_state)
		S_UART_RX:begin
		SRAM_address = UART_SRAM_address;
		SRAM_write_data = UART_SRAM_write_data;
		SRAM_we_n = UART_SRAM_we_n;
		end
		S_CSC:begin
		SRAM_address = CSI_SRAM_address;
		SRAM_write_data = CSI_SRAM_write_data;
		SRAM_we_n = CSI_SRAM_we_n;
		
		end
		
		S_IDCT:begin
		SRAM_address = IDCT_SRAM_address;
		SRAM_write_data = IDCT_SRAM_write_data;
		SRAM_we_n = IDCT_SRAM_we_n;
		
		end
		
		S_LDD:begin
		
		
		SRAM_address = LDD_SRAM_address;
		SRAM_write_data = LDD_SRAM_write_data;
		SRAM_we_n = LDD_SRAM_we_n;
			
		if(whatsTheAddy && (IDCT_TLS == 2'd2))begin
			SRAM_address = IDCT_SRAM_address;
			SRAM_write_data = IDCT_SRAM_write_data;
			SRAM_we_n = IDCT_SRAM_we_n;
		end
		
		
		
		end
		
		default:begin
		SRAM_address = VGA_SRAM_address;
		SRAM_write_data = 16'd0;
		SRAM_we_n = 1'b1;
		end
	
	
	endcase


end

// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, UART_rx_initialize, PB_pushed};

endmodule
