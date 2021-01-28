`define SHIFT 9'd6
`define BFZERO 0
`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif



module ColorspaceConversion_Interpolation (
	input  logic            Clock,
   input  logic            Resetn,
	input  logic 				CSI_en,
	
	
   output wire   [17:0]   SRAM_address_o,
	output  wire   [15:0]   SRAM_write_data_o,
   input  wire   [15:0]   SRAM_read_data,
	output wire SRAM_we_n_o,
	output enum logic [0:2] {
	Normal,
	InitInterpolFail
	
	}errorCode,
	
	output logic   done,
	
	output logic [8:0] CSC_x,
	output logic [7:0] CSC_y

	
);


logic flip_flop;
logic force_state;



//CsC Var
logic reset_CS_e;
logic enable_CS_e;
wire [31:0] Y_e;
reg [31:0] U_e;
reg [31:0] V_e;
logic R_flag_e;
logic G_flag_e;
logic B_flag_e;

logic [7:0] Ro_e;
logic [7:0] Go_e;
logic [7:0] Bo_e;

wire [7:0] nexteven_U;



logic reset_CS_o;
logic enable_CS_o;
wire [31:0] Y_o;
logic [31:0] U_o;
logic [31:0] V_o;
logic R_flag_o;
logic G_flag_o;
logic B_flag_o;

logic [7:0] Ro_o;
logic [7:0] Go_o;
logic [7:0] Bo_o;

wire [7:0] nexteven_V;

assign U_e[31:8] = 24'd0;
assign V_e[31:8] = 24'd0;

//pixel Var
logic [8:0] x_counter;
logic [7:0] y_counter;

assign CSC_x = x_counter;
assign CSC_y = y_counter;





enum logic [1:0] {
	Init,
	Load_I_unit,
	GenerateUV1,
	process
} state;



//SRAM Var
logic [15:0] Y;
logic [15:0] U;
logic [15:0] U_buffer;
logic [15:0] V;
logic [31:0] U_odd;
logic [31:0] V_odd;
logic [3:0] load_counter;

logic [17:0] Y_address;
logic [17:0] U_address;
logic [17:0] V_address;
logic [17:0] write_address;
logic [17:0]   SRAM_address;
logic 	SRAM_we_n;
logic [15:0]   SRAM_write_data;

assign SRAM_address_o = SRAM_address;
assign SRAM_we_n_o = SRAM_we_n;
assign SRAM_write_data_o = SRAM_write_data;



//Interpol Var
logic enable_I_U;
logic reset_I_U;
reg [7:0] load_I_U;
wire [7:0] load_I_U_wire;
wire [31:0] Uprime;
logic outputready_U;


logic enable_I_V;
logic reset_I_V;
reg [7:0] load_I_V;
wire [7:0] load_I_V_wire;
wire [31:0] Vprime;
logic outputready_V;

Interpolation I_unit_U(
.Clock (Clock),
.Resetn(reset_I_U),
.I_en(enable_I_U),

.MACdata(Uprime),
.inputdata(load_I_U),
.inputdata_wire(load_I_U_wire),
.outputready(outputready_U),

.bottomData(nexteven_U),

.force_state(force_state),
.sync_state(load_counter)



);

Interpolation I_unit_V(
.Clock (Clock),
.Resetn(reset_I_V),
.I_en(enable_I_V),

.MACdata(Vprime),
.inputdata(load_I_V),
.inputdata_wire(load_I_V_wire),
.outputready(outputready_V),

.bottomData(nexteven_V),

.force_state(force_state),
.sync_state(load_counter)

);



CSConversion CS_unit_e(
.Clock (Clock),
.Resetn(reset_CS_e),
.CS_en(enable_CS_e),


.Yi(Y_e),
.Ui(U_e),
.Vi(V_e),

.R_flag(R_flag_e),
.G_flag(G_flag_e),
.B_flag(B_flag_e),


.Ro_reg(Ro_e),
.Go_reg(Go_e),
.Bo_reg(Bo_e),

.force_state(force_state),
.sync_state(load_counter)

);


CSConversion CS_unit_o(
.Clock (Clock),
.Resetn(reset_CS_o),
.CS_en(enable_CS_o),


.Yi(Y_o),
.Ui(U_o),
.Vi(V_o),

.R_flag(R_flag_o),
.G_flag(G_flag_o),
.B_flag(B_flag_o),


.Ro_reg(Ro_o),
.Go_reg(Go_o),
.Bo_reg(Bo_o),

.force_state(force_state),
.sync_state(load_counter)

);


assign Y_e = Y[7:0];
assign Y_o = Y[15:8];

assign load_I_V_wire = !flip_flop ? V[15:8] : (x_counter < (9'd160-`SHIFT) ? SRAM_read_data[15:8] : V[7:0] ); //! sign cause recent errors
assign load_I_U_wire = !flip_flop ? U[15:8] : U[7:0];

