/*
Copyright by Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps

`include "../rtl/define_state.h"
`include "../rtl/VGA_param.h"

`define FEOF 32'hFFFFFFFF
`define INPUT_FILE_NAME "../data/panda.ppm"
`define VALIDATION_FILE_NAME "../data/panda.ppm"

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
	integer validation_fd;
	logic [7:0] VGA_file_data;
	int number_of_mismatches;

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
		.UART_TX_O(uart_tx)
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

	initial begin
		wait (SRAM_resetn === 1'b0);
		wait (SRAM_resetn === 1'b1);
		repeat (3) @ (posedge clock_50);
	
		//uart_rx_generate; // slow filling of SRAM (even if baud rate is scaled up by 500/7) 					//switch to change sim speed 
		 fill_SRAM; // fast filling of SRAM (bypassing UART SRAM interface in simulation)
		$write("%t: SRAM is now filled (UART transmission is finished)\n\n", $realtime);

		// waiting to reach back the IDLE state
		wait (UUT.top_state == S_IDLE);
		$write("%t: Re-entered the IDLE state (VGA mode)\n\n", $realtime);
                @(posedge VGA_Vsync);
		$write("%t: Detected posedge on Vertical Sync - start self-checking on the VGA output\n\n", $realtime);
		open_validation_file;
                @(negedge VGA_Vsync);
		$fclose(validation_fd);
                $write("\n%t: Detected negedge on Vertical Sync - finish simulating one frame for 640x480 @ 60 Hz\n", $realtime);

                if (number_of_mismatches == 0) $write("No mismatches!\n\n");
                else $write("A total of %d mismatches!\n\n", number_of_mismatches);

		$stop;
	end

	// Task for filling the SRAM directly to shorten simulation time
	task fill_SRAM;
	integer input_fd, file_data, temp, i, new_line_count;
	logic [15:0] buffer;
	begin
		// generate a negative transition on UART_RX (needed to leave the top-level IDLE state)
		@(posedge clock_50);
		uart_rx = 1'b0; 
		repeat (5) @(posedge clock_50);
		uart_rx = 1'b1; 

		$write("Opening file \"%s\" for initializing SRAM\n\n", `INPUT_FILE_NAME);
		input_fd = $fopen(`INPUT_FILE_NAME, "rb");
		file_data = $fgetc(input_fd);
		new_line_count = 0;
		i = 0;
		while (file_data != `FEOF) begin
			if (new_line_count >= 3) begin
				// Filter out the header
				buffer[15:8] = file_data & 8'hFF;
				file_data = $fgetc(input_fd);			
				buffer[7:0] = file_data & 8'hFF;
				SRAM_component.SRAM_data[i] = buffer;
				i++;
			end

			// This is for filtering out the header of the 
			// PPM file, which consists of 3 lines of text
			// So check for line feed (8'h0A in ASCII) here
			if ((file_data & 8'hFF) == 8'h0A) new_line_count++;		
			file_data = $fgetc(input_fd);
		end
		$fclose(input_fd);
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
		$write("Opening validation file \"%s\"\n\n", `VALIDATION_FILE_NAME);
		validation_fd = $fopen(`VALIDATION_FILE_NAME, "rb");
		
		temp = $fgetc(validation_fd);
		new_line_count = 0;

		// This is for filtering out the header of the 
		// PPM file, which consists of 3 lines of text
		// So check for line feed (8'h0A in ASCII) here
		while (temp != `FEOF && new_line_count < 3) begin
			// Filter out the header
			if ((temp & 8'hFF) == 8'h0A) new_line_count++;		
			if (new_line_count < 3) temp = $fgetc(validation_fd);
		end
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
			if (VGA_en) begin
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
	 					VGA_file_data = $fgetc(validation_fd);
						expected_red = VGA_file_data & 8'hFF;
	 					VGA_file_data = $fgetc(validation_fd);
						expected_green = VGA_file_data & 8'hFF;
	 					VGA_file_data = $fgetc(validation_fd);
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

	// the code below is used to emulate sending the PPM file
	// from the host through the UART set up as follows:
	// 1 start bit / 8 data bits / 1 stop bit 
	// the speed-up is 500/7 for the 57.6 MHz clock or
	// or a speed-up of 434/6 for the 50 MHz clock

	logic clock_57_6;

	// generate the 57.6 MHz clock
	initial begin
		clock_57_6 = 1'b0;
		forever begin
			#8.68;
			clock_57_6 = ~clock_57_6;
		end
	end

	task uart_rx_generate;
		int src_fd, file_data;
		string src_filename;
		logic [7:0] uart_rx_byte;
		int inter_byte_delay, rx_index;
	begin
		src_filename = `INPUT_FILE_NAME;
		src_fd = $fopen(src_filename, "rb");
		$display("%t: Start generating Rx data to UUT\n", $realtime);

		// read the first byte from the file
		file_data = $fgetc(src_fd);
		while (file_data != `FEOF) begin

			uart_rx_byte[7:0] = file_data & 8'hFF;
			// $write("%t: start sending byte 8\'h%h to UUT\n", $realtime, uart_rx_byte);

			// generate the Start bit
			uart_rx = 1'b0; 

			// adapt the duration of a bit to 7 clock pulses at 57.6 MHz
			// repeat (500) @(posedge clock_57_6);
			repeat (7) @(posedge clock_57_6);

			// 500 pulses at 57.6 MHz equal one pulse at 115.2 KHz
			// changed to 7 pulses (see note above)
			for (rx_index=0; rx_index<8; rx_index++) begin
				// generate the each bit from the byte
				uart_rx = uart_rx_byte[rx_index];
				// repeat (500) @(posedge clock_57_6);
				repeat (7) @(posedge clock_57_6);
			end

			// generate the Stop bit
			uart_rx = 1'b1;	
			// repeat (500) @(posedge clock_57_6);
			repeat (7) @(posedge clock_57_6);

			// 100 ns delay between bytes
			inter_byte_delay = 5;	
			repeat (inter_byte_delay) @(posedge clock_50);

			// read next byte from the file
			file_data = $fgetc(src_fd);
		end

		// advance the UART timer closer to timeout
		@(negedge clock_50);
		UUT.UART_timer = 26'd49999989;
	end
	endtask

endmodule


