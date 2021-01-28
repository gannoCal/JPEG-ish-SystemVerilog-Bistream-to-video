/*
Copyright by Adam Kinsman, Jason Thong and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

/*
This testbench was adapated from experiment4 from lab 5. Make sure
instantiation names match that of your project (e.g. replace "experiment4"
everywhere with "project" or whatever your top-level is called).

There are many debug hooks already placed in the code (messages will print
when "something bad" happens), it is recommended you modify these as well as
add your own.

The verification strategy here is to watch data being written back to the
SRAM. It is assumed that all values being written are the final values.
If you are using the SRAM as temporary storage (strongly NOT advisable),
you will get false errors, so use the original testbench instead.
*/ 

`timescale 1ns/100ps
`default_nettype none

`include "../rtl/define_state.h"
`include "../rtl/VGA_param.h"

`define FEOF 32'hFFFFFFFF
`define MAX_MISMATCHES 1000000

// file for output
// this is only useful if decoding is done all the way through 
`define OUTPUT_FILE_NAME "../data/duckQ1_tb.ppm"

// file for comparison
// to test milestone 2 independently, use the .sram_d1 file to check the output
`define VERIFICATION_FILE_NAME "../data/duckQ1.sram_d1"

// input file for milestone 1
//`define INPUT_FILE_NAME "../data/panda.sram_d1"

// input file for milestone 2
//`define INPUT_FILE_NAME "../data/pete.sram_d2"

// input file for milestone 3 (full project)
`define INPUT_FILE_NAME "../data/duckQ1.mic14"


// the top module of the testbench
module TB;

	logic clock_50;			// 50 MHz clock
	
	logic [3:0] push_button_n;	// pushbuttons
	logic [17:0] switch;		// switches

	logic [6:0] seven_seg_n [7:0];	// 8 seven segment displays		
	logic [8:0] led_green;		// 9 green LEDs

	logic uart_rx, uart_tx;		// UART receive/transmit

	wire [15:0] SRAM_data_io;	// SRAM interface
	logic [15:0] SRAM_write_data, SRAM_read_data;
	logic [19:0] SRAM_address;
	logic SRAM_UB_N, SRAM_LB_N, SRAM_WE_N, SRAM_CE_N, SRAM_OE_N;
	logic SRAM_resetn;		// used to initialize the
	logic RAM_filled;		// SRAM emulator in the TB

	logic VGA_clock;		// VGA interface
	logic VGA_Hsync;
	logic VGA_Vsync;
	logic VGA_blank;
	logic VGA_sync;
	logic [7:0] VGA_red;
	logic [7:0] VGA_green;
	logic [7:0] VGA_blue;

	///////CSI VAR
	logic csi_en;

	//////IDCT Var
	logic idct_en;

	//////IDCT Var
	logic ldd_en;

	//////Integrated
	logic integrated;

	// some bookkeeping variables
	integer validation_fd;
	logic [7:0] VGA_file_data;
	int number_of_mismatches;

	// a very software-ish way of emulating the sram
	logic [17:0] SRAM_ARRAY[262143:0];
	integer SRAM_ARRAY_write_count[262143:0];
	integer num_mismatches;
	integer warn_writing_out_of_region;
	integer warn_multiple_writes_to_same_location;

	// instantiate the unit under test
	experiment4 UUT (
		.CLOCK_50_I(clock_50),

		.SWITCH_I(switch),
		.PUSH_BUTTON_N_I(push_button_n),		

		.SEVEN_SEGMENT_N_O(seven_seg_n), 
		.LED_GREEN_O(led_green),

		.VGA_CLOCK_O(VGA_clock),
		.VGA_HSYNC_O(VGA_Hsync),
		.VGA_VSYNC_O(VGA_Vsync),
		.VGA_BLANK_O(VGA_blank),
		.VGA_SYNC_O(VGA_sync),
		.VGA_RED_O(VGA_red),
		.VGA_GREEN_O(VGA_green),
		.VGA_BLUE_O(VGA_blue),
		
		.SRAM_DATA_IO(SRAM_data_io),
		.SRAM_ADDRESS_O(SRAM_address),
		.SRAM_UB_N_O(SRAM_UB_N),
		.SRAM_LB_N_O(SRAM_LB_N),
		.SRAM_WE_N_O(SRAM_WE_N),
		.SRAM_CE_N_O(SRAM_CE_N),
		.SRAM_OE_N_O(SRAM_OE_N),

		.UART_RX_I(uart_rx),
		.UART_TX_O(uart_tx),

		.CSI_I(csi_en),
		.IDCT_I(idct_en),
		.LDD_I(ldd_en),
		.whatsTheAddy(integrated)
	);

	// the emulator for the external SRAM during simulation
	tb_SRAM_Emulator SRAM_component (
		.Clock_50(clock_50),
		.Resetn(SRAM_resetn),
	
		.SRAM_data_io(SRAM_data_io),
		.SRAM_address(SRAM_address[17:0]),
		.SRAM_UB_N(SRAM_UB_N),
		.SRAM_LB_N(SRAM_LB_N),
		.SRAM_WE_N(SRAM_WE_N),
		.SRAM_CE_N(SRAM_CE_N),
		.SRAM_OE_N(SRAM_OE_N)
	);

	// 50 MHz clock generation
	always begin
		#10;
		clock_50 = ~clock_50;
	end

	task fill_SRAM;
		integer file_ptr, file_data, i;
		logic [15:0] buffer;
	begin
		// generate a negative transition on UART_RX (needed to leave the top-level IDLE state)
		@(posedge clock_50);
		uart_rx = 1'b0; 
		repeat (5) @(posedge clock_50);
		uart_rx = 1'b1; 
		if(!integrated)begin
			$write("Opening file \"%s\" for initializing SRAM\n\n", `INPUT_FILE_NAME);
			file_ptr = $fopen(`INPUT_FILE_NAME, "rb");
			for (i=0; i<262144; i=i+1) begin
				file_data = $fgetc(file_ptr);
				buffer[15:8] = file_data & 8'hFF;
				file_data = $fgetc(file_ptr);
				buffer[7:0] = file_data & 8'hFF;
				SRAM_component.SRAM_data[i] = buffer;
			end
			$fclose(file_ptr);
		end else begin
			$write("Opening file \"%s\" for initializing SRAM\n\n", `INPUT_FILE_NAME);
			file_ptr = $fopen(`INPUT_FILE_NAME, "rb");
			for (i=76800; i<262144; i=i+1) begin
				file_data = $fgetc(file_ptr);
				buffer[15:8] = file_data & 8'hFF;
				file_data = $fgetc(file_ptr);
				buffer[7:0] = file_data & 8'hFF;
				SRAM_component.SRAM_data[i] = buffer;
			end
			$fclose(file_ptr);



		end
	
		$write("Opening file \"%s\" to get SRAM verification data\n\n", `VERIFICATION_FILE_NAME);
		file_ptr = $fopen(`VERIFICATION_FILE_NAME, "rb");
		for (i=0; i<262144; i=i+1) begin
			file_data = $fgetc(file_ptr);
			buffer[15:8] = file_data & 8'hFF;
			file_data = $fgetc(file_ptr);
			buffer[7:0] = file_data & 8'hFF;
			SRAM_ARRAY[i] = buffer;
			SRAM_ARRAY_write_count[i] = 0;
		end
		$fclose(file_ptr);
	
		num_mismatches = 0;
		warn_writing_out_of_region = 0;
		warn_multiple_writes_to_same_location = 0;

		// advance the UART timer closer to timeout
		@(negedge clock_50);
		UUT.UART_timer = 26'd49999989;
	end
	endtask

	task check_sram_write_counts;
		integer i, error_count;
	begin
		error_count = 0;
		//NOTE: this is for milestone 1, in different milestones we will be
		//writing to different regions so modify as needed
		for (i=0; i<76799; i=i+1) begin
			if (SRAM_ARRAY_write_count[i]==0) begin
				if (error_count < `MAX_MISMATCHES) begin
					$write("error: did not write to location %d (%x hex)\n", i, i);
					error_count = error_count + 1;
				end
			end
		end
	end
	endtask

	task write_PPM_file; 
		integer i, output_file;
		logic [7:0] high_byte, low_byte;
	begin
		$write("Writing SRAM contents to file \"%s\"\n\n", `OUTPUT_FILE_NAME);
		output_file = $fopen(`OUTPUT_FILE_NAME, "wb");
	
		// Write file header
		$fwrite(output_file, "P6%c320 240%c255%c", 8'h0A, 8'h0A, 8'h0A); 

		// Write RGB main data
		for (i = 0; i < 3*320*240/2; i = i + 1) begin
			high_byte = (SRAM_component.SRAM_data[i+UUT.VGA_base_address] >> 8) & 8'hFF;
			low_byte = SRAM_component.SRAM_data[i+UUT.VGA_base_address] & 8'hFF;	
			$fwrite(output_file, "%c%c", high_byte, low_byte);
		end

		$fclose(output_file);
	end 
	endtask

	initial begin
                $timeformat(-6, 2, "us", 10);
		clock_50 = 1'b0;
		uart_rx = 1'b1;
		idct_en = 1'd0; 
		csi_en = 1'd0;
		ldd_en = 1'd0;
		switch[17:0] = 18'd0;
		push_button_n[3:0] = 4'hF;
		SRAM_resetn = 1'b1;
		RAM_filled = 1'b0;
		number_of_mismatches = 0;
		repeat (2) @(negedge clock_50);
		$display("\n*** Asserting the asynchronous reset ***");
		switch[17] = 1'b1;
		repeat (3) @(negedge clock_50);
		switch[17] = 1'b0;		
		$display("*** Deasserting the asynchronous reset ***\n");
		@(negedge clock_50);
		// clear SRAM model
		SRAM_resetn = 1'b0;	
		@(negedge clock_50);
		SRAM_resetn = 1'b1;	
	end

	always @(UUT.IDCT_unit.top_level_state)begin
		$write("%t: state = %s \n\n", $realtime  ,UUT.IDCT_unit.top_level_state  );

	end

	always @(UUT.IDCT_unit.post_address_tracker)begin
		$write("%t: post-address = %d \n\n", $realtime  ,UUT.IDCT_unit.post_address_tracker  );

	end

	initial begin
		wait (SRAM_resetn === 1'b0);
		wait (SRAM_resetn === 1'b1);
		repeat (3) @ (posedge clock_50);
	
		fill_SRAM; // fast filling of external SRAM 
		$write("%t: SRAM is now filled (UART transmission is finished)\n\n", $realtime);
		//idct_en = 1'd1;
		//ldd_en = 1'd1;

		 $write("%t: Set IDCT_I = 1 \n\n", $realtime);
		repeat (3) @ (posedge clock_50); //Small delay

		// waiting to reach back the IDLE state
		// this can be adjusted if we want to debug milestones 2/3 independently of milestone 1
		wait (UUT.top_state == S_IDLE);
		$write("Decoding finished at %t\n\n", $realtime);

		//this task checks that we've written to all the locations that we were supposed to
		check_sram_write_counts;	
	
		//this is only useful if decoding is done all the way through 
		// (e.g. milestone 1 is simulated together with the other milestones)
		write_PPM_file;

		#5; // delay a little bit of time before stopping (just for fun)

                if (number_of_mismatches == 0) $write("No mismatches!\n\n");
                else $write("A total of %d mismatches!\n\n", number_of_mismatches);

		$stop;
	end

	// monitor the write enable signal on the SRAM
	// if the incoming data does not match the expected data
	// then stop simulating and print debug info
	always @ (posedge clock_50) begin
		if (UUT.SRAM_we_n == 1'b0) begin //signal names within project (instantiated as uut) should match here, assuming names from experiment4a
	
			//IMPORTANT: this is the "no write" memory region for milestone 1, change region for different milestones
			if (UUT.SRAM_address < 0) begin
				if (warn_writing_out_of_region < `MAX_MISMATCHES) begin
					$write("critical warning: writing outside of the RGB data region, may corrupt source data in SRAM\n");
					$write("  writing value %d (%x hex) to location %d (%x hex), sim time %t\n", 
						UUT.SRAM_write_data, UUT.SRAM_write_data, UUT.SRAM_address, UUT.SRAM_address, $realtime);
					warn_writing_out_of_region = warn_writing_out_of_region + 1;
				end
			end
	
			if (SRAM_ARRAY[UUT.SRAM_address] != UUT.SRAM_write_data && UUT.SRAM_address <18'd76800) begin
				$write("error: wrote value %d (%x hex) to location %d (%x hex), should be value %d (%x hex)\n",
					UUT.SRAM_write_data, UUT.SRAM_write_data, UUT.SRAM_address, UUT.SRAM_address,
					SRAM_ARRAY[UUT.SRAM_address], SRAM_ARRAY[UUT.SRAM_address]);
				$write("sim time %t\n", $realtime);
				$write("print some useful debug info here...\n");
				// assuming your milestone 1 instance is called "m1" and its state is called "state"
				// $write("m1 state %d\n", UUT.m1.state); 
				$write("...or take a look at the last few clock cycles in the waveforms that lead up to this error\n");
				num_mismatches = num_mismatches + 1;
				if (num_mismatches == `MAX_MISMATCHES) 
					$stop;
			end
			
			SRAM_ARRAY_write_count[UUT.SRAM_address] = SRAM_ARRAY_write_count[UUT.SRAM_address] + 1;
			if (SRAM_ARRAY_write_count[UUT.SRAM_address] != 1 && warn_multiple_writes_to_same_location < `MAX_MISMATCHES) begin
				/*$write("warning: written %d times to location %d (%x hex), sim time %t\n",
					SRAM_ARRAY_write_count[UUT.SRAM_address], UUT.SRAM_address, UUT.SRAM_address, $realtime)*/;
				warn_multiple_writes_to_same_location = warn_multiple_writes_to_same_location + 1;
			end
		end
	end

endmodule

