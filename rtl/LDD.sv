`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


module LDD (					//////Zig-Zag to the MAC
	input  logic            Clock,
   input  logic            Resetn,
	input  logic 				LDD_en,
	
	output wire   [17:0]   SRAM_address_o,
	output  wire   [15:0]   SRAM_write_data_o,
   input  wire   [15:0]   SRAM_read_data,
	output wire SRAM_we_n_o,
	
	output logic [6:0] external_dram_addy,
	output logic [31:0] external_dram_data,
	output logic external_dram_wren,
	
	output enum logic [1:0] {
		INIT_LDD,
		DEADBEEF,
		PROCESS,
		TRANSFER
	} top_level_state,
	
	output enum logic [1:0] {
		RUN,
		SDELAY1,
		SDELAY2
		
	} DECODE_state,
	
	
	
	input logic [1:0] IDCT_TLS,
	input logic IDCT_done,
	
	output logic done
	
	
);

////ERROR HANDLING
enum logic [1:0] {
	NONE,
	NOTDEAD,
	NOTBEEF
} ERROR;

//////////FSM States
/*enum logic [1:0] {
	INIT,
	DEADBEEF,
	PROCESS,
	TRANSFER
} top_level_state;*/

enum logic [1:0] {
	INIT_T_address,
	SEND_DATA,
	WAIT,
	WTT
}TRANSFER_state;


enum logic [2:0] {
	INIT_address,
	DELAY1,
	DELAY2,
	DEADBEEF_INTERNAL,
	DONE_LOAD
} DEADBEEF_state;

enum logic [1:0] {
	BUFFER_FILL1,
	BUFFER_FILL2,
	DECODE
} PROCESS_state;


/*enum logic [1:0] {
	RUN,
	SDELAY1,
	SDELAY2
} DECODE_state;*/



///////counters
logic [5:0] counter;
logic [4:0] shift_counter;

//////counter comb offset
logic [4:0] shift_counter_offset;

//////Quantaization Var
logic Q_type;

//////Serialization Buffers
logic [31:0] sBuffer;

/////special var
logic specialFlag;
logic [31:0] specialBuffer;

//////Serialization write lines
logic [31:0] writeline0;
logic [31:0] writeline1;
logic [8:0] testline;


//////Serialization Address lines
logic [5:0] sAddress;
logic [5:0] sAddressNext;

/////Serialization Clip
logic [2:0] sClip;
logic [2:0] sClipNext;

/////serialization zeros
logic [5:0] zeroes;

/////SRAM Var
logic [17:0] SRAM_address;
logic 	SRAM_we_n;
logic [15:0] SRAM_write_data;

assign SRAM_address_o = ((shift_counter + shift_counter_offset) > 5'd15) && top_level_state == PROCESS && PROCESS_state == DECODE && DECODE_state ==RUN ? SRAM_address + 18'd1 : SRAM_address;
assign SRAM_we_n_o = ((shift_counter + shift_counter_offset) > 5'd15) && top_level_state == PROCESS && PROCESS_state == DECODE && DECODE_state ==RUN ? 1'd1 : SRAM_we_n;
assign SRAM_write_data_o = SRAM_write_data;




/////DRAM 3 Var (Q)
logic	[6:0]  address_a3;
logic	[6:0]  address_b3;
logic	  wren_a3;
logic	  wren_b3;
logic	[31:0]  data_a3;
logic	[31:0]  data_b3;
logic [31:0] out_a3;
logic [31:0] out_b3;




/*dual_port_RAM DRAM_3(					////////Q DRAM
	.address_a(address_a3),
	.address_b(address_b3),
	.clock(Clock),
	.data_a(data_a3),
	.data_b(data_b3),
	.wren_a(wren_a3),
	.wren_b(wren_b3),
	.q_a(out_a3),
	.q_b(out_b3)   
);*/









always_comb begin
		sAddress = 6'd0;
		sAddressNext = 6'd0;
		sClip = 3'd0;
		sClipNext = 3'd0;

		case(top_level_state)
			PROCESS:begin
				case(PROCESS_state)
					DECODE:begin
						
							
								case(Q_type)
									1'b0:begin
										case(counter)
											6'd0:begin
												sAddress = 6'd0;
												sAddressNext = 6'd1;
												sClip = 3'd3;
												sClipNext = 3'd2;
											end
											6'd1:begin
												sAddress = 6'd1;
												sAddressNext = 6'd8;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd2:begin
												sAddress = 6'd8;
												sAddressNext = 6'd16;
												sClip = 3'd2;
												sClipNext = 3'd3;
											end
											6'd3:begin
												sAddress = 6'd16;
												sAddressNext = 6'd9;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd4:begin
												sAddress = 6'd9;
												sAddressNext = 6'd2;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd5:begin
												sAddress = 6'd2;
												sAddressNext = 6'd3;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd6:begin
												sAddress = 6'd3;
												sAddressNext = 6'd10;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd7:begin
												sAddress = 6'd10;
												sAddressNext = 6'd17;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd8:begin
												sAddress = 6'd17;
												sAddressNext = 6'd24;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd9:begin
												sAddress = 6'd24;
												sAddressNext = 6'd32;
												sClip = 3'd3;
												sClipNext = 3'd4;
											end
											6'd10:begin
												sAddress = 6'd32;
												sAddressNext = 6'd25;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd11:begin
												sAddress = 6'd25;
												sAddressNext = 6'd18;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd12:begin
												sAddress = 6'd18;
												sAddressNext = 6'd11;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd13:begin
												sAddress = 6'd11;
												sAddressNext = 6'd4;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd14:begin
												sAddress = 6'd4;
												sAddressNext = 6'd5;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd15:begin
												sAddress = 6'd5;
												sAddressNext = 6'd12;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd16:begin
												sAddress = 6'd12;
												sAddressNext = 6'd19;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd17:begin
												sAddress = 6'd19;
												sAddressNext = 6'd26;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd18:begin
												sAddress = 6'd26;
												sAddressNext = 6'd33;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd19:begin
												sAddress = 6'd33;
												sAddressNext = 6'd40;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd20:begin
												sAddress = 6'd40;
												sAddressNext = 6'd48;
												sClip = 3'd4;
												sClipNext = 3'd5;
											end
											6'd21:begin
												sAddress = 6'd48;
												sAddressNext = 6'd41;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd22:begin
												sAddress = 6'd41;
												sAddressNext = 6'd34;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd23:begin
												sAddress = 6'd34;
												sAddressNext = 6'd27;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd24:begin
												sAddress = 6'd27;
												sAddressNext = 6'd20;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd25:begin
												sAddress = 6'd20;
												sAddressNext = 6'd13;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd26:begin
												sAddress = 6'd13;
												sAddressNext = 6'd6;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd27:begin
												sAddress = 6'd6;
												sAddressNext = 6'd7;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd28:begin
												sAddress = 6'd7;
												sAddressNext = 6'd14;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd29:begin
												sAddress = 6'd14;
												sAddressNext = 6'd21;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd30:begin
												sAddress = 6'd21;
												sAddressNext = 6'd28;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd31:begin
												sAddress = 6'd28;
												sAddressNext = 6'd35;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd32:begin
												sAddress = 6'd35;
												sAddressNext = 6'd42;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd33:begin
												sAddress = 6'd42;
												sAddressNext = 6'd49;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd34:begin
												sAddress = 6'd49;
												sAddressNext = 6'd56;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd35:begin
												sAddress = 6'd56;
												sAddressNext = 6'd57;
												sClip = 3'd5;
												sClipNext = 3'd6;
											end
											6'd36:begin
												sAddress = 6'd57;
												sAddressNext = 6'd50;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd37:begin
												sAddress = 6'd50;
												sAddressNext = 6'd43;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd38:begin
												sAddress = 6'd43;
												sAddressNext = 6'd36;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd39:begin
												sAddress = 6'd36;
												sAddressNext = 6'd29;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd40:begin
												sAddress = 6'd29;
												sAddressNext = 6'd22;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd41:begin
												sAddress = 6'd22;
												sAddressNext = 6'd15;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd42:begin
												sAddress = 6'd15;
												sAddressNext = 6'd23;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd43:begin
												sAddress = 6'd23;
												sAddressNext = 6'd30;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd44:begin
												sAddress = 6'd30;
												sAddressNext = 6'd37;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd45:begin
												sAddress = 6'd37;
												sAddressNext = 6'd44;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd46:begin
												sAddress = 6'd44;
												sAddressNext = 6'd51;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd47:begin
												sAddress = 6'd51;
												sAddressNext = 6'd58;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd48:begin
												sAddress = 6'd58;
												sAddressNext = 6'd59;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd49:begin
												sAddress = 6'd59;
												sAddressNext = 6'd52;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd50:begin
												sAddress = 6'd52;
												sAddressNext = 6'd45;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd51:begin
												sAddress = 6'd45;
												sAddressNext = 6'd38;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd52:begin
												sAddress = 6'd38;
												sAddressNext = 6'd31;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd53:begin
												sAddress = 6'd31;
												sAddressNext = 6'd39;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd54:begin
												sAddress = 6'd39;
												sAddressNext = 6'd46;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd55:begin
												sAddress = 6'd46;
												sAddressNext = 6'd53;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd56:begin
												sAddress = 6'd53;
												sAddressNext = 6'd60;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd57:begin
												sAddress = 6'd60;
												sAddressNext = 6'd61;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd58:begin
												sAddress = 6'd61;
												sAddressNext = 6'd54;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd59:begin
												sAddress = 6'd54;
												sAddressNext = 6'd47;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd60:begin
												sAddress = 6'd47;
												sAddressNext = 6'd55;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd61:begin
												sAddress = 6'd55;
												sAddressNext = 6'd62;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd62:begin
												sAddress = 6'd62;
												sAddressNext = 6'd63;
												sClip = 3'd6;
												sClipNext = 3'd6;
											end
											6'd63:begin
												sAddress = 6'd63;
												sAddressNext = 6'd0;
												sClip = 3'd6;
												sClipNext = 3'd0;
											end
											
											
										
										
										endcase
									end
									1'b1:begin
										case(counter)
											6'd0:begin
												sAddress = 6'd0;
												sAddressNext = 6'd1;
												sClip = 3'd3;
												sClipNext = 3'd1;
											end
											6'd1:begin
												sAddress = 6'd1;
												sAddressNext = 6'd8;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd2:begin
												sAddress = 6'd8;
												sAddressNext = 6'd16;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd3:begin
												sAddress = 6'd16;
												sAddressNext = 6'd9;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd4:begin
												sAddress = 6'd9;
												sAddressNext = 6'd2;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd5:begin
												sAddress = 6'd2;
												sAddressNext = 6'd3;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd6:begin
												sAddress = 6'd3;
												sAddressNext = 6'd10;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd7:begin
												sAddress = 6'd10;
												sAddressNext = 6'd17;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd8:begin
												sAddress = 6'd17;
												sAddressNext = 6'd24;
												sClip = 3'd1;
												sClipNext = 3'd1;
											end
											6'd9:begin
												sAddress = 6'd24;
												sAddressNext = 6'd32;
												sClip = 3'd1;
												sClipNext = 3'd2;
											end
											6'd10:begin
												sAddress = 6'd32;
												sAddressNext = 6'd25;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd11:begin
												sAddress = 6'd25;
												sAddressNext = 6'd18;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd12:begin
												sAddress = 6'd18;
												sAddressNext = 6'd11;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd13:begin
												sAddress = 6'd11;
												sAddressNext = 6'd4;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd14:begin
												sAddress = 6'd4;
												sAddressNext = 6'd5;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd15:begin
												sAddress = 6'd5;
												sAddressNext = 6'd12;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd16:begin
												sAddress = 6'd12;
												sAddressNext = 6'd19;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd17:begin
												sAddress = 6'd19;
												sAddressNext = 6'd26;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd18:begin
												sAddress = 6'd26;
												sAddressNext = 6'd33;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd19:begin
												sAddress = 6'd33;
												sAddressNext = 6'd40;
												sClip = 3'd2;
												sClipNext = 3'd2;
											end
											6'd20:begin
												sAddress = 6'd40;
												sAddressNext = 6'd48;
												sClip = 3'd2;
												sClipNext = 3'd3;
											end
											6'd21:begin
												sAddress = 6'd48;
												sAddressNext = 6'd41;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd22:begin
												sAddress = 6'd41;
												sAddressNext = 6'd34;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd23:begin
												sAddress = 6'd34;
												sAddressNext = 6'd27;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd24:begin
												sAddress = 6'd27;
												sAddressNext = 6'd20;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd25:begin
												sAddress = 6'd20;
												sAddressNext = 6'd13;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd26:begin
												sAddress = 6'd13;
												sAddressNext = 6'd6;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd27:begin
												sAddress = 6'd6;
												sAddressNext = 6'd7;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd28:begin
												sAddress = 6'd7;
												sAddressNext = 6'd14;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd29:begin
												sAddress = 6'd14;
												sAddressNext = 6'd21;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd30:begin
												sAddress = 6'd21;
												sAddressNext = 6'd28;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd31:begin
												sAddress = 6'd28;
												sAddressNext = 6'd35;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd32:begin
												sAddress = 6'd35;
												sAddressNext = 6'd42;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd33:begin
												sAddress = 6'd42;
												sAddressNext = 6'd49;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd34:begin
												sAddress = 6'd49;
												sAddressNext = 6'd56;
												sClip = 3'd3;
												sClipNext = 3'd3;
											end
											6'd35:begin
												sAddress = 6'd56;
												sAddressNext = 6'd57;
												sClip = 3'd3;
												sClipNext = 3'd4;
											end
											6'd36:begin
												sAddress = 6'd57;
												sAddressNext = 6'd50;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd37:begin
												sAddress = 6'd50;
												sAddressNext = 6'd43;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd38:begin
												sAddress = 6'd43;
												sAddressNext = 6'd36;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd39:begin
												sAddress = 6'd36;
												sAddressNext = 6'd29;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd40:begin
												sAddress = 6'd29;
												sAddressNext = 6'd22;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd41:begin
												sAddress = 6'd22;
												sAddressNext = 6'd15;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd42:begin
												sAddress = 6'd15;
												sAddressNext = 6'd23;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd43:begin
												sAddress = 6'd23;
												sAddressNext = 6'd30;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd44:begin
												sAddress = 6'd30;
												sAddressNext = 6'd37;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd45:begin
												sAddress = 6'd37;
												sAddressNext = 6'd44;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd46:begin
												sAddress = 6'd44;
												sAddressNext = 6'd51;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd47:begin
												sAddress = 6'd51;
												sAddressNext = 6'd58;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd48:begin
												sAddress = 6'd58;
												sAddressNext = 6'd59;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd49:begin
												sAddress = 6'd59;
												sAddressNext = 6'd52;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd50:begin
												sAddress = 6'd52;
												sAddressNext = 6'd45;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd51:begin
												sAddress = 6'd45;
												sAddressNext = 6'd38;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd52:begin
												sAddress = 6'd38;
												sAddressNext = 6'd31;
												sClip = 3'd4;
												sClipNext = 3'd4;
											end
											6'd53:begin
												sAddress = 6'd31;
												sAddressNext = 6'd39;
												sClip = 3'd4;
												sClipNext = 3'd5;
											end
											6'd54:begin
												sAddress = 6'd39;
												sAddressNext = 6'd46;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd55:begin
												sAddress = 6'd46;
												sAddressNext = 6'd53;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd56:begin
												sAddress = 6'd53;
												sAddressNext = 6'd60;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd57:begin
												sAddress = 6'd60;
												sAddressNext = 6'd61;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd58:begin
												sAddress = 6'd61;
												sAddressNext = 6'd54;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd59:begin
												sAddress = 6'd54;
												sAddressNext = 6'd47;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd60:begin
												sAddress = 6'd47;
												sAddressNext = 6'd55;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd61:begin
												sAddress = 6'd55;
												sAddressNext = 6'd62;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd62:begin
												sAddress = 6'd62;
												sAddressNext = 6'd63;
												sClip = 3'd5;
												sClipNext = 3'd5;
											end
											6'd63:begin
												sAddress = 6'd63;
												sAddressNext = 6'd0;
												sClip = 3'd5;
												sClipNext = 3'd0;
											end
									
									
										endcase
									
									
									
									
								
							
							end
						endcase
					end
				endcase
			end
		endcase
end













always_comb begin
	/////DRAM 3 Default										//C
		address_a3 = 7'd0;
		address_b3 = 7'd0;
		wren_a3 = 1'd0;
		wren_b3 = 1'd0;
		data_a3 = 32'd0;
		data_b3 = 32'd0;
		
		
	/////counter comb offset reset
		shift_counter_offset = 5'd0;
		
	/////write lines
		writeline0 = 9'd0;
		writeline1 = 9'd0;
		
		
	/////EXTERNAL LINES
	external_dram_addy = 7'd0;
	external_dram_wren = 1'd0;
	external_dram_data = 32'd0;
		
		case(top_level_state)
			PROCESS:begin
				case(PROCESS_state)
					DECODE:begin
						case(DECODE_state)
							RUN:begin
								if(zeroes > 6'd0)begin
									data_a3 = 32'd0;
									wren_a3 = 1'd1;
									address_a3 = {1'd0, sAddress};
								
								end else begin
								
								
								
							
							
									case(sBuffer[(31-shift_counter)-:2])
										2'b00:begin
											shift_counter_offset = 5'd8;
											writeline0 = {{29{sBuffer[29-shift_counter]}}, sBuffer[(29-shift_counter)-:3]} << sClip ;
											//writeline1 = {{29{sBuffer[26]}}, sBuffer[(26-shift_counter)-:3]} << sClipNext;
											data_a3 = writeline0;
											//data_b3 = writeline1;
											wren_a3 = 1'd1;
											//wren_b3 = 1'd1;
											address_a3 = {1'd0, sAddress};
											//address_b3 = {1'd0, sAddressNext};
											
										end
										
										2'b01:begin
											shift_counter_offset = 5'd5;
											writeline0 = {{29{sBuffer[29-shift_counter]}}, sBuffer[(29-shift_counter)-:3]} << sClip ;
											data_a3 = writeline0;
											wren_a3 = 1'd1;
											address_a3 = {1'd0, sAddress};
										end
										
										2'b10:begin
											case(sBuffer[(29-shift_counter)])
												1'b0:begin
													shift_counter_offset = 5'd9;
													writeline0 = {{26{sBuffer[28-shift_counter]}}, sBuffer[(28-shift_counter)-:6]} << sClip ;
													data_a3 = writeline0;
													wren_a3 = 1'd1;
													address_a3 = {1'd0, sAddress};
												end
											
												1'b1:begin
													case(sBuffer[(28-shift_counter)])
														1'b0:begin
															shift_counter_offset = 5'd4;
															data_a3 = 32'd0;
															wren_a3 = 1'd1;
															address_a3 = {1'd0, sAddress};
														end
													
														1'b1:begin
															shift_counter_offset = 5'd13;
															testline = {{23{sBuffer[27-shift_counter]}}, sBuffer[(27-shift_counter)-:9]};
															writeline0 = {{23{sBuffer[27-shift_counter]}}, sBuffer[(27-shift_counter)-:9]} << sClip ;
															data_a3 = writeline0;
															wren_a3 = 1'd1;
															address_a3 = {1'd0, sAddress};
														end
													endcase
												
												end
											
											endcase
										
										end
										
										2'b11:begin
											case(sBuffer[(29-shift_counter)-:3])
												3'b000:begin
													shift_counter_offset = 5'd5;
													data_a3 = 32'd0;
													wren_a3 = 1'd1;
													address_a3 = {1'd0, sAddress};
												end
												
												default:begin
													shift_counter_offset = 5'd5;
													data_a3 = 32'd0;
													wren_a3 = 1'd1;
													address_a3 = {1'd0, sAddress};
												end
											endcase
										
										end
									endcase
								end
							end
							
							DELAY1:begin
								if(specialFlag)begin
									data_a3 = specialBuffer;
									wren_a3 = 1'd1;
									address_a3 = {1'd0, sAddress};
								end
							
							
							end
							
						endcase
					end
				endcase
			end
			
			TRANSFER:begin
				case(TRANSFER_state)
					INIT_T_address:begin
						address_a3 = {1'b0,counter};
						wren_a3 = 1'b0;
					end
					SEND_DATA:begin
						external_dram_addy = {1'b0,counter-6'd1};
						address_a3 = {1'b0,counter};
						wren_a3 = 1'b0;
						external_dram_data = out_a3;
						external_dram_wren = 1'b1;
					end
				endcase
			end
		endcase
		
		
		//direct external test
		external_dram_addy = address_a3;
		external_dram_data = data_a3;
		external_dram_wren = wren_a3;
		
		
		
		
		
		
		
end


always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn)begin
		/////ERROR HANDLING
		ERROR <= NONE;
	
		/////FSM States
		top_level_state <= INIT_LDD;
		DEADBEEF_state <= INIT_address;
		PROCESS_state <= BUFFER_FILL1;
		DECODE_state <= RUN;
		TRANSFER_state <= INIT_T_address;
		
		/////High Level Var
		done <= 0;
		
		/////SRAM Var
		SRAM_address <= 18'd0;
		SRAM_we_n <= 1'd1;
		SRAM_write_data <= 16'd0;
		
		/////buffers
		sBuffer <= 32'd0;
		specialBuffer <= 32'd0;
		
		/////counters
		counter <= 6'd0;
		shift_counter <= 5'd0;
		
		//////Quantaization Var
		Q_type <= 1'd0;
		
		//////Num zeroes
		zeroes <= 6'd0;
		
		/////(*__*)
		specialFlag <= 0;
		
	
	end else begin
		if(counter == 6'd63 && (DECODE_state == RUN || (DECODE_state == DELAY1 && specialFlag) ) && top_level_state == PROCESS && PROCESS_state == DECODE && 1==1)begin
			TRANSFER_state <= WTT;
			top_level_state <= TRANSFER;
		end
		
		if(IDCT_done)begin
			/////ERROR HANDLING
			ERROR <= NONE;
		
			/////FSM States
			top_level_state <= INIT_LDD;
			DEADBEEF_state <= INIT_address;
			PROCESS_state <= BUFFER_FILL1;
			DECODE_state <= RUN;
			
			/////High Level Var
			done <= 1;
			
			/////SRAM Var
			SRAM_address <= 18'd76800;
			SRAM_we_n <= 1'd1;
			SRAM_write_data <= 16'd0;
			
			/////buffers
			sBuffer <= 32'd0;
			
			/////counters
			counter <= 6'd0;
			shift_counter <= 5'd0;
			
			//////Quantaization Var
			Q_type <= 1'd0;
			
			//////Num zeroes
			zeroes <= 6'd0;
		
		
		end
	
	
	
		case(top_level_state)
			INIT_LDD:begin
				DEADBEEF_state <= INIT_address;
				if(LDD_en)begin
					top_level_state <= DEADBEEF;
					done <= 0;
				end
			
			end	//end INIT
			
			
			DEADBEEF:begin
				case(DEADBEEF_state)
					INIT_address:begin
						SRAM_address <= 18'd76800;																///Set Dead address
						SRAM_we_n <= 1'd1;
						DEADBEEF_state <= DELAY1;
					end
					DELAY1:begin
						SRAM_address <= SRAM_address + 18'd1;											///Set Beef address
						DEADBEEF_state <= DELAY2;
					end
					DELAY2:begin
						SRAM_address <= SRAM_address + 18'd1;											///Set Q address
						DEADBEEF_state <= DEADBEEF_INTERNAL;
					end
					DEADBEEF_INTERNAL:begin
						if(counter == 6'd0 && SRAM_read_data == 16'hDEAD)begin					///Check Dead
							counter <= counter + 6'd1;
							SRAM_address <= SRAM_address + 18'd2;										///Set Bitsream start address
						end else if(counter == 6'd0)begin
							ERROR <= NOTDEAD;
							top_level_state <= INIT_LDD;
						end
						
						if(counter == 6'd1 && SRAM_read_data == 16'hBEEF)begin					///Check Beef
							counter <= counter + 6'd1;
							SRAM_address <= SRAM_address + 18'd1;										///Set Bitsream next address							
						end else if(counter == 6'd1) begin
							ERROR <= NOTBEEF;
							top_level_state <= INIT_LDD;
						end
						
						if(counter == 6'd2 && SRAM_read_data[15] == 1'd1)begin					///Check quantization
							Q_type <= 1'd1;
							SRAM_address <= SRAM_address + 18'd1;										///Set Bitsream next address again
							counter <= 6'd0;
							top_level_state <= PROCESS;
						end else if(counter == 6'd2 && SRAM_read_data[15] == 1'd0) begin
							Q_type <= 1'd0;
							SRAM_address <= SRAM_address + 18'd1;										///Set Bitsream next address again
							counter <= 6'd0;	
							top_level_state <= PROCESS;
						end
						
						
					
					end	
				
				
				
				endcase	///end DEADBEEF_STATE
			
			
			
			end	///end DEADBEEF
		
		
		
			PROCESS:begin
				case(PROCESS_state)				///ADD WAIT
					
					
					BUFFER_FILL1:begin
						sBuffer[31:16] <= SRAM_read_data;
						PROCESS_state <= BUFFER_FILL2;
					end
					BUFFER_FILL2:begin
						sBuffer[15:0] <= SRAM_read_data;
						PROCESS_state <= DECODE;
					end
					DECODE:begin
						case(DECODE_state)
							
						
							RUN:begin
								if(zeroes > 6'd0)begin
								counter <= counter + 6'd1;
								zeroes <= zeroes - 6'd1;
								end else begin
								
									counter <= counter + 6'd1;
									
									case(sBuffer[(31-shift_counter)-:2])
										2'b00:begin																	////00
											counter <= counter + 6'd1;
											specialBuffer <= {{29{sBuffer[26-shift_counter]}}, sBuffer[(26-shift_counter)-:3]} << sClipNext;
											specialFlag <= 1;
											shift_counter <= shift_counter + 5'd8;
											
										end
										
										2'b01:begin
										;	//////write next 3bit value
											shift_counter <= shift_counter + 5'd5;
											
										end
										
										2'b10:begin																	////10
											shift_counter <= shift_counter + 5'd1;
											case(sBuffer[(29-shift_counter)])
												1'b0:begin
													;	//////write next 6bit value
												
													shift_counter <= shift_counter + 5'd9;
													
												end
											
												1'b1:begin
													
													case(sBuffer[(28-shift_counter)])
														1'b0:begin
															zeroes <= 6'd63 - counter; 
															shift_counter <= shift_counter + 5'd4;
														end
													
														1'b1:begin
															;	//////write next 9bit value
												
															shift_counter <= shift_counter + 5'd13;
										
														end
													endcase
												
												end
											
											endcase
										
										end
										
										2'b11:begin
											
											case(sBuffer[(29-shift_counter)-:3])
												3'b000:begin
													zeroes <= 6'd7;	//write one zero this state
													shift_counter <= shift_counter + 5'd5;
												end
												
												default:begin
													zeroes <= 6'd0 + {3'd0, sBuffer[(29-shift_counter)-:3]}  - 6'd1;
													shift_counter <= shift_counter + 5'd5;
												
												end
											
											
											endcase
										
										end
										
									
									
									
									
									endcase
									
									if((shift_counter + shift_counter_offset) > 5'd15)begin
										SRAM_address <= SRAM_address + 18'd1;
										sBuffer <= {sBuffer[15:0] , SRAM_read_data};								/////////////////////////////////////could be causing major problems
										shift_counter <= shift_counter - 5'd16 + shift_counter_offset;
									
									end
									
									
								end
								
								
								
								DECODE_state <= SDELAY1;
								
								
								
								
							end
							
							SDELAY1:begin
							DECODE_state <= RUN;
							specialFlag <= 0;
								if(specialFlag)begin
									counter <= counter + 6'd1;
								end
							end
							
							/*SDELAY2:begin
							DECODE_state <= RUN;
							SRAM_read_data <= SRAM_read_data_i;
							end*/
						endcase
					end
					
					
				endcase
			end
			
			TRANSFER:begin
				case(TRANSFER_state)
					INIT_T_address:begin
						counter <= counter + 6'd1;
						TRANSFER_state <= SEND_DATA;
					end
					SEND_DATA:begin
						if(counter == 6'd0)
							TRANSFER_state <= WAIT;
						else
							counter <= counter + 6'd1;
					end
					WAIT:begin
						if(IDCT_TLS == 2'd1)begin
							top_level_state <= PROCESS;
							PROCESS_state <= DECODE;
							DECODE_state <= RUN;
						end
					
					
					end
					
					WTT:begin
						if(IDCT_TLS == 2'd2)begin
							top_level_state <= TRANSFER;
							TRANSFER_state <= WAIT;
						end
					end
				endcase
			
			
			
			end
		
		
		
		
		
		
		endcase		///end top_level_state
	end
end














endmodule