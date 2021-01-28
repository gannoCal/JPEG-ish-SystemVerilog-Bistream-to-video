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
*/ 

`timescale 1ns/100ps
`default_nettype none

`include "../rtl/define_state.h"
`include "../rtl/VGA_param.h"

`define FEOF 32'hFFFFFFFF
`define MAX_MISMATCHES 100000

// file for output
`define OUTPUT_FILE_NAME "../data/pete_tb.ppm"

// file for comparison 
// (adapt depending on how you have out PPM file from the SW model)
`define COMPARE_FILE_NAME "../data/pete_sw.ppm"

// input file for milestone 1
//`define INPUT_FILE_NAME "../data/pete.sram_d1"

// input file for milestone 2
//`define INPUT_FILE_NAME "../data/pete.sram_d2"

// input file for milestone 3 (full project)
`define INPUT_FILE_NAME "../data/pete.mic14"

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

	logic [7:0] expected_red, expected_green, expected_blue;
	logic [2:0] color;
	logic [2:0] current_row, current_col;
	logic [9:0] VGA_row, VGA_col;
	logic VGA_en;

	// some bookkeeping variables
	integer validation_file;
	integer comparison_enabled;
	logic [7:0] VGA_file_data;
	int number_of_mismatches;


	//CSI Variables

	logic csi_en;		// UART receive/transmit
	logic [8:0] csi_x;
	logic [7:0] csi_y;

//////Integrated
	logic integrated;


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
		.CSI_x(csi_x),
		.CSI_y(csi_y),

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

	initial begin
                $timeformat(-6, 2, "us", 10);
		clock_50 = 1'b0;
		uart_rx = 1'b1;

		csi_en = 1'b0;

		switch[17:0] = 18'd0;
		push_button_n[3:0] = 4'hF;
		SRAM_resetn = 1'b1;
		RAM_filled = 1'b0;
		number_of_mismatches = 0;
		comparison_enabled = 0;
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

	initial begin
		wait (SRAM_resetn === 1'b0);
		wait (SRAM_resetn === 1'b1);
		repeat (3) @ (posedge clock_50);
	
		fill_SRAM; // fast filling of SRAM
		$write("%t: SRAM is now filled (UART transmission is finished)\n\n", $realtime);

		// waiting to reach back the IDLE state
		wait (UUT.top_state == S_IDLE);
		$write("%t: Re-entered the IDLE state (VGA mode)\n\n", $realtime);
		csi_en = 1'b1;
		$write("%t: Set CSI_I = 1 \n\n", $realtime);
		repeat (3) @ (posedge clock_50); //Small delay
		wait (UUT.top_state == S_IDLE);
		write_PPM_file;

                @(posedge VGA_Vsync);
		$write("%t: Detected posedge on Vertical Sync - start self-checking on the VGA output\n\n", $realtime);
		open_validation_file;
                @(negedge VGA_Vsync);
		$fclose(validation_file);
                $write("\n%t: Detected negedge on Vertical Sync - finish simulating one frame for 640x480 @ 60 Hz\n", $realtime);

		#5; // delay a little bit of time before stopping (just for fun)

                if (number_of_mismatches == 0) $write("No mismatches!\n\n");
                else $write("A total of %d mismatches!\n\n", number_of_mismatches);

		$stop;
	end

	always @(UUT.CSI_x or UUT.CSI_y)begin
		$write("%t: x = %d , y = %d \n\n", $realtime  ,UUT.CSI_x  ,UUT.CSI_y  );

	end

	// Task for filling the SRAM directly to shorten simulation time
	task fill_SRAM;
		integer uart_file, file_data, temp, i, new_line_count;
		logic [15:0] buffer;
	begin

		// generate a negative transition on UART_RX (needed to leave the top-level IDLE state)
		@(posedge clock_50);
		uart_rx = 1'b0; 
		repeat (5) @(posedge clock_50);
		uart_rx = 1'b1; 

		if(!integrated)begin
			$write("Opening file \"%s\" for initializing SRAM\n\n", `INPUT_FILE_NAME);
			uart_file = $fopen(`INPUT_FILE_NAME, "rb");
			file_data = $fgetc(uart_file);
			i = 0;
			while (file_data != `FEOF) begin
				buffer[15:8] = file_data & 8'hFF;
				file_data = $fgetc(uart_file);			
				buffer[7:0] = file_data & 8'hFF;
				SRAM_component.SRAM_data[i] = buffer;
				i++;

				file_data = $fgetc(uart_file);
			end


			$fclose(uart_file);
		end else begin
			$write("Opening file \"%s\" for initializing SRAM\n\n", `INPUT_FILE_NAME);
			uart_file = $fopen(`INPUT_FILE_NAME, "rb");
			file_data = $fgetc(uart_file);
			i = 76800;
			while (file_data != `FEOF) begin
				buffer[15:8] = file_data & 8'hFF;
				file_data = $fgetc(uart_file);			
				buffer[7:0] = file_data & 8'hFF;
				SRAM_component.SRAM_data[i] = buffer;
				i++;

				file_data = $fgetc(uart_file);
			end


			$fclose(uart_file);

		end
		$write("Finish initializing SRAM\n\n");

		// advance the UART timer closer to timeout
		@(negedge clock_50);
		UUT.UART_timer = 26'd49999989;
	end
	endtask

	// Task for opening the validation file for self-checking simulation
	task open_validation_file; 
		integer temp, new_line_count;
	begin
		$write("Opening validation file \"%s\"\n\n", `COMPARE_FILE_NAME);
		validation_file = $fopen(`COMPARE_FILE_NAME, "rb");
	
		temp = $fgetc(validation_file);
		new_line_count = 0;
	
		// This is for filtering out the header of PPM file
		// Which consists of 3 lines of text
		// So check for line feed (8'h0A in ASCII) here
		//note this is ONLY needed for PPM files, the debug files within the project have no such headers
		while (temp != `FEOF && new_line_count < 3) begin
			// Filter out the header
			if ((temp & 8'hFF) == 8'h0A) new_line_count++;		
			if (new_line_count < 3) temp = $fgetc(validation_file);
		end
		comparison_enabled = 1;
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

	// This always block checks to see if the RGB data obtained from the design matches with the PPM file
	always @ (posedge clock_50) begin
		if (~VGA_Vsync) begin
			VGA_en <= 1'b0;
			VGA_row <= 10'h000;
			VGA_col <= 10'h000;
		end else begin
			VGA_en <= ~VGA_en;
			// In 640x480 @ 60 Hz mode, data is provided at every other clock cycle when using 50 MHz clock
			if (VGA_en && comparison_enabled) begin
				if (UUT.VGA_enable) begin
					// Delay pixel_X_pos and pixel_Y_pos to match the VGA controller
					VGA_row <= UUT.VGA_unit.pixel_Y_pos;
					VGA_col <= UUT.VGA_unit.pixel_X_pos;
				
					if (VGA_row == VIEW_AREA_TOP && VGA_col == VIEW_AREA_LEFT) 
						$write("%t: Entering 320x240 display area ...\n\n", $realtime);
					if (VGA_row == VIEW_AREA_BOTTOM && VGA_col == VIEW_AREA_RIGHT) 
						$write("%t: Leaving 320x240 display area ...\n\n", $realtime);
				
					// In display area
					if ((VGA_row >= VIEW_AREA_TOP && VGA_row < VIEW_AREA_BOTTOM) &&
		 			    (VGA_col >= VIEW_AREA_LEFT && VGA_col < VIEW_AREA_RIGHT)) begin
	 			
		 				// Get expected data from PPM file
	 					VGA_file_data = $fgetc(validation_file);
						expected_red = VGA_file_data & 8'hFF;
	 					VGA_file_data = $fgetc(validation_file);
						expected_green = VGA_file_data & 8'hFF;
	 					VGA_file_data = $fgetc(validation_file);
						expected_blue = VGA_file_data & 8'hFF;
							
						if (VGA_red != expected_red) begin
							$write("Red   mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
								VGA_col, VGA_row, expected_red, VGA_red);
							number_of_mismatches++;
						end

						if (VGA_green != expected_green) begin
							$write("Green mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
								VGA_col, VGA_row, expected_green, VGA_green);
							number_of_mismatches++;
						end
						if (VGA_blue != expected_blue) begin
							$write("Blue  mismatch at pixel (%d, %d): expect=%x, got=%x\n", 
							VGA_col, VGA_row, expected_blue, VGA_blue);
							number_of_mismatches++;

						end		

						
						// this code section should be uncommented to stop the simulation
						// at a pre-defined number of mismatches
						if (number_of_mismatches > `MAX_MISMATCHES) begin
							$write("Stopped due to %d mismatches!!!\n", number_of_mismatches);
							$stop;
						end
						

					end
				end 
			end
		end
	end

	// the code below is used to store one frame of video in a .ppm file
	// there is no need to change it

	task automatic open_frame_file(ref int frame_fd, int frame);
		static string frame_filename = "";
		static string str_tmp = "";
	begin
		str_tmp = $sformatf("%1d", frame);
		frame_filename = {"../data/frame", str_tmp, ".ppm"};
		frame_fd = $fopen (frame_filename, "wb");
		str_tmp = $sformatf("%1d %1d", H_SYNC_ACT, V_SYNC_ACT);
		$fwrite(frame_fd, "P6%c%s%c255%c", 8'h0A, str_tmp, 8'h0A, 8'h0A); 
	end
	endtask

	task write_vga_frame();
		static int vga_row, vga_col;
		static logic buf_hsync = 0, buf_vsync = 0;
		static int frame = 0, frame_fd;
	begin
		// the VGA controller with PIPE_DELAY as a parameter
		// generates a short H_SYNC pulse after async reset;
		// this might "trick" the testbench into a wrong assumption
		// that a full H_SYNC cycle has passed (not an issue on board
		// because the monitor will ignore these type of short pulses)

		vga_row = -Y_START+1-(PIPE_DELAY?1:0);
		vga_col = -X_START;
		open_frame_file(frame_fd, frame);		
		forever begin
			@(posedge VGA_clock);

			if ((vga_row >= 0) && (vga_row < V_SYNC_ACT))
				if ((vga_col >= 0) && (vga_col < H_SYNC_ACT)) begin
					$fwrite(frame_fd, "%c%c%c", VGA_red, VGA_green, VGA_blue);
			end

			vga_col = vga_col + 1;
			if (buf_hsync && !VGA_Hsync) begin
				vga_col = -X_START + 1;
				vga_row = vga_row + 1;
			end

			if (buf_vsync && !VGA_Vsync) begin
				vga_row = -Y_START+1;
				frame = frame + 1;
				$fclose(frame_fd);
				open_frame_file(frame_fd, frame);	
			end

			buf_hsync <= VGA_Hsync;
			buf_vsync <= VGA_Vsync;
		end
	end
	endtask

	initial begin
		write_vga_frame();
	end

endmodule