always_comb begin
	U_o = 32'd0;
	V_o = 32'd0;
	SRAM_write_data = 16'd0;
		case(state)
			GenerateUV1:begin
				if(outputready_V && outputready_U)begin		
					U_o = Uprime;							
					V_o = Vprime;
				end
			end
			process:begin
				case(load_counter)
				4'd0:begin
					U_o = U_odd;							
					V_o = V_odd;
					SRAM_write_data = {Go_o,Bo_o};
				end
				4'd1:begin
					U_o = U_odd;							
					V_o = V_odd;
				end
				4'd2:begin
					U_o = U_odd;							
					V_o = V_odd;
				end
				4'd3:begin
					U_o = U_odd;							
					V_o = V_odd;
				end
				4'd4:begin
					U_o = U_odd;							
					V_o = V_odd;
					SRAM_write_data = {Ro_e,Go_e};
				end
				4'd5:begin
					U_o = U_odd;							
					V_o = V_odd;
					SRAM_write_data = {Bo_e,Ro_o};
				end
			endcase
		end
	endcase
end

always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn)begin
		SRAM_address <= 18'd0;
		Y_address <= 18'd0;
		U_address <= 18'd38400;
		V_address <= 18'd57600;
		write_address <= 18'd146944;
		reset_I_U <= 1'd1;
		reset_I_V <= 1'd1;
		reset_CS_e <= 1'd1;
		reset_CS_o <= 1'd1;
		enable_I_U <= 1'd0;
		enable_I_U <= 1'd0;
		load_I_U <= 8'd0;
		load_I_V <= 8'd0;
		load_counter <= 4'd0;
		SRAM_we_n <= 1'd1;
		errorCode <= Normal;
		flip_flop <= 0;
		x_counter <= 8'd0;
		y_counter <= 9'd0;
		done <= 0;
		state <= Init;
		U_e[7:0] <= 8'd0;
		V_e [7:0]<= 8'd0;
		force_state<=0;
	end else begin
		case(state)
			Init:begin
			Y_address <= 18'd0;
			U_address <= 18'd38400;
			V_address <= 18'd57600;
			enable_I_U <= 1'd0;
			enable_I_U <= 1'd0;
			reset_I_U <= 1'd0;
			reset_I_V <= 1'd0;
			load_I_U <= 8'd0;
			load_I_V <= 8'd0;
			load_counter <= 4'd0;
			reset_CS_e <= 1'd0;
			reset_CS_o <= 1'd0;
				if(CSI_en)begin
					state <= Load_I_unit;				
					SRAM_address <= Y_address;													//provide address 1 Y0Y1
					Y_address <= Y_address + 18'd1;
					reset_I_U <= 1'd0;
					reset_I_V <= 1'd0;
					reset_CS_e <= 1'd0;
					reset_CS_o <= 1'd0;
				end
			end
			Load_I_unit:begin
				case(load_counter)
					4'd0:begin
						done <= 0;
						reset_I_U <= 1'd1;
						reset_I_V <= 1'd1;
						reset_CS_e <= 1'd1;
						reset_CS_o <= 1'd1;
					if(`BFZERO)
						flip_flop <= 0;
						load_counter <= load_counter + 4'd1;								//provide address 2 U0U2
						SRAM_address <= U_address;
						U_address <= U_address + 18'd1;
					end
					4'd1:begin
						load_counter <= load_counter + 4'd1;								//provide address 3 V0V2
						SRAM_address <= V_address;
						V_address <= V_address + 18'd1;
					end
					4'd2:begin
						load_counter <= load_counter + 4'd1;								//provide address 4 U4U6
						SRAM_address <= U_address;
						U_address <= U_address + 18'd1;										//recieve data 1 Y0Y1
						Y[15:8] <= SRAM_read_data[7:0];
						Y[7:0] <= SRAM_read_data[15:8];
					end
					4'd3:begin
						load_counter <= load_counter + 4'd1;								//provide address 5 V4V6
						SRAM_address <= V_address;
						V_address <= V_address + 18'd1;										//recieve data 2 U0U2
						U[15:8] <= SRAM_read_data[7:0];
						U[7:0] <= SRAM_read_data[15:8];
						enable_I_U <= 1'd1;														//enable Uint	
						enable_I_V <= 1'd1;													   //Enable Vint			
					end
					4'd4:begin
						load_counter <= load_counter + 4'd1;								//provide address 6 U8U10
						SRAM_address <= U_address;
						U_address <= U_address + 18'd1;										//recieve data 3 V0V2
						V[15:8] <= SRAM_read_data[7:0];
						V[7:0] <= SRAM_read_data[15:8];										//Load V0 three times
						load_I_V <= SRAM_read_data[15:8];									//load U0 3 times
						load_I_U <= U[7:0];
					end
					4'd5:begin
						load_counter <= load_counter + 4'd1;								//provide address 7 V8V10
						SRAM_address <= V_address;
						V_address <= V_address + 18'd1;										//load V2
						load_I_V <=V[15:8];														//load U2
						load_I_U <=U[15:8];														//recieve data 4 U4U6 
						U[15:8] <= SRAM_read_data[7:0];
						U[7:0] <= SRAM_read_data[15:8];
					end
					4'd6:begin
						load_counter <= load_counter + 4'd1;
						load_I_V <= SRAM_read_data[15:8];									//Load V4
						load_I_U <= U[7:0];														//load U4
						V[15:8] <= SRAM_read_data[7:0];										//recieve data 5 V4V6 
						V[7:0] <= SRAM_read_data[15:8];												
					end
					4'd7:begin
						load_counter <= load_counter + 4'd1;
						U[15:8] <= SRAM_read_data[7:0];
						U[7:0] <= SRAM_read_data[15:8];					
						load_I_V <=V[15:8];														//load V6												
						load_I_U <=U[15:8];														//load U6							
					end
					4'd8:begin											
						V[15:8] <= SRAM_read_data[7:0];										//recieve data 7 V8V10
						V[7:0] <= SRAM_read_data[15:8];
						state <= GenerateUV1;													//State to GenerateUV1
					
						load_counter <= 4'd0;
					end
				
				
				
				endcase
			
			
			end
			GenerateUV1:begin
			case(load_counter)
					4'd0:begin
						load_counter <= load_counter + 4'd1;
					end
					4'd1:begin
						load_counter <= load_counter + 4'd1;
					end
					4'd2:begin
						load_counter <= load_counter + 4'd1;
						load_I_U<= U[7:0];
						load_I_V<= V[7:0];
					end
					4'd3:begin
						load_counter <= load_counter + 4'd1;
					end
					4'd4:begin
						load_counter <= load_counter + 4'd1;
					end
					4'd5:begin
						load_counter <= load_counter + 4'd1;
						enable_CS_e <= 1'd1;														//enable CSCunit
						enable_CS_o <= 1'd1;
					end
					4'd6:begin
						errorCode <= InitInterpolFail;
						state <= Init;
					end
				endcase
				if(outputready_V && outputready_U)begin									//once primes are calcualted, go to process
					load_counter <= 4'd0;														//State to process
					state <= process;
					U_odd <= Uprime;
					V_odd <= Vprime;
					U_buffer <= U;					
					U_e [7:0] <= nexteven_U;
					V_e [7:0] <= nexteven_V;
					force_state<=1;																//set internal module state counter to match exernal
				end
			end
			
			
			process:begin
				if(y_counter < 9'd240)begin
					if(x_counter < 9'd160)begin
				
						//Sram Block
						case(load_counter)
							4'd0:begin
								if(x_counter < (9'd160-9'd1))begin
									SRAM_address <= Y_address;
									Y_address <= Y_address + 18'd1;
								end
								SRAM_we_n <= 1'd1;
							end
							4'd1:begin
								if(flip_flop && x_counter < (9'd160-`SHIFT))begin
									SRAM_address <= U_address;
									U_address <= U_address + 18'd1;
								end
								SRAM_we_n <= 1'd1;
							end
							4'd2:begin
								if(flip_flop && x_counter < (9'd160-`SHIFT))begin
									SRAM_address <= V_address;
									V_address <= V_address + 18'd1;
								end
								SRAM_we_n <= 1'd1;
							end
							4'd3:begin
								if(x_counter < (9'd160-9'd1))									//Swap Y[15:8] and Y[7:0] to match true SRAM pattern. Only swap Y[7:0] on last batch
									Y[15:8] <= SRAM_read_data[7:0];
								Y[7:0] <= SRAM_read_data[15:8];
								SRAM_address <= write_address;
								write_address <= write_address + 18'd1;
								SRAM_we_n <= 1'd0;
							end
							4'd4:begin
								if(flip_flop && x_counter < (9'd160-`SHIFT))begin
									U[15:8] <= SRAM_read_data[7:0];
									U[7:0] <= SRAM_read_data[15:8];
								end
								SRAM_address <= write_address;
								write_address <= write_address + 18'd1;
								SRAM_we_n <= 1'd0;
							end
							4'd5:begin
								if(flip_flop && x_counter < (9'd160-`SHIFT))begin
									V[15:8] <= SRAM_read_data[7:0];
									V[7:0] <= SRAM_read_data[15:8];
								end
								SRAM_address <= write_address;
								write_address <= write_address + 18'd1;
								SRAM_we_n <= 1'd0;
							end
						endcase
						
						//U Block & incrememnts load counter state
						case(load_counter)
							4'd0:begin
								load_counter <= load_counter + 4'd1;
							end
							4'd1:begin
								load_counter <= load_counter + 4'd1;
							end
							4'd2:begin
								load_counter <= load_counter + 4'd1;
							end
							4'd3:begin
								load_counter <= load_counter + 4'd1;
								if(!flip_flop)										
									load_I_U <= U[15:8];
								else
									load_I_U <= U[7:0];
								end
							4'd4:begin
								load_counter <= load_counter + 4'd1;
							end
							4'd5:begin
								load_counter <= 4'd0;
								x_counter <= x_counter + 9'd1;
								if(x_counter < (9'd160-`SHIFT))
									flip_flop <= ~flip_flop;									//flip-flop the flip_flop *flip_flop*
								U_odd <= Uprime;
								U_buffer <= U;
							end
						endcase
						
						//V Block
						case(load_counter)
							4'd3:begin
								if(!flip_flop)
								load_I_V <= V[15:8];
								else
								load_I_V <= V[7:0];
							end
							4'd5:begin
								V_odd <= Vprime;
							end
						endcase
						
						//RGBe Block
						case(load_counter)
							4'd5:begin
								U_e[7:0] <= nexteven_U;
								V_e[7:0] <= nexteven_V;
							end
						endcase
					end else begin		//x
						y_counter <= y_counter+8'd1;
						x_counter <= 9'd0;
						state <= Load_I_unit;
						SRAM_address <= Y_address;
						Y_address <= Y_address + 18'd1;
						reset_I_U <= 1'd0;
						reset_I_V <= 1'd0;
						load_counter <= 4'd0;
						force_state<=0;
						reset_CS_e <= 1'd0;
						reset_CS_o <= 1'd0;
						SRAM_we_n <= 1'd1;
						enable_CS_e <= 1'd0;
						enable_CS_o <= 1'd0;
						enable_I_U <= 1'd0;														//Disable Uint Engine
						enable_I_V <= 1'd0;														//Disable Vint		
					end 
				end else begin		//y
					done <=1;
					state <= Init;
					reset_I_U <= 1'd0;
					reset_I_V <= 1'd0;
					load_counter <= 4'd0;
					force_state<=0;
					SRAM_we_n <= 1'd1;
					reset_CS_e <= 1'd0;
					reset_CS_o <= 1'd0;
				end 
			end																						//End process	
		endcase
	end
end
	
endmodule