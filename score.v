module score(
	input clock,	//put clock 50 into this
	input draw,		//put rate divider into this
	input reset,	//put reset into this
	input[14:0] scoreIn,	//does nothing right now
	output [7:0] xOut,	//send to VGA x
	output [7:0] yOut,	//send to VGA y
	output [2:0] colourOut,
	output plot, 			//send to VGA writeEn
	output done);
	
	reg[14:0] score;
	reg[3:0] thousands, hundreds, tens, ones;
	wire [7:0] x, y;
	wire [2:0] cOut;
	wire p, d;
	reg start, okay;
	
	//flip flipScore2(draw, reset, clock, drawIn);
	
	//convert binary to decimal
	always@(posedge clock) begin
		if(!reset) begin
			score <= 0;
			thousands <= 0;
			hundreds <= 0;
			tens <= 0;
			ones <= 0;
			start <= 0;
			okay <= 0;
		end
			else if(draw) begin
				score <= scoreIn;
				thousands <= 0;
				hundreds <= 0;
				tens <= 0;
				ones <= 0;
				start <= 0;
				okay <= 1;
			end
			else if(score >= 10'd1000) begin
				score <= score - 10'd1000;
				thousands <= thousands + 1;
				//hundreds <= hundreds;
				//tens <= tens;
				//ones <= ones;
				start <= 0;
			end
			else if(score >= 8'd100) begin
				score <= score - 7'd100;
				//thousands <= thousands;
				hundreds <= hundreds + 1;
				//tens <= tens;
				//ones <= ones;
				start <= 0;
			end
			else if(score >= 4'd10) begin
				score <= score - 4'd10;
				//thousands <= thousands;
				//hundreds <= hundreds;
				tens <= tens + 1;
				//ones <= ones;
				start <= 0;
			end
			else if(score >= 1'd1) begin
				score <= score - 1'd1;
				//thousands <= thousands;
				//hundreds <= hundreds;
				//tens <= tens;
				ones <= ones + 1;
				start <= 0;
			end
			else if((score == 0) && (okay)) begin
				//score <= score;
				//thousands <= thousands;
				//hundreds <= hundreds;
				//tens <= tens;
				//ones <= ones;
				start <= 1;
				okay <= 0;
			end
	end
	
	//send 4 regs into draw module, output a sprite for each digit and count up x and y
	render_score rendScore(clock, start, reset, thousands, hundreds, tens, ones, x, y, cOut, p, d);
	assign xOut = x;
	assign yOut = y;
	assign colourOut = cOut;
	assign plot = p;
	assign done = d;
	
endmodule
				  
module render_score(
	input clock,	//put clock 50 into this
	input drawIn,		//put rate divider into this
	input reset,	//put reset into this
	input[3:0] thou,
	input[3:0] hun,
	input[3:0] ten,
	input[3:0] one,
	output reg[7:0] xOut,	//send to VGA x
	output reg[7:0] yOut,	//send to VGA y
	output [2:0] colourOut,
	output reg plot, 			//send to VGA writeEn
	output reg done);						
	
	wire [2:0] yAdd;
	wire [4:0] update;
	reg [5:0] rowBlock;	//updated
	wire ld, enable, plotOut, stop, clock30Out, draw;
	reg [7:0] x;
	wire [7:0] xOutW;
	wire [6:0] yOutW;
	reg [12:0] row;
	//don't need fsm start, as draw will always be on
	reg fsmStart;
	wire st;
	
	flip flipScore (draw, reset, clock, drawIn);
	
	//updated localparam
	localparam row46 = 5'b01110,	//zero
				  row47 = 5'b10001,
				  row48 = 5'b10001,
				  row49 = 5'b10001,
				  row50 = 5'b01110,
				  row1 = 5'b00111,	//one
				  row2 = 5'b00100,
				  row3 = 5'b00100,
				  row4 = 5'b00100,
				  row5 = 5'b11111,
				  row6 = 5'b11111,	//two
				  row7 = 5'b10000,
				  row8 = 5'b11111,
				  row9 = 5'b00001,
				  row10 =5'b11111,
				  row11 = 5'b11111,	//three
				  row12 = 5'b10000,
				  row13 = 5'b11111,
				  row14 = 5'b10000,
				  row15 = 5'b11111,
				  row16 = 5'b01001,	//four
				  row17 = 5'b01001,
				  row18 = 5'b11111,
				  row19 = 5'b01000,
				  row20 = 5'b01000,
				  row21 = 5'b11111,	//five
				  row22 = 5'b00001,
				  row23 = 5'b11111,
				  row24 = 5'b10000,
				  row25 = 5'b11111,
				  row26 = 5'b11111,	//six
				  row27 = 5'b00001,
				  row28 = 5'b11111,
				  row29 = 5'b10001,
				  row30 = 5'b11111,
				  row31 = 5'b11111,	//seven
				  row32 = 5'b10000,
				  row33 = 5'b01000,
				  row34 = 5'b00100,
				  row35 = 5'b00010,
				  row36 = 5'b11111,	//eight
				  row37 = 5'b10001,
				  row38 = 5'b11111,
				  row39 = 5'b10001,
				  row40 = 5'b11111,
				  row41 = 5'b11111,	//nine
				  row42 = 5'b10001,
				  row43 = 5'b11111,
				  row44 = 5'b10000,
				  row45 = 5'b11111;
	
	//change this to the number of ticks to draw one character
	counter30 count30(clock, draw, reset, clock30Out);
	//change counter 4 to only count from 0-4
	counter4 count4(clock, clock30Out, reset, draw, update);
	
	//updated
	always@(*) begin
		case(update)
			5'd0: begin
			rowBlock = thou*5;
			x <= 8'b0;
			fsmStart = 1'b1;
			done = 1'b0;
			end
			5'd1: begin 
			rowBlock = hun*5;
			fsmStart = 1'b1;
			x <= 8'd6;
			done = 1'b0;
			end
			5'd2: begin 
			rowBlock = ten*5;
			fsmStart = 1'b1;
			x <= 8'd12;
			done = 1'b0;
			end
			5'd3: begin 
			rowBlock = one*5;
			fsmStart = 1'b1;
			x <= 8'd18;
			done = 1'b0;
			end
			5'd4: begin 
			rowBlock = 6'b0;
			fsmStart = 1'b0;
			done = 1'b1;
			x <= 8'd0;
			end
			default: begin
			rowBlock = 6'b0;
			fsmStart = 1'b0;
			done = 1'b0;
			x <= 8'd0;
			end
		endcase
	end
	
	//changed always
	always@(*) begin
		case(yAdd+rowBlock)
		6'd0: row = row46;
		6'd1: row = row47;
		6'd2: row = row48;
		6'd3: row = row49;
		6'd4: row = row50;
		6'd5: row = row1;
		6'd6: row = row2;
		6'd7: row = row3;
		6'd8: row = row4;
		6'd9: row = row5;
		6'd10: row = row6;
		6'd11: row = row7;
		6'd12: row = row8;
		6'd13: row = row9;
		6'd14: row = row10;
		6'd15: row = row11;
		6'd16: row = row12;
		6'd17: row = row13;
		6'd18: row = row14;
		6'd19: row = row15;
		6'd20: row = row16;
		6'd21: row = row17;
		6'd22: row = row18;
		6'd23: row = row19;
		6'd24: row = row20;
		6'd25: row = row21;
		6'd26: row = row22;
		6'd27: row = row23;
		6'd28: row = row24;
		6'd29: row = row25;
		6'd30: row = row26;
		6'd31: row = row27;
		6'd32: row = row28;
		6'd33: row = row29;
		6'd34: row = row30;
		6'd35: row = row31;
		6'd36: row = row32;
		6'd37: row = row33;
		6'd38: row = row34;
		6'd39: row = row35;
		6'd40: row = row36;
		6'd41: row = row37;
		6'd42: row = row38;
		6'd43: row = row39;
		6'd44: row = row40;
		6'd45: row = row41;
		6'd46: row = row42;
		6'd47: row = row43;
		6'd48: row = row44;
		6'd49: row = row45;
		default: row = row46;
		endcase
	end
	
	score_control scoreControl1(clock, reset, fsmStart, st, ld, enable);
	//change x and y to hardcoded values
	score_data scoreData1(clock, reset, ld, enable, 8'd10 + x, (7'd3 + yAdd), row, xOutW, yOutW, plotOut, stop);
	counterScore cs1(clock, reset, st, 3'd4, yAdd);
	flip flipStop2(st, reset, clock, stop);

	assign colourOut = 3'b111;
	always@(*) begin
		xOut <= xOutW;
		yOut <= yOutW;
		plot <= (plotOut && fsmStart);
	end

endmodule

//sends a pulse out every 30 clock cycles
module counter30(
	input clock,
	input resetD,
	input reset, 
	output reg q);
	reg [6:0] count;
	
	always@(posedge clock) begin
		if(!reset) begin
			count <= 7'd0;
			q <= 1'b0;
		end
		else if(resetD) begin
			count <= 7'd0;
			q <= 1'b0;
		end
		else begin
			if(count > 7'd0) begin
				count <= count - 1'b1;
				q = 1'b0;
			end
			else begin
				count <= 7'd29;
				q <= 1'b1;
			end
		end
	end
	
endmodule

//takes in a pulse to start counting up from 0 to 3, stopping once it gets there
//outputs a number from 0-4
module counter4(
	input clock,
	input clock30,
	input reset,
	input start,
	output reg[4:0] q);
	
	reg[4:0] count;
	
	always@(posedge clock) begin
		if(!reset) begin
			count <= 5'd20;
			q <= 5'd20;
		end
		else if(start) begin
				count <= 5'd0;
				q <= count[4:0];
			end
		else if(clock30) begin
			if(count < 5'd4) begin
				count <= count + 1'b1;
				q <= count[4:0];
				end
			else if(count == 5'd4) begin
				count <= 5'd20;
				q <= 5'd4;
			end
		end
	end
endmodule

module score_control(
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

module score_data(
	input clock,
	input reset,
	input ld,						//load state on
	input shift,					//shift state on
	input [7:0]xIn,
	input [6:0]yIn,
	input [12:0]row,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg enableOut, 		//turn on the plot of VGA
	output reg stop);				//send to control to move to next state
	
	reg s;
	reg [3:0]count;
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
				if(count < 4'd3) begin			//plot equals shifter bit
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
	
	shifter alien_shifter(clock, shift, ld, row, shiftOut);
	
endmodule

//change to only 5 bits
module shifterScore(
	input clock,
	input draw,					//tells when to start drawing
	input load,					//loads in a value
	input[12:0] value,
	output reg q);				//bit to be drawn

	reg[12:0] n;
	
	always@(negedge clock) begin
		if(load)begin
			n <= value;
			end
		if(draw) begin
			n <= n >> 1'b1;
		end
	end
	
	always@(*) begin
		q <= n[0];
	end
endmodule

module counterScore(
	input clock,
	input reset,
	input enable,
	input [2:0]in,
	output reg[2:0] q);
	
	reg[2:0] count;
	
	always@(posedge clock) begin
		if(!reset)begin
			count <= 3'd0;
			end
		else begin
			if (enable) begin
				if(count < in) begin
					count <= count + 1'b1;
					end
				else begin
					count <= 3'b0;
					end
				end
			end
	end
	
	always@(*) begin
		q <= count;
	end
endmodule

