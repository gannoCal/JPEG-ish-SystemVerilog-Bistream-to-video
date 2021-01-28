`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


module IDCT (
	input  logic            Clock,
   input  logic            Resetn,
	input  logic 				IDCT_en,
	
	output wire   [17:0]   SRAM_address_o,
	output  wire   [15:0]   SRAM_write_data_o,
   input  wire   [15:0]   SRAM_read_data,
	output wire SRAM_we_n_o ,
	
	input [6:0] LDD_dram_addy,
	input [31:0] LDD_dram_data,
	input LDD_dram_wren,
	
	input integrated,
	
	output enum logic [1:0] {
		INIT_IDCT,
		LOAD_S_COMPUTE_S,
		COMPUTE_T_STORE_S
	} top_level_state,
	
	input logic [1:0]  LDD_TLS,
	
	input logic [1:0] LDD_DECODE_S,
	
	input logic [17:0] LDD_sram_addy,
	
	output logic done
	
	
);


////ERROR HANDLING
enum logic [1:0] {
	NONE,
	COMPUTE_T_ERROR
} ERROR;


////FSM States 
/*enum logic [1:0] {
	INIT,
	LOAD_S_COMPUTE_S,
	COMPUTE_T_STORE_S
} top_level_state;*/

enum logic [2:0] {
	INIT_address,
	DELAY1,
	DELAY2,
	LOAD_S_INTERNAL,
	DONE_LOAD
} LOAD_S_state;

enum logic [1:0] {
	INITIAL,
	BUFFER,
	WRITE,
	DONE_STORE
} STORE_S_state;

enum logic [1:0] {
	INIT_READ_T,
	COMPUTE_T
} COMPUTE_T_state;

enum logic [1:0] {
	INIT_READ_S,
	COMPUTE_S
} COMPUTE_S_state;


////Generic States

enum logic [1:0] {
	Y,
	U,
	V
} PROCESSING;

/////High-Level INIT/DONE Flags
logic first_megastate;


/////SRAM Var
logic [17:0] SRAM_address;
logic 	SRAM_we_n;
logic [15:0] SRAM_write_data;

/////High-Level Block Trackers
logic [17:0] Pre_address_tracker;
logic [5:0] Pre_row_tracker;
logic [16:0] post_address_tracker;
logic [5:0] post_row_tracker;


/////DRAM 0 Var (C)
logic	[6:0]  address_a0;
logic	[6:0]  address_b0;
logic	  wren_a0;
logic	  wren_b0;
logic	[31:0]  data_a0;
logic	[31:0]  data_b0;
logic [31:0] out_a0;
logic [31:0] out_b0;

/////DRAM 1 Var (S)
logic	[6:0]  address_a1;
logic	[6:0]  address_b1;
logic	  wren_a1;
logic	  wren_b1;
logic	[31:0]  data_a1;
logic	[31:0]  data_b1;
logic [31:0] out_a1;
logic [31:0] out_b1;

/////DRAM 2 Var (T)
logic	[6:0]  address_a2;
logic	[6:0]  address_b2;
logic	  wren_a2;
logic	  wren_b2;
logic	[31:0]  data_a2;
logic	[31:0]  data_b2;
logic [31:0] out_a2;
logic [31:0] out_b2;


///Comb Wires
logic [31:0] sum0;
logic [31:0] sum1;



/////Load DRAM Var
logic [4:0] i_block_counter;
logic [5:0] j_block_counter;
logic [2:0] j_internal_counter;
logic [6:0] internal_load_counter;

/////Store DRAM Var
logic [2:0] row_counter;
logic [6:0] read_counter;
logic [7:0] write_buffer;



///////////////Compute Var

/////Accumulators
logic [31:0] accumlator0;
logic [31:0] accumlator1;
logic [31:0] accumlator2;
logic [31:0] accumlator3;

/////Counters
logic [2:0] state_counter;
logic [5:0] S_grab_counter;
logic [5:0] C_grab_counter0;
logic [5:0] C_grab_counter1;
logic [5:0] T_write_counter;

/////Buffers
logic [31:0] T_write_buffer0;
logic [31:0] T_write_buffer1;
logic [31:0] T_write_buffer2;

/////Flags
logic initial_compute_T;

/////Flip-Flops
logic flip_flop;			





dual_port_RAM DRAM_0(					////////C DRAM
	.address_a(address_a0),
	.address_b(address_b0),
	.clock(Clock),
	.data_a(data_a0),
	.data_b(data_b0),
	.wren_a(wren_a0),
	.wren_b(wren_b0),
	.q_a(out_a0),
	.q_b(out_b0)   
);

dual_port_RAM DRAM_1(					////////S DRAM
	.address_a(address_a1),
	.address_b(address_b1),
	.clock(Clock),
	.data_a(data_a1),
	.data_b(data_b1),
	.wren_a(wren_a1),
	.wren_b(wren_b1),
	.q_a(out_a1),
	.q_b(out_b1)   
);

dual_port_RAM DRAM_2(					////////T DRAM
	.address_a(address_a2),
	.address_b(address_b2),
	.clock(Clock),
	.data_a(data_a2),
	.data_b(data_b2),
	.wren_a(wren_a2),
	.wren_b(wren_b2),
	.q_a(out_a2),
	.q_b(out_b2)   
);





//////////////Multipliers


/////Multiplier Var
logic [31:0] op1_0;
logic [31:0] op2_0;
reg [31:0] mult_result_0;

logic [31:0] op1_1;
logic [31:0] op2_1;
reg [31:0] mult_result_1;

logic [31:0] op1_2;
logic [31:0] op2_2;
reg [31:0] mult_result_2;

logic [31:0] op1_3;
logic [31:0] op2_3;
reg [31:0] mult_result_3;


Multiplier mult_unit_0 (							//C0
.Mult_op_1(op1_0),
.Mult_op_2(op2_0),
.Mult_result(mult_result_0)

);


Multiplier mult_unit_1 (							//C1
.Mult_op_1(op1_1),
.Mult_op_2(op2_1),
.Mult_result(mult_result_1)

);


Multiplier mult_unit_2 (							//C2
.Mult_op_1(op1_2),
.Mult_op_2(op2_2),
.Mult_result(mult_result_2)

);


Multiplier mult_unit_3 (							//C3
.Mult_op_1(op1_3),
.Mult_op_2(op2_3),
.Mult_result(mult_result_3)

);



//assign SRAM_address_o = LDD_DECODE_S == 2'd2 && top_level_state == COMPUTE_T_STORE_S && STORE_S_state == WRITE ? (SRAM_address + 18'd1) : SRAM_address;
//assign SRAM_we_n_o = LDD_DECODE_S == 2'd2 && top_level_state == COMPUTE_T_STORE_S && STORE_S_state == WRITE ? 1'b0 : SRAM_we_n;
//assign SRAM_write_data_o = LDD_DECODE_S == 2'd2 && top_level_state == COMPUTE_T_STORE_S && STORE_S_state == WRITE ? '{write_buffer[7],write_buffer[6],write_buffer[5],write_buffer[4],write_buffer[3],write_buffer[2],write_buffer[1],write_buffer[0],out_b1[7],out_b1[6],out_b1[5],out_b1[4],out_b1[3],out_b1[2],out_b1[1],out_b1[0]} : SRAM_write_data;

assign SRAM_address_o = integrated && (top_level_state == COMPUTE_T_STORE_S && T_write_counter == 6'd62 ) ? LDD_sram_addy : SRAM_address;
assign SRAM_we_n_o = integrated && (top_level_state == COMPUTE_T_STORE_S && T_write_counter == 6'd62 ) ? 1'd1 : SRAM_we_n;
assign SRAM_write_data_o = SRAM_write_data;




///////Comb 0

always_comb begin
		//Multiplication Default
		op1_0 = 32'd0;
		op1_1 = 32'd0;
		op1_2 = 32'd0;
		op1_3 = 32'd0;
		op2_0 = 32'd0;
		op2_1 = 32'd0;
		op2_2 = 32'd0;
		op2_3 = 32'd0;
		
		/////DRAM 0 Default										//C
		address_a0 = 7'd0;
		address_b0 = 7'd0;
		wren_a0 = 1'd0;
		wren_b0 = 1'd0;
		data_a0 = 32'd0;
		data_b0 = 32'd0;
		
		
		/////DRAM 1 Default										//S
		address_a1 = 7'd0;
		address_b1 = 7'd0;
		wren_a1 = 1'd0;
		wren_b1 = 1'd0;
		data_a1 = 32'd0;
		data_b1 = 32'd0;
		
		/////DRAM 2 Default										//T
		address_a2 = 7'd0;
		address_b2 = 7'd0;
		wren_a2 = 1'd0;
		wren_b2 = 1'd0;
		data_a2 = 32'd0;
		data_b2 = 32'd0;
		
		sum0 = 32'd0;
		sum1 = 32'd0;

		

	case(top_level_state)
		LOAD_S_COMPUTE_S:begin
		//COMPUTE_S PROCESSES
				op1_0 = {{8{out_a2[23]}},out_a2[23:0]};
				op1_1 = {{8{out_a2[23]}},out_a2[23:0]};
				op1_2 = {{8{out_a2[23]}},out_a2[23:0]};
				op1_3 = {{8{out_a2[23]}},out_a2[23:0]};
				wren_a1 = 1'd0;														//Disable Write (S)
				wren_a0 = 1'd0;														//Disable Write (Ca)
				wren_b0 = 1'd0;	
		
		
		
			if(!integrated)begin
				//LOAD_S PROCESSES
				case(LOAD_S_state)
					LOAD_S_INTERNAL:begin
						address_a1 = internal_load_counter;
						data_a1 = SRAM_read_data;
						wren_a1 = 1'd1;
					end
				
				endcase
			end else begin
				address_a1 = LDD_dram_addy;
				wren_a1 = LDD_dram_wren;
				data_a1 = LDD_dram_data;
			
			
			
			end
			
			
			
																//Disable Write (Cb)	
			
			//COMPUTE_S PROCESSES
			case(COMPUTE_S_state)
				INIT_READ_S:begin
					address_a2 = S_grab_counter;
					address_a0 = C_grab_counter0;
					address_b0 = C_grab_counter1;
				end
				COMPUTE_S:begin
					case(state_counter)
							3'd0:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;					
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								if(!initial_compute_T)begin
									address_b1 = {1'd0,T_write_counter} + 7'd64;
									wren_b1 = 1'd1;
									if(T_write_buffer0[31])
										data_b1 = 32'd0;
									else if(|T_write_buffer0[30:24])
										data_b1 = 32'd255;
									else
										data_b1 = {16'd0,T_write_buffer0[31:16]};
								end
								
									
							end
							3'd1:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								if(!initial_compute_T)begin
									address_b1 = {1'd0,T_write_counter} + 7'd64;
									wren_b1 = 1'd1;
									if(T_write_buffer1[31])
										data_b1 = 32'd0;
									else if(|T_write_buffer1[30:24])
										data_b1 = 32'd255;
									else
										data_b1 = {16'd0,T_write_buffer1[31:16]};
								end
								
							
							end
							3'd2:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								if(!initial_compute_T)begin
									address_b1 = {1'd0,T_write_counter} + 7'd64;
									wren_b1 = 1'd1;
									if(T_write_buffer2[31])
										data_b1 = 32'd0;
									else if(|T_write_buffer2[30:24])
										data_b1 = 32'd255;
									else
										data_b1 = {16'd0,T_write_buffer2[31:16]};
								end
								
							
							end
							3'd3:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd4:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd5:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd6:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd7:begin
								address_a2 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								address_b1 = {1'd0,T_write_counter} + 7'd64;
								wren_b1 = 1'd1;
								
								sum0 = accumlator0 + mult_result_0;
								
								if(sum0[31])
									data_b1 = 32'd0;
								else if(|sum0[30:24])
									data_b1 = 32'd255;
								else
									data_b1 = {16'd0,sum0[31:16]};
								
							
							end
						
						
						
						
						endcase
					end
						
						
			
			endcase
		
		
		
		end
		COMPUTE_T_STORE_S:begin
			//COMPUTE_T PROCESSES
			op1_0 = {{16{out_a1[15]}},out_a1[15:0]};
			op1_1 = {{16{out_a1[15]}},out_a1[15:0]};
			op1_2 = {{16{out_a1[15]}},out_a1[15:0]};
			op1_3 = {{16{out_a1[15]}},out_a1[15:0]};
			
			wren_a1 = 1'd0;														//Disable Write (S)
			wren_a0 = 1'd0;														//Disable Write (Ca)
			wren_b0 = 1'd0;														//Disable Write (Cb)																	
			case(COMPUTE_T_state)
				INIT_READ_T:begin
					address_a1 = S_grab_counter;
					address_a0 = C_grab_counter0;
					address_b0 = C_grab_counter1;
				end
				COMPUTE_T:begin
					case(state_counter)
							3'd0:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;					
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								if(!initial_compute_T)begin
									address_a2 = T_write_counter;
									address_b2 = T_write_counter + 6'd1;
									wren_a2 = 1'd1;
									wren_b2 = 1'd1;
									data_a2 = {8'd0,T_write_buffer0[31:8]};
									data_b2 = {8'd0,T_write_buffer1[31:8]};
								end
								
									
							end
							3'd1:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd2:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd3:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd4:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd5:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd6:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
							
							end
							3'd7:begin
								address_a1 = S_grab_counter;
								address_a0 = C_grab_counter0;
								address_b0 = C_grab_counter1;
								
								op2_0 = {{16{out_a0[31]}},out_a0[31:16]};	//C0
								op2_1 = {{16{out_a0[15]}},out_a0[15:0]};	//C1
								op2_2 = {{16{out_b0[31]}},out_b0[31:16]};	//C2
								op2_3 = {{16{out_b0[15]}},out_b0[15:0]};	//C3
								
								address_a2 = T_write_counter;
								address_b2 = T_write_counter + 6'd1;
								wren_a2 = 1'd1;
								wren_b2 = 1'd1;
								sum0 =accumlator0 + mult_result_0;
								sum1 =accumlator1 + mult_result_1;
								
								data_a2 = {8'd0,sum0[31:8]};
								data_b2 = {8'd0,sum1[31:8]};
								
							
							end
						
						
						
						
						endcase
					end
			endcase
			
			//STORE_S PROCESSES
			case(STORE_S_state)
				INITIAL:begin
					wren_b1 = 1'd0;
					address_b1 = read_counter + 7'd64;
				end
				BUFFER:begin
					wren_b1 = 1'd0;
					address_b1 = read_counter + 7'd67;
				end
				WRITE:begin
					wren_b1 = 1'd0;
					address_b1 = read_counter + 7'd67;
					
				end
			
			endcase
			
		
		
		end
	
	
	
	endcase




end


///////State Machine 0
always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn)begin
		//Error handling
		ERROR <= NONE;
		top_level_state <= INIT_IDCT;	
		LOAD_S_state <= INIT_address;
		STORE_S_state <= INITIAL;
		COMPUTE_T_state <= INIT_READ_T;
		COMPUTE_S_state <= INIT_READ_S;
		
		/////// SRAM
		internal_load_counter <= 7'd0;
		i_block_counter <= 5'd0;
		j_block_counter <= 6'd0;
		j_internal_counter <= 3'd0;
		PROCESSING <= Y;
		
		
		///////////Compute
		accumlator0 <= 32'd0;
		accumlator1 <= 32'd0;
		accumlator2 <= 32'd0;
		accumlator3 <= 32'd0;
		
		state_counter <= 3'd0;
		S_grab_counter <= 6'd0;
		C_grab_counter0 <= 6'd0;
		C_grab_counter1 <= 6'd1;
		T_write_counter <= 6'd0;
		T_write_buffer0 <= 32'd0;
		T_write_buffer1 <= 32'd0;
		T_write_buffer2 <= 32'd0;

		//Flags
		initial_compute_T <= 0;
		
		//Flip Flop
		flip_flop <= 0;
		
		/////High-Level Block Trackers
		Pre_address_tracker <= 18'd0;
		post_address_tracker <= 17'd0;
		Pre_row_tracker <= 5'd0;
		post_row_tracker<= 5'd0;
		
		/////High-Level INIT/DONE Flags
      first_megastate <= 1;
		done <= 0;
		
		/////Store DRAM Var
		row_counter <= 2'd0;
		read_counter <= 6'd0;
		write_buffer <= 8'd0;

		
		

	end else begin
		if(SRAM_address == 17'd76799 && SRAM_we_n == 1'd0)begin
			done <= 1;
			top_level_state <= INIT_IDCT;
		end
	
		case(top_level_state)
			INIT_IDCT: begin
			
			if(!integrated)begin
				if(IDCT_en)begin
					top_level_state <= LOAD_S_COMPUTE_S;
					LOAD_S_state <= INIT_address;
				end
			end else begin
				if(LDD_TLS == 2'd2)begin
					top_level_state <= LOAD_S_COMPUTE_S;
					LOAD_S_state <= INIT_address;
				end
			
			
			end
				
				
			end
			
			LOAD_S_COMPUTE_S:begin
				//Transition Case
				if(T_write_counter == 6'd63)begin
					internal_load_counter <= 7'd0;
					j_internal_counter <= 3'd0;		
					COMPUTE_T_state <= INIT_READ_T;
					STORE_S_state <= INITIAL;
					state_counter <= 3'd0;
					top_level_state <= COMPUTE_T_STORE_S;
					S_grab_counter <= 6'd0;
					C_grab_counter0 <= 6'd0;
					C_grab_counter1 <= 6'd1;
					if(!integrated)begin
						Pre_row_tracker <= Pre_row_tracker + 6'd1;
						if(Pre_address_tracker < 18'd76800)begin
							if(Pre_row_tracker == 6'd39)begin
								Pre_row_tracker <= 6'd0;
								Pre_address_tracker <= Pre_address_tracker + 18'd2248;
							end else
								Pre_address_tracker <= Pre_address_tracker + 18'd8;
						end else begin
							if(Pre_row_tracker == 6'd19)begin
								Pre_row_tracker <= 6'd0;
								Pre_address_tracker <= Pre_address_tracker + 18'd1128;
							end else
								Pre_address_tracker <= Pre_address_tracker + 18'd8;
						
						
						
						
						end
					end
				end
				
				
				if(!integrated)begin
					//LOAD_S PROCESSES
					case(LOAD_S_state)
						INIT_address:begin
							SRAM_address <= 18'd76800 + Pre_address_tracker; ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
							SRAM_we_n <= 1'd1;
							LOAD_S_state <= DELAY1;
						end
						DELAY1:begin
							SRAM_address <= SRAM_address + 18'd1;
							j_internal_counter <= j_internal_counter + 3'd1;
							LOAD_S_state <= DELAY2;
						end
						DELAY2:begin
							SRAM_address <= SRAM_address + 18'd1;
							j_internal_counter <= j_internal_counter + 3'd1;
							LOAD_S_state <= LOAD_S_INTERNAL;
						end
						LOAD_S_INTERNAL:begin
							if(internal_load_counter < 7'd63 )begin
								if(j_internal_counter < 3'd7) begin
									SRAM_address <= SRAM_address + 18'd1;
									j_internal_counter <= j_internal_counter + 3'd1;
								end else begin
									if(Pre_address_tracker < 18'd76800)begin
									SRAM_address <= SRAM_address + 18'd313;
									end else begin
									SRAM_address <= SRAM_address + 18'd153;
									end
									j_internal_counter <= 3'd0;
								end
								internal_load_counter <= internal_load_counter + 3'd1;
								
							end else begin
								if(!first_megastate)
									LOAD_S_state <= DONE_LOAD;
								else begin
									internal_load_counter <= 7'd0;
									j_internal_counter <= 3'd0;		
									COMPUTE_T_state <= INIT_READ_T;
									STORE_S_state <= INITIAL;
									state_counter <= 3'd0;
									top_level_state <= COMPUTE_T_STORE_S;
									S_grab_counter <= 6'd0;
									C_grab_counter0 <= 3'd0;
									C_grab_counter1 <= 3'd1;
									Pre_row_tracker <= Pre_row_tracker + 6'd1;
									if(Pre_address_tracker < 18'd153600)begin
										if(Pre_row_tracker == 6'd39)begin
											Pre_row_tracker <= 6'd0;
											Pre_address_tracker <= Pre_address_tracker + 18'd2248;
										end else
											Pre_address_tracker <= Pre_address_tracker + 18'd8;
									end else begin
										if(Pre_row_tracker == 6'd19)begin
											Pre_row_tracker <= 6'd0;
											Pre_address_tracker <= Pre_address_tracker + 18'd1128;
										end else
											Pre_address_tracker <= Pre_address_tracker + 18'd8;
									
									end
								end
							end
						end
						DONE_LOAD:begin
							internal_load_counter <= 7'd0;
							j_internal_counter <= 3'd0;																					//WAIT FOR COMPUTE TO FINISH
						end
					endcase
				end else begin
					if(!first_megastate)
									;
					else begin
						if(LDD_dram_addy == 7'd63)begin
							internal_load_counter <= 7'd0;
							j_internal_counter <= 3'd0;		
							COMPUTE_T_state <= INIT_READ_T;
							STORE_S_state <= INITIAL;
							state_counter <= 3'd0;
							top_level_state <= COMPUTE_T_STORE_S;
							S_grab_counter <= 6'd0;
							C_grab_counter0 <= 3'd0;
							C_grab_counter1 <= 3'd1;
						end
						
					end
				
	
				
				
				
				
				
				end
				
				
				
				
				if(!first_megastate)begin
					//COMPUTE_S PROCESSES
					case(COMPUTE_S_state)
						INIT_READ_S:begin
							S_grab_counter <= S_grab_counter + 6'd8;
							C_grab_counter0 <= C_grab_counter0 + 6'd4;
							C_grab_counter1 <= C_grab_counter1 + 6'd4;
							COMPUTE_S_state <= COMPUTE_S;
							initial_compute_T <= 1;
							flip_flop <= 0;
							accumlator0 <= 32'd0;
							accumlator1 <= 32'd0;
							accumlator2 <= 32'd0;
							accumlator3 <= 32'd0;
							state_counter <= 3'd0;
							T_write_counter <= 6'd0;
						end
					
					
					
						COMPUTE_S:begin
							case(state_counter)
								3'd0:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
									if(!initial_compute_T)begin
										T_write_counter <= T_write_counter + 6'd8;
									end
								
								end
								3'd1:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
									if(!initial_compute_T)begin
										T_write_counter <= T_write_counter + 6'd8;
									end
								end
								3'd2:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
									if(!initial_compute_T)begin
										if(flip_flop)
											T_write_counter <= T_write_counter + 6'd8;
										else
											T_write_counter <= T_write_counter - 6'd55;
									end
									if(T_write_counter == 6'd63)begin
										state_counter <= 3'd0;
										S_grab_counter <= 6'd0;
										C_grab_counter0 <= 6'd0;
										C_grab_counter1 <= 6'd1;
									end
								end
								3'd3:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
								end
								3'd4:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
								end
								3'd5:begin
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
								end
								3'd6:begin
									
									accumlator0 <= accumlator0 + mult_result_0;
									accumlator1 <= accumlator1 + mult_result_1; 
									accumlator2 <= accumlator2 + mult_result_2;
									accumlator3 <= accumlator3 + mult_result_3;
									state_counter <= state_counter + 1;
									if(!flip_flop)begin
										S_grab_counter <= S_grab_counter - 6'd56;
										C_grab_counter0 <= 6'd2;
										C_grab_counter1 <= 6'd3;
									end else begin
										S_grab_counter <= S_grab_counter - 6'd55;
										C_grab_counter0 <= 6'd0;
										C_grab_counter1 <= 6'd1;
									end
									
								end
								3'd7:begin
									accumlator0 <= 32'd0;
									accumlator1 <= 32'd0;
									accumlator2 <= 32'd0;
									accumlator3 <= 32'd0;
									T_write_buffer0 <= accumlator1 + mult_result_1;
									T_write_buffer1 <= accumlator2 + mult_result_2;
									T_write_buffer2 <= accumlator3 + mult_result_3;
									initial_compute_T <= 0;
									state_counter <= 0;
									T_write_counter <= T_write_counter + 6'd8;
									flip_flop <= ~flip_flop;									//flip-flop the flip_flop *flip_flop*
									S_grab_counter <= S_grab_counter + 6'd8;
									C_grab_counter0 <= C_grab_counter0 + 6'd4;
									C_grab_counter1 <= C_grab_counter1 + 6'd4;
								end
							
							
							
							
							endcase
						end
					
					endcase
				end
			end
		
			COMPUTE_T_STORE_S:begin
				//Transition Case
				if(T_write_counter == 6'd62)begin
					internal_load_counter <= 7'd0;
					j_internal_counter <= 3'd0;		
					LOAD_S_state <= INIT_address;
					COMPUTE_S_state <= INIT_READ_S;
					state_counter <= 3'd0;
					S_grab_counter <= 6'd0;
					C_grab_counter0 <= 6'd0;
					C_grab_counter1 <= 6'd1;
					if(!first_megastate)begin
						post_row_tracker <= post_row_tracker + 6'd1;
						if(post_address_tracker < 17'd38400)begin
							if(post_row_tracker == 6'd39)begin
								post_row_tracker <= 6'd0;
								post_address_tracker <= post_address_tracker + 17'd1124;
							end else
								post_address_tracker <= post_address_tracker + 17'd4;
						end else begin
							if(post_row_tracker == 6'd19)begin
								post_row_tracker <= 6'd0;
								post_address_tracker <= post_address_tracker + 17'd564;
							end else
								post_address_tracker <= post_address_tracker + 17'd4;
						
						end
						
						/*if(post_address_tracker >= 17'd76164)begin
							done <= 1;
							top_level_state <= INIT;
						end else begin*/
							top_level_state <= LOAD_S_COMPUTE_S;
						
						//end
					end else begin
						top_level_state <= LOAD_S_COMPUTE_S;
						first_megastate <= 0;
					end
				end
				
				
				if(!first_megastate)begin
				//STORE_S PROCESSES
					case(STORE_S_state)
						INITIAL:begin
							STORE_S_state <= BUFFER;
							SRAM_address <= {1'd0,post_address_tracker}-18'd1; ////////////////////////////
							row_counter <= 3'b111;
							read_counter <= 7'd126;
							SRAM_we_n <= 1'd1;
						end
						BUFFER:begin
							write_buffer <= '{out_b1[7],out_b1[6],out_b1[5],out_b1[4],out_b1[3],out_b1[2],out_b1[1],out_b1[0]};
							read_counter <= read_counter + 6'd1;
							STORE_S_state <= WRITE;
							
						end
						WRITE:begin
							
								if(row_counter == 3'd3) begin
									if(post_address_tracker < 17'd38400)begin
									SRAM_address <= SRAM_address + 18'd157;
									end else begin
									SRAM_address <= SRAM_address + 18'd77;
									end
									row_counter <= 3'd0;
								end else begin
									SRAM_address <= SRAM_address + 18'd1;
									row_counter <= row_counter +3'd1;
								end
								SRAM_we_n <= 1'd0;
								SRAM_write_data <= '{write_buffer[7],write_buffer[6],write_buffer[5],write_buffer[4],write_buffer[3],write_buffer[2],write_buffer[1],write_buffer[0],out_b1[7],out_b1[6],out_b1[5],out_b1[4],out_b1[3],out_b1[2],out_b1[1],out_b1[0]};
							
							read_counter <= read_counter + 6'd1;
							STORE_S_state <= BUFFER;
							
							if(read_counter == 6'd61 && SRAM_we_n == 1'd0)begin
								STORE_S_state <= DONE_STORE;
								
							end
						end
						DONE_STORE:begin
						internal_load_counter <= 7'd0;
						j_internal_counter <= 3'd0;
						read_counter <= 7'd0;						//WAIT FOR COMPUTE TO FINISH
						row_counter <= 3'd0;
						SRAM_we_n <= 1'd1;
						end
					
					endcase
				end
				
				
			
				//COMPUTE_T PROCESSES
				case(COMPUTE_T_state)
					INIT_READ_T:begin
						S_grab_counter <= S_grab_counter + 6'd1;
						C_grab_counter0 <= C_grab_counter0 + 6'd4;
						C_grab_counter1 <= C_grab_counter1 + 6'd4;
						COMPUTE_T_state <= COMPUTE_T;
						initial_compute_T <= 1;
						flip_flop <= 0;
						accumlator0 <= 32'd0;
						accumlator1 <= 32'd0;
						accumlator2 <= 32'd0;
						accumlator3 <= 32'd0;
						state_counter <= 3'd0;
						T_write_counter <= 6'd0;
					end
				
				
				
					COMPUTE_T:begin
						case(state_counter)
							3'd0:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
								if(!initial_compute_T)begin
									T_write_counter <= T_write_counter + 6'd2;
								end
								
								if(T_write_counter == 6'd62)begin
								state_counter <= 3'd0;
								S_grab_counter <= 6'd0;
								C_grab_counter0 <= 6'd0;
								C_grab_counter1 <= 6'd1;
								end
							end
							3'd1:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
							end
							3'd2:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
							end
							3'd3:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
							end
							3'd4:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
							end
							3'd5:begin
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
							end
							3'd6:begin
								
								accumlator0 <= accumlator0 + mult_result_0;
								accumlator1 <= accumlator1 + mult_result_1; 
								accumlator2 <= accumlator2 + mult_result_2;
								accumlator3 <= accumlator3 + mult_result_3;
								state_counter <= state_counter + 1;
								if(!flip_flop)begin
									S_grab_counter <= S_grab_counter - 6'd7;
									C_grab_counter0 <= 6'd2;
									C_grab_counter1 <= 6'd3;
								end else begin
									S_grab_counter <= S_grab_counter + 6'd1;
									C_grab_counter0 <= 6'd0;
									C_grab_counter1 <= 6'd1;
								end
								
							end
							3'd7:begin
								accumlator0 <= 32'd0;
								accumlator1 <= 32'd0;
								accumlator2 <= 32'd0;
								accumlator3 <= 32'd0;
								T_write_buffer0 <= accumlator2 + mult_result_2;
								T_write_buffer1 <= accumlator3 + mult_result_3;
								initial_compute_T <= 0;
								state_counter <= 0;
								T_write_counter <= T_write_counter + 6'd2;
								flip_flop <= ~flip_flop;									//flip-flop the flip_flop *flip_flop*
								S_grab_counter <= S_grab_counter + 6'd1;
								C_grab_counter0 <= C_grab_counter0 + 6'd4;
								C_grab_counter1 <= C_grab_counter1 + 6'd4;
							end
						
						
						
						
						endcase
					end
				endcase
				
			end
		
		
		endcase
		
		
		
		
		
	
	end



end





endmodule