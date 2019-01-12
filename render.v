module render(
	input clock,	//put clock 50 into this
	input draw,		//put rate divider into this
	input reset,	//put reset into this
	input[7:0] shotX,
	input[7:0] shotY,
	input[7:0] cannonX,
	input[7:0] cannonY,
	input[7:0] alienX,
	input[7:0] alienY,
	input[14:0] alive,	//does nothing right now
	input[14:0] scoreIn,
	input over,
	output reg[7:0] x,	//send to VGA x
	output reg[7:0] y,	//send to VGA y
	output reg plot,
	output reg[2:0] colourOut);			//send to VGA writeEn
	
	wire ld, alien, cannon, stop, done, plot1, plot2, plot3, done2, plot4, done4, plotOver;
	wire [2:0]cOut1,  cOut2, cOut4, cOver;
	wire [7:0]xOut1, yOut1, xOut2, yOut2, xOut3, yOut3, xOut4, yOut4, xOver, yOver;
	
	//erase erasePart(clock, draw, reset, cannonX, cannonY, alienX, alienY, xOut1, yOut1, cOut1, plot1, done);
	
	eraseScreen eraseAll(clock, (draw && ~over), reset, xOut1, yOut1, cOut1, plot1, done);
	
	render_sprites renderSprites(clock, done, reset, cannonX, cannonY, alienX, alienY, alive, xOut2, yOut2, cOut2, plot2, done2);
	
	score drawScore(clock, done2, reset, scoreIn, xOut4, yOut4, cOut4, plot4, done4);
	
	drawShot drawBullet(clock, reset, done4, shotX, shotY, xOut3, yOut3, plot3);
	
	game_over gameover(clock, draw, reset, over, xOver, yOver, cOver, plotOver);
	
//	always@(*) begin
//		thing <= done2;
//	end
	
	reg[1:0] choose;
	
	always@(posedge clock) begin
		if(!reset) begin
			choose <= 2'b00;
		end
		else if(draw) begin
			choose <= 2'b01;
		end
		else if(done) begin
			choose <= 2'b00;
		end
		else if(done2) begin
			choose <= 2'b10;
		end
	end
	
	always@(posedge clock) begin
		if(over) begin
			x <= xOver;
			y <= yOver;
			plot <= plotOver;
		end
		else if(choose == 2'b01) begin
			x <= xOut1;
			y <= yOut1;
			plot <= plot1;
		end
		else if(choose == 2'b00) begin
			x <= xOut2;
			y <= yOut2;
			plot <= plot2;
		end
		else if(done4) begin
			x <= xOut3;
			y <= yOut3;
			plot <= plot3;
		end
		else if(choose == 2'b10) begin
			x <= xOut4;
			y <= yOut4;
			plot <= plot4;
		end
	end
	
	always@(posedge clock) begin
		if(!reset) begin
			colourOut <= 3'd0;
		end
		else if(over) begin
			colourOut <= cOver;
		end
		else if (choose == 2'b01) begin
			colourOut <= cOut1;
		end
		else if(choose == 2'b00) begin
			colourOut <= cOut2;
		end
		else if(done4) begin
			colourOut <= 3'b010;
		end
		else if(choose == 2'b10) begin
			colourOut <= 3'b111;
		end
	end
	
endmodule

module drawShot(
	input clock,
	input reset,
	input draw,
	input[7:0] shotX,
	input[7:0] shotY,
	output [7:0] x,
	output [7:0] y, 
	output reg plot);
	
	reg[1:0] count;
	wire go;
	
	flip shotFlip(go, reset, clock, draw);
	
	always@(posedge clock) begin
		if(!reset) begin
			plot <= 1'b0;
			count <= 2'b11;
		end
		else if (go) begin
			plot <= 1'b1;
			count <= 2'b00;
		end
		else if(count < 2'b1) begin
			plot <= 1'b1;
			count <= count + 1'b1;
		end
		else begin
			plot <= 1'b0;
			count <=2'b11;
		end
	end
	
	assign x = shotX;
	assign y = shotY + count;
	
endmodule
