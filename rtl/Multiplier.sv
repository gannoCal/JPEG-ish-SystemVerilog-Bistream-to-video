`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif


module Multiplier (
	//input logic [1:0] select,
	input logic signed [31:0] Mult_op_1, 
	input logic signed [31:0] Mult_op_2,
	
	output logic signed [31:0] Mult_result,
	output logic signed[63:0] Mult_result_long
	
);

assign Mult_result_long = Mult_op_1 * Mult_op_2;
assign Mult_result = Mult_result_long[31:0];


endmodule