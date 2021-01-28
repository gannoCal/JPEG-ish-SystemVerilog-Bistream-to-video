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

// This module generates the Hsync, Vsync signals for the VGA using modulo counters
module VGA_controller (
		input logic Clock,
		input logic Resetn,
		input logic Enable,

		input logic [7:0] iRed,
		input logic [7:0] iGreen,
		input logic [7:0] iBlue,
		output logic [9:0] oCoord_X,
		output logic [9:0] oCoord_Y,
		
		// VGA Side
		output logic [7:0] oVGA_R,
		output logic [7:0] oVGA_G,
		output logic [7:0] oVGA_B,
		output logic oVGA_H_SYNC,
		output logic oVGA_V_SYNC,
		output logic oVGA_SYNC,
		output logic oVGA_BLANK
);

`include "VGA_param.h"

logic [7:0] nVGA_R;
logic [7:0] nVGA_G;
logic [7:0] nVGA_B;

logic [9:0] H_Cont;
logic [9:0] V_Cont;

assign oVGA_BLANK = oVGA_H_SYNC & oVGA_V_SYNC;
assign oVGA_SYNC  = 1'b0;

// X and Y coordinates of pixel position
assign oCoord_X = H_Cont - X_START;
assign oCoord_Y = V_Cont - Y_START;

//
// H_Sync Generator
always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn) begin
		H_Cont <= 10'd0;
		oVGA_H_SYNC <= 1'b0;
	end else begin
		if (Enable) begin
			// H_Sync Counter
			if (H_Cont < H_SYNC_TOTAL-1) H_Cont <= H_Cont + 10'd1;
			else H_Cont <= 10'd0;
			
			// H_Sync Generator
			if ((H_Cont >= PIPE_DELAY) && (H_Cont < H_SYNC_CYC + PIPE_DELAY)) oVGA_H_SYNC <= 1'b0;
			else oVGA_H_SYNC <= 1'b1;
		end
	end
end

// V_Sync Generator
always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn) begin
		V_Cont <= 10'd0;
		oVGA_V_SYNC <= 1'b0;
	end else begin
		if (Enable) begin
			// When H_Sync Re-start
			if (H_Cont == PIPE_DELAY) begin
				// V_Sync Counter
				if (V_Cont < V_SYNC_TOTAL-1) V_Cont <= V_Cont + 10'd1;
				else V_Cont <= 10'd0;
				
				// V_Sync Generator
				if (V_Cont < V_SYNC_CYC) oVGA_V_SYNC <= 1'b0;
				else oVGA_V_SYNC <= 1'b1;
			end
		end
	end
end

// next state signals for Red/Green/Blue
assign nVGA_R = (H_Cont >= X_DELAYED_START && H_Cont < X_DELAYED_START + H_SYNC_ACT &&
		V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT) ? iRed : 8'd0;

assign nVGA_G = (H_Cont >= X_DELAYED_START && H_Cont < X_DELAYED_START + H_SYNC_ACT &&
		V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT) ? iGreen : 8'd0;

assign nVGA_B = (H_Cont >= X_DELAYED_START && H_Cont < X_DELAYED_START + H_SYNC_ACT &&
		V_Cont >= Y_START && V_Cont < Y_START + V_SYNC_ACT) ? iBlue : 8'd0;

// buffer the RGB signals to synchronize them with V_SYNC and H_SYNC
// the RGB signals need also to be disabled during blanking
//
// V_Sync Generator
always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn) begin
		oVGA_R <= 8'd0;
		oVGA_G <= 8'd0;
		oVGA_B <= 8'd0;
	end else begin
		if (Enable) begin
			oVGA_R <= nVGA_R;
			oVGA_G <= nVGA_G;
			oVGA_B <= nVGA_B;
		end
	end
end

endmodule

