module spaceinvaders
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  LEDR,
			HEX0,
			HEX1,
			HEX2,
			HEX3,
			HEX4,
			HEX5,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);
	
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output	[9:0]	 LEDR;
	output reg [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = ~KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [7:0] y;
	wire writeEn;
	wire rd_out;
  wire fire;
  wire [7:0] alienX;
  wire [7:0] alienY;
  wire [7:0] cannonX;
  wire [7:0] cannonY;
  wire [7:0] shotX;
  wire [7:0] shotY;
  wire [14:0] alive;
	reg [14:0] sum;
//	assign sum = (~alive[0] + ~alive[1] + ~alive[2] + ~alive[3] + ~alive[4] + ~alive[5] + ~alive[6] + ~alive[7] + ~alive[8] + ~alive[9] + ~alive[10] + ~alive[11] + ~alive[12] + ~alive[13] + ~alive[14]);
  wire reset_shot;
	wire player_alive;

	always@(*) begin
		if (~player_alive) begin
//			LEDR[8:0] <= 10'b1111111111;
			HEX0[6:0] <= 7'b0000110;
			HEX1[6:0] <= 7'b0010010;
			HEX2[6:0] <= 7'b1000000;
			HEX3[6:0] <= 7'b1000111;
			HEX4[6:0] <= 7'b1111111;
			HEX5[6:0] <= 7'b1000001;
		end
		else begin
//			LEDR[8:0] <= 0;
			HEX0[6:0] <= 7'b1111111;
			HEX1[6:0] <= 7'b1111111;
			HEX2[6:0] <= 7'b1111111;
			HEX3[6:0] <= 7'b1111111;
			HEX4[6:0] <= 7'b1111111;
			HEX5[6:0] <= 7'b1111111;
		end
	end

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(~resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
    cannon cann(CLOCK_50, ~resetn, ~KEY[2], ~KEY[1], ~KEY[3], player_alive, cannonX, cannonY, fire);
    aliens als(CLOCK_50, ~resetn, player_alive, alienX, alienY);
    shot_handler sh(CLOCK_50, ~resetn, ~reset_shot, cannonX, cannonY, fire, shotX, shotY, LEDR[9]);
    collision coll(CLOCK_50, ~resetn, alienX, alienY, shotX, shotY, cannonX, cannonY, alive, player_alive, reset_shot);

		render renderAll(CLOCK_50, rd_out, ~resetn, shotX, shotY, cannonX, cannonY, alienX, alienY, alive, sum, ~player_alive, x, y, writeEn, colour); 
		counterDraw cd1(CLOCK_50, ~resetn, rd_out);
		
	always@(posedge CLOCK_50) begin
		if (resetn) begin
			sum <= 0;
		end
		else if (reset_shot) begin
			sum <= sum + 125;
		end
	end
endmodule

module counterDraw(
	input clock,
	input reset,
	output reg q);
	
	reg[21:0] count;
	
	always@(posedge clock) begin
		if(!reset) begin
			count <= 22'd0;
			q <= 1'd0;
		end
		else begin
			if(count < 24'b111101000010010000000) begin
//			if(count < 20'd10000) begin
				count <= count + 1'd1;
				q <= 1'd0;
			end
			else begin
				count <= 22'd0;
				q <= 1'd1;
			end
		end
	end
endmodule
