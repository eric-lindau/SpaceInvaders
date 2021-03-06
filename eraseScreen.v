module eraseScreen(
	input clock,	//put clock 50 into this
	input draw,		//put rate divider into this
	input reset,	//put reset into this
	output reg[7:0] xOut,	//send to VGA x
	output reg[7:0] yOut,	//send to VGA y
	output [2:0] colourOut,
	output reg plot,
	output reg done);		//send to render alien when finished
	
	reg[14:0] count;
	
	always @(posedge clock)	begin
	if (!reset) begin
		count <= 15'b100000000000001;
		done <= 1'b0;
		xOut <= 8'd0;
		yOut <= 8'd0;
		plot = 1'b0;
		end
	else begin
		if(draw) begin
			count <= 15'd0;
			done <= 1'b0;
			xOut <= count[6:0];
			yOut <= count[13:7];
			plot <= 1'b1;
			end
		else if(count < 15'b100000000000000) begin
			count <= count + 1'b1;
			done <= 1'b0;
			xOut <= count[6:0];
			yOut <= count[13:7];
			plot <= 1'b1;
			end
		else if(count == 15'b100000000000000) begin
			count <= count + 1'b1;
			done <= 1'b1;
			xOut <= count[6:0];
			yOut <= count[13:7];
			plot <= 1'b0;
			end
		else begin
			count <= count;
			done <= 1'b0;
			xOut <= 8'd0;
			yOut <= 8'd0;
			plot <= 1'b0;
			end
		end
	end
	
	assign colourOut = 3'b000;
	
endmodule
