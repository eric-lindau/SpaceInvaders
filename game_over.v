module game_over(
	input clock,	//put clock 50 into this
	input draw,		//put rate divider into this
	input reset,	//put reset into this
	input over, 	//one long pulse when game is over
	output reg[7:0] xOut,	//send to VGA x
	output reg[7:0] yOut,	//send to VGA y
	output reg[2:0] colour,
	output reg plot);						
	
	wire [3:0] yAdd;
	wire ld, enable, plotOut, stop, clock112Out;
	wire [7:0] xOutW;
	wire [6:0] yOutW;
	reg [115:0] row;
	wire st;
	
	localparam row0 = 116'b00001111111111000001111110000011110000001111011111111111100000011111111000111100000011110111111111111011111111111100,
				  row1 = 116'b00001111111111000001111110000011110000001111011111111111100000011111111000111100000011110111111111111011111111111100,
				  row2 = 116'b00111100000000000111100111100011111100111111011110000000000001111000011110111100000011110111100000000011110000001111,
				  row3 = 116'b00111100000000000111100111100011111100111111011110000000000001111000011110111100000011110111100000000011110000001111,
				  row4 = 116'b11110000000000011110000001111011111111111111011110000000000001111000011110111100000011110111100000000011110000001111,
				  row5 = 116'b11110000000000011110000001111011111111111111011110000000000001111000011110111100000011110111100000000011110000001111,
				  row6 = 116'b11110000111110011110000001111011111111111111011111111000000001111000011110111111001111110111111110000011110000111111,
				  row7 = 116'b11110000111111011110000001111011111111111111011111111000000001111000011110111111001111110111111110000011110000111111,
				  row8 = 116'b11110000001111011111111111111011110011001111011110000000000001111000011110001111111111000111100000000011111111110000,
				  row9 = 116'b11110000001111011111111111111011110011001111011110000000000001111000011110001111111111000111100000000011111111110000,
				  row10= 116'b00111100001111011110000001111011110000001111011110000000000001111000011110000011111100000111100000000011110011111100,
				  row11= 116'b00111100001111011110000001111011110000001111011110000000000001111000011110000011111100000111100000000011110011111100,
				  row12= 116'b00001111111111011110000001111011110000001111011111111111100000011111111000000000110000000111111111111011110000111111,
				  row13= 116'b00001111111110011110000001111011110000001111011111111111100000011111111000000000110000000111111111111011110000111111;
	
	always@(*) begin
		case(yAdd)
		5'd0: row = row0;
		5'd1: row = row1;
		5'd2: row = row2;
		5'd3: row = row3;
		5'd4: row = row4;
		5'd5: row = row5;
		5'd6: row = row6;
		5'd7: row = row7;
		5'd8: row = row8;
		5'd9: row = row9;
		5'd10: row = row10;
		5'd11: row = row11;
		5'd12: row = row12;
		5'd13: row = row13;
		default: row = row0;
		endcase
	end
	
	
	over_control overControl1(clock, reset, over, st, ld, enable);
	over_data overData1(clock, reset, ld, enable, 8'd5, (8'd40 + yAdd), row, xOutW, yOutW, plotOut, stop);
	counterOver cOver1(clock, reset, st, 4'd13, yAdd);
	flip flipStopOver(st, reset, clock, stop);
	
	reg[7:0] colourCount;
	
	always@(posedge clock) begin
		if(~reset) begin
			colour <= 3'b000;
			colourCount <= 7'd0;
		end
		else if(draw) begin
			if (colourCount < 50) begin
				colourCount <= colourCount + 1;
			end
			else begin
				colourCount <= 8'b0;
				colour <= colour+1;
			end
		end
	end
	
	always@(*) begin
		xOut <= xOutW;
		yOut <= yOutW;
		plot <= plotOut;
	end

endmodule

module over_control(
	input clock, 
	input reset, 
	input draw,			//shift bits out to be drawn
	input stop,			//load bits into shifter
	output reg ld, 
	output reg enable);
	
	reg[4:0] current_state, next_state;
	
	localparam LOAD = 1'd0,
				  SHIFT = 1'd1;
				  
	always@(*)
	begin: state_table
			case(current_state)
				LOAD: next_state = draw ? SHIFT : LOAD;
				SHIFT: next_state = stop ? LOAD : SHIFT;
				default: next_state = LOAD;
			endcase
	end
	
	always@(*)
	begin
		ld = 1'b0;
		enable = 1'b0;
		case(current_state)
			LOAD:begin
				ld = 1'b1;
				end
			SHIFT:begin
				enable = 1'b1;
				end
			endcase
	end
	
	always@(posedge clock)
	begin: state_FFs
			if(!reset)
				current_state <= LOAD;
			else
				current_state <= next_state;
	end
endmodule

module over_data(
	input clock,
	input reset,
	input ld,						//load state on
	input shift,					//shift state on
	input [7:0]xIn,
	input [6:0]yIn,
	input [115:0]row,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg enableOut, 		//turn on the plot of VGA
	output reg stop);				//send to control to move to next state
	
	reg s;
	reg [7:0]count;
	wire shiftOut;
	
	always@(posedge clock)
	begin
		if(!reset) begin
		xOut <= 8'd0;
		yOut <= 7'd0;
		count <= 4'd0;
		stop <= 1'b0;
		enableOut <= 1'b0;
		end
		else begin
			if(ld) begin							//load in pos and reset count
				xOut <= xIn;
				yOut <= yIn;
				enableOut <= shiftOut;
				count <= 1'b0;
			end
			if(shift) begin
				if(count < 8'd114) begin			//plot equals shifter bit
					enableOut <= shiftOut;
					stop <= 1'b0;
					end
				else begin
					stop <= 1'b1;						//go to next state
					enableOut <= shiftOut;
					end
				count <= count + 1'b1;				//increase x coord
				xOut <= xOut + 1'b1;
			end
		end
	end
	
	shifterOver overShifter(clock, shift, ld, row, shiftOut);
	
endmodule

//Reverse shifter bits
module shifterOver(
	input clock,
	input draw,					//tells when to start drawing
	input load,					//loads in a value
	input[115:0] value,
	output reg q);				//bit to be drawn

	reg[115:0] n;
	
	always@(negedge clock) begin
		if(load)begin
			n <= value;
			end
		if(draw) begin
		//reverse this direction
			n <= n << 1'b1;
		end
	end
	
	//set to n[115]
	always@(*) begin
		q <= n[115];
	end
endmodule

module counterOver(
	input clock,
	input reset,
	input enable,
	input [3:0]in,
	output reg[3:0] q);
	
	reg[3:0] count;
	
	always@(posedge clock) begin
		if(!reset)begin
			count <= 4'd0;
			end
		else begin
			if (enable) begin
				if(count < in) begin
					count <= count + 1'b1;
					end
				else begin
					count <= 4'b0;
					end
				end
			end
	end
	
	always@(*) begin
		q <= count;
	end
endmodule
