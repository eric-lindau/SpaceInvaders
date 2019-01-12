module shot_handler(
  input clock,
  input reset,
  input noshot,
  input [7:0] startX,
  input [7:0] startY,
  input fire,
  output reg [7:0] shotX,
  output reg [7:0] shotY,
  output reg TEST
);	
	reg int_fire;
	//assign thing = int_fire;
	wire slow_clock;
	rate_divider rd(clock, reset, 30'd500000, slow_clock);
	
	always@(*) begin
		TEST <= int_fire;
	end
	
//	always@(posedge clock) begin
//		if (~reset || ~noshot) begin
//			shotX <= startX + 6;
//			shotY <= startY;
//		end
//		else if (fire && ~int_fire) begin
//			shotX <= startX + 6;
//			shotY <= startY - 1;
//		end
//		else if (slow_clock && int_fire) begin
//			if (shotY < startY) begin
//				shotY <= shotY - 1;
//			end
//			else if (shotY <= 1) begin
//				shotY <= startY;
//			end
//			shotX <= shotX;
//		end
//		else if (!int_fire) begin
//				shotX <= startX + 6;
//				shotY <= startY;
//		end
//	end
	always@(posedge clock) begin
		if (~reset || ~noshot) begin
			shotX <= startX + 6;
			shotY <= startY;
		end
		else if (fire && ~int_fire) begin
			shotX <= startX + 6;
			shotY <= startY - 1;
		end
		else if (slow_clock && int_fire) begin
			shotY <= shotY - 1;
			shotX <= shotX;
		end
		else if (~int_fire) begin
			shotX <= startX + 6;
			shotY <= startY;
		end
	end


	
	always@(posedge clock) begin
		if (fire) begin
			int_fire <= 1;
		end
		else if (~reset || ~noshot || (shotY <= 1)) begin
			int_fire <= 0;
		end
	end
endmodule

module collision(
	input clock,
	input reset,
  input [7:0] alienX,
  input [7:0] alienY,
  input [7:0] shotX,
  input [7:0] shotY,
  input [7:0] cannonX,
  input [7:0] cannonY,
	output reg [14:0] alive,
  output reg cannon_alive,
  output reg reset_shot
);
  localparam A_WIDTH = 8'd13,
             A_HEIGHT = 8'd8,
             A_X_DIST = 8'd5,
             A_Y_DIST = 8'd2,
             A_NUM_PER_ROW = 8'd5,
             A_NUM_ROWS = 8'd3;
  
  reg [7:0] indexX;
  reg [7:0] indexY;
  reg [7:0] index;
  always@(posedge clock)
  begin: collision_detect
    if (!reset) begin
      indexX <= 0;
      indexY <= 0;
      index <= 0;
      alive <= 15'b111111111111111;
      cannon_alive <= 1;
      reset_shot <= 0;
    end
    else begin
      if (alive[index] && (alienX + indexX <= shotX && shotX <= alienX + indexX + A_WIDTH && alienY + indexY <= shotY && shotY <= alienY + indexY + A_HEIGHT)) begin
        alive[index] <= 0;
        reset_shot <= 1;
      end
      else begin
        reset_shot <= 0;
      end

      if (alive[index] && (alienY + indexY + A_HEIGHT >= cannonY)) begin
        cannon_alive <= 0;
      end

      if ((index + 1) % A_NUM_PER_ROW == 0) begin
        indexY <= indexY + A_HEIGHT + A_Y_DIST;
        indexX <= 0;
      end
      else begin
        indexX <= indexX + A_WIDTH + A_X_DIST;
      end

      if (index + 1 == A_NUM_PER_ROW * A_NUM_ROWS) begin
        indexX <= 0;
        indexY <= 0;
        index <= 0;
      end
      else begin
        index <= index + 1;
      end
    end
  end
endmodule
