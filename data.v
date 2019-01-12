module cannon(
	input clock, 
	input reset, 
	input left, 
	input right,
	input fire,
	input alive,
	output reg [7:0]x,
	output reg [7:0]y,
  output reg firing
);
    localparam MIN_X = 8'b00000001,
               MAX_X = 8'b10000000,
               WIDTH = 8'b00001101,
               STARTING_X = 8'b00010000,
               STARTING_Y = 8'b01101111;
    
    localparam MOVE_MAGNITUDE = 8'b00000001;

    reg [1:0] fire_cooldown;

    wire slow_clock;

    rate_divider rd(clock, reset, 20'b11110100001001000000, slow_clock);
	 
    always@(posedge clock)
    begin: move_cannon
		  if (~reset) begin
				x <= STARTING_X;
				y <= STARTING_Y;
        end
		  else if (alive && slow_clock) begin
			  if (left && x > MIN_X && ~right) begin
					x <= x - MOVE_MAGNITUDE;
			  end
			  if (right && x + WIDTH < MAX_X && ~left) begin
					x <= x + MOVE_MAGNITUDE;
			  end
			end
    end

    always@(posedge clock)
    begin: fire_cannon
        firing <= 0;
        if (!reset) begin
            fire_cooldown <= 2'b0;
        end
        else if (alive && fire && fire_cooldown == 0) begin
            firing <= 1;
            fire_cooldown <= 2'b11;
        end
        else if (fire_cooldown != 0) begin
            fire_cooldown <= fire_cooldown - 1;
        end
    end

endmodule

module aliens(
	input clock,
	input reset,
    input move,
	output reg [7:0] x, 
	output reg [7:0] y
);
    wire left, down, right, up;
    wire slow_clock;
    wire [7:0] w_x, w_y;

    // rate_divider rd(clock, reset, 26'b11111111101000010010000000, slow_clock);
    rate_divider rd(clock, reset, 24'b111111111010000100100000, slow_clock);
	 
	 //assign thing = slow_clock;

    alien_control control(
        clock, slow_clock, reset, move, left, down, right, up
    );

    alien_datapath datapath(
        clock, slow_clock, reset, move, left, down, right, up, w_x, w_y
    );

    always@(posedge clock)
    begin: set
        x <= w_x;
        y <= w_y;
    end
endmodule

module alien_control(
    input clock,
	input slow_clock,
    input reset,
    input move,
    output reg move_left,
    output reg move_down,
    output reg move_right,
    output reg move_up
);
    localparam LEFT = 2'b00,
               DOWN = 2'b01,
               RIGHT = 2'b11,
               DOWN_2 = 2'b10;

    reg [1:0] current_state, next_state;
	 reg [2:0] count;
	 reg go;

    always@(*)
    begin: states
        case (current_state)
            LEFT: next_state = go ? DOWN : LEFT;
            DOWN: next_state = go ? RIGHT : DOWN;
            RIGHT: next_state = go ? DOWN_2 : RIGHT;
            DOWN_2: next_state = go ? LEFT : DOWN_2;
            default: next_state = LEFT;
        endcase
    end

    always@(*)
    begin: set
        if (!reset) begin
            move_left = 0;
            move_down = 0;
            move_right = 0;
            move_up = 0;
        end
        else begin
            case (current_state)
                LEFT: begin
                    move_left = 1;
                    move_down = 0;
                    move_right = 0;
                    move_up = 0;
                end
                DOWN: begin
                    move_left = 0;
                    move_down = 1;
                    move_right = 0;
                    move_up = 0;
                end
                DOWN_2: begin
                    move_left = 0;
                    move_down = 1;
                    move_right = 0;
                    move_up = 0;
                end
                RIGHT: begin
                    move_left = 0;
                    move_down = 0;
                    move_right = 1;
                    move_up = 0;
                end
            endcase
        end
    end

    always@(posedge clock)
    begin: stateset
        if (~reset) begin
				current_state <= LEFT;
        end
        else if (slow_clock && move) begin
				current_state <= next_state;
        end
    end
	 
	 always@(posedge clock)
	 begin: thing
		if (~reset) begin
			count <= 0;
			go <= 0;
		end
		else begin
			if(count == 5) begin
				count <= 0;
				go <= 1;
			end
			else begin
				count <= count + 1'b1;
				go <= 0;
			end
		end
	 end
endmodule

module alien_datapath(
    input clock,
	input slow_clock,
    input reset,
    input move,
    input move_left,
    input move_down,
    input move_right,
    input move_up,
    output reg [7:0] x,
    output reg [7:0] y
);
    localparam STARTING_X = 8'b00011101,
               STARTING_Y = 8'b00010000;

    localparam MOVE_MAGNITUDE = 4'b10;

    always@(posedge clock)
    begin: set
		  if (~reset) begin
			x <= STARTING_X;
            y <= STARTING_Y;
        end
		  else if (slow_clock && move) begin
			  if (move_left) begin
						x <= x - MOVE_MAGNITUDE;
				  end
				  if (move_down) begin
						y <= y + MOVE_MAGNITUDE;
				  end
				  if (move_right) begin
						x <= x + MOVE_MAGNITUDE;
				  end
				  if (move_up) begin
						y <= y - MOVE_MAGNITUDE;
				  end
		   end
    end
endmodule

module rate_divider(
	input clock,
	input reset,
	input [29:0] num,
	output reg slow_clock
);
	reg [29:0] count;
	
//	flip rateFlip(resetNew, input reset, input clock, input ready);
	
	always@(posedge clock)
	begin: set
		if (!reset) begin
			count <= num;
			slow_clock <= 0;
		end
		else begin
			if (count >= 0) begin
				if (count == 0) begin
					count <= num;
					slow_clock <= 1;
				end
				else begin
					slow_clock <= 0;
					count <= count - 1;
				end
			end
			else begin
				count <= 0;
			end
		end
	end
endmodule
