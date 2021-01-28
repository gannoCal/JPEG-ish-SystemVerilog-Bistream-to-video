`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


module Interpolation (
	input  logic            Clock,
   input  logic            Resetn,
	input  logic I_en,
	
	
	input logic   [7:0]   inputdata,
	input logic   [7:0]   inputdata_wire,
	output wire   [31:0]   MACdata,

	output logic   [7:0]   bottomData,
	
	output logic      outputready,
	
	input logic [3:0] sync_state,
	input logic force_state
	
);


enum logic [1:0] {
	Idle,
	initLoad,
	Process
} top_state_type;

logic [7:0] old_values[5:0];
logic [2:0] load_counter;
logic [2:0] async_stage_counter;
logic [7:0] op1;
logic [31:0] acc_mult_result;
logic [31:0] mult_result;
logic [31:0] sum;
logic sign;

assign bottomData = old_values[3];
assign load_counter = force_state ? sync_state : async_stage_counter;


Multiplier mult_unit_I (
.Mult_op_1({24'd0,op1}),
.Mult_op_2({24'd0,old_values[0]}),
.Mult_result(mult_result)

);

assign MACdata = sum[31:8];



always_comb begin
		sum = 32'd0;
		outputready = 1'd0;
	if(load_counter == 3'd5)begin
		sum = acc_mult_result + mult_result + 8'd128;
		outputready =  1'd1;
	end
end




always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn)begin
		old_values <= '{8'd0,8'd0,8'd0,8'd0,8'd0,8'd0};
		async_stage_counter <= 3'd0;
		top_state_type <=Idle;
		acc_mult_result <= 32'd0;
		op1 <= 8'd0;
	end else begin
		case(top_state_type)
			Idle:begin
				async_stage_counter <= 3'd0;
				if(I_en == 1'd1)begin
					top_state_type <= initLoad;							
				end
			end
			initLoad: begin
			if(load_counter == 3'd0)begin
				old_values <= '{inputdata, inputdata,inputdata,old_values[5],old_values[4],old_values[3]}; 									//Load first value 3 times
				async_stage_counter <= async_stage_counter + 3'd3;
			end else begin
				old_values <= '{inputdata, old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};
				async_stage_counter <= async_stage_counter + 3'd1;
					if(load_counter == 3'd5)begin
						top_state_type <= Process;
						op1 <= 8'd21;
						sign <= 0;
						async_stage_counter <= 3'd0;
					end
				end
			end
			Process: begin
				case(load_counter)
					3'd0:begin
						op1 <= 8'd52;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						acc_mult_result <= acc_mult_result + mult_result; 
						old_values <= '{old_values[0], old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};				//accumulate result onto MACdata, shift oldvalue[0] to oldvalue[7]
					end
					3'd1:begin
						op1 <= 8'd159;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						acc_mult_result <= acc_mult_result - mult_result;
						old_values <= '{old_values[0], old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};				//accumulate result onto MACdata, shift oldvalue[0] to oldvalue[7]
					end
					3'd2:begin
						op1 <= 8'd159;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						acc_mult_result <= acc_mult_result + mult_result; 
						old_values <= '{old_values[0], old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};				//accumulate result onto MACdata, shift oldvalue[0] to oldvalue[7]
					end
					3'd3:begin
						op1 <= 8'd52;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						acc_mult_result <= acc_mult_result + mult_result; 
						old_values <= '{old_values[0], old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};				//accumulate result onto MACdata, shift oldvalue[0] to oldvalue[7]
					end
					3'd4:begin
						op1 <= 8'd21;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						acc_mult_result <= acc_mult_result - mult_result;	
						old_values <= '{old_values[0], old_values[5],old_values[4],old_values[3],old_values[2],old_values[1]};				//accumulate result onto MACdata, shift oldvalue[0] to oldvalue[7]
					end
					
					3'd5:begin
						acc_mult_result <= 32'd0;
						if(!force_state) begin
							async_stage_counter <= 3'd0;
							old_values <= '{inputdata, old_values[0], old_values[5],old_values[4],old_values[3],old_values[2]};  				//Shift data over by two, grab inputdata / inputdata_wire
						end else begin
							old_values <= '{inputdata_wire, old_values[0], old_values[5],old_values[4],old_values[3],old_values[2]};  
						end
						op1 <= 8'd21;
						sign <= 0;
						if(!I_en)
							top_state_type <=Idle;
					end
					default:begin
						op1 <= 8'd0;
						sign <= 0;
						async_stage_counter <= 3'd0;	
					end
				endcase
			end
		endcase
	end
end
	
endmodule