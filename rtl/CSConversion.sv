`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


module CSConversion (
	input  logic            Clock,
   input  logic            Resetn,
	input  logic CS_en,
	
	input wire [31:0] Yi,
	input logic [31:0] Ui,
	input logic [31:0] Vi,
	
	output logic R_flag,
	output logic  G_flag,
	output logic  B_flag,
	
	output logic [7:0] Ro,
	output logic [7:0] Go,
	output logic [7:0] Bo,
	
	output logic [7:0] Ro_reg,
	output logic [7:0] Go_reg,
	output logic [7:0] Bo_reg,
	input logic [3:0] sync_state,
	input logic force_state
	
);

enum logic [1:0] {
	Idle,
	Process
} top_state_type;

reg [31:0] Y_result; 
reg [31:0] U_intermediary;
logic [2:0] async_stage_counter;
logic [2:0] stage_counter;
logic [31:0] op1;
logic [31:0] op2;
reg [31:0] mult_result;
logic [31:0] sum;

assign stage_counter = force_state ? sync_state : async_stage_counter;



Multiplier mult_unit_C (
.Mult_op_1(op1),
.Mult_op_2(op2),
.Mult_result(mult_result)

);





always_comb begin
	op1 = 0;
	op2 = 0;
	Ro = 0;
	Go = 0;
	Bo = 0;
	R_flag = 0;
	G_flag = 0;
	B_flag = 0;
	sum = 0;
	case(stage_counter)
		3'd0:begin
			op1 = (Yi-32'd16);												
			op2 = 32'd76284;
		end
		3'd1:begin
			op1 = (Vi-32'd128);
			op2 = 32'd104595;
			sum = Y_result + mult_result;
			if(sum[31])
				Ro = 8'd0;
			else if(|sum[30:24] )
				Ro = 8'd255;
			else 
				Ro = sum[23:16];
			R_flag = 1;
		end
		3'd2:begin
			op1 = (Ui-32'd128);
			op2 = 32'd25624;
		end
		3'd3:begin
			op1 = (Vi-32'd128);
			op2 = 32'd53281;
			sum = Y_result - U_intermediary - mult_result;
			if(sum[31])
				Go = 8'd0;
			else if(|sum[30:24] )
				Go = 8'd255;
			else 
				Go = sum[23:16];
			G_flag = 1;
		end
		3'd4:begin
			op1 = (Ui-32'd128);
			op2 = 32'd132251;
			sum = Y_result + mult_result;
			if(sum[31])
				Bo = 8'd0;
			else if(|sum[30:24] )
				Bo = 8'd255;
			else 
				Bo = sum[23:16];
			B_flag = 1;
		end
		default:begin
			Ro = 0;
			Go = 0;
			Bo = 0;
			R_flag = 0;
			G_flag = 0;
			B_flag = 0;
			sum = 0;
		end
	endcase
end







always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn)begin
		top_state_type <=Idle;
		Y_result <= 32'd0;
		U_intermediary <= 32'd0;
		async_stage_counter <= 3'd0;
	end else begin
		case(top_state_type)
			Idle:begin
			async_stage_counter <= 3'd0;
				if(CS_en)begin
					top_state_type <= Process;
					Y_result <= mult_result;
				end
			end
			Process:begin
				case(stage_counter)
					3'd0:begin
						Y_result <= mult_result;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
					end
					3'd1:begin
						Ro_reg <= Ro;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
					end
					3'd2:begin
						U_intermediary <= mult_result;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
					end
					3'd3:begin
						Go_reg <= Go;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
					end
					3'd4:begin
						Bo_reg <= Bo;
						if(!force_state)
							async_stage_counter <= async_stage_counter +3'd1;
						if(!CS_en)
							top_state_type <= Idle;
					end
					3'd5:begin
						if(!force_state)
							async_stage_counter <= 3'd0;
					end
				endcase
			end
		endcase
	end
end
	
endmodule