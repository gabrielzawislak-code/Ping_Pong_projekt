/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Ball physics. Runs only on this (MASTER) board, which owns the whole
 * game simulation.
 *
 * All playfield geometry (paddle planes, ball size, top/bottom border)
 * comes from vga_pkg, so the physics here and the renderer can never
 * disagree about where a paddle or a wall actually is.
 *
 * Movement model: every tick, the ball's tentative next position on each
 * axis is computed in a widened, explicitly SIGNED intermediate (so a
 * value that would go negative compares correctly instead of silently
 * wrapping around to a huge number - the classic unsigned-subtraction
 * trap). If that tentative position would cross a paddle's face or the
 * top/bottom border, the ball is clamped exactly onto that plane and its
 * velocity on that axis is reflected - in the very same tick, so the
 * ball can never travel into or past whatever it just hit, no matter how
 * fast it is currently moving. Touching the left or right edge of the
 * screen is not a bounce - it ends the point.
 *
 * The ball serves slowly and speeds up by one unit on every paddle
 * return (capped at MAX_SPEED), resetting to the slow serve speed after
 * each point. The vertical deflection off a paddle depends on where
 * along the paddle the ball made contact - a hit near an edge deflects
 * sharply, a hit near the middle stays close to horizontal. The serve
 * direction/angle is picked from a free-running LFSR so it varies from
 * game to game.
 */
module ball_pos(
    input logic clk,
    input logic rst_n,
    input logic [2:0] flag_char,
    input logic ref_time,
    input logic [10:0] paddle_y_1,
    input logic [10:0] paddle_y_2,
    output logic [10:0] ball_x,
    output logic [10:0] ball_y,
    output logic [3:0] score_1,
    output logic [3:0] score_2
);

    import vga_pkg::*;

    localparam logic signed [3:0] START_SPEED = 4'sd2;
    localparam logic signed [3:0] MAX_SPEED   = 4'sd7;
    localparam int SERVE_DELAY = 60;

    localparam int SERVE_X = (HOR_PIXELS / 2) - (BALL_SIZE / 2);
    localparam int SERVE_Y = (VER_PIXELS / 2) - (BALL_SIZE / 2);

    localparam int TOP_LIMIT    = BORDER_MARGIN;
    localparam int BOTTOM_LIMIT = VER_PIXELS - BORDER_MARGIN - BALL_SIZE;

    enum logic [1:0] {
        ST_START,
        ST_MOVE,
        ST_GOAL
    } state, state_nxt;

    logic [10:0] ball_x_reg, ball_y_reg, ball_x_nxt, ball_y_nxt;
    logic signed [3:0] dx_reg, dy_reg, dx_nxt, dy_nxt;
    logic signed [3:0] speed_reg, speed_nxt;
    logic [3:0] p1_score_reg, p2_score_reg, p1_score_nxt, p2_score_nxt;
    logic [5:0] delay_counter, delay_counter_nxt;

    /**
     * Free-running pseudo-random source (maximal-length 8-bit LFSR),
     * used only to pick the ball's serve direction/angle. It shifts
     * every clock cycle regardless of game state, so the bits sampled at
     * the human-timed moment of serving are effectively unpredictable.
     */
    logic [7:0] lfsr_reg;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            lfsr_reg <= 8'hA5;
        end
        else begin
            lfsr_reg <= {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};
        end
    end

    // Tentative next position using the CURRENT velocity, widened and
    // explicitly signed so a would-be negative result compares correctly
    // instead of wrapping around like a plain unsigned subtraction would.
    logic signed [12:0] x_tent, y_tent;
    assign x_tent = $signed({1'b0, ball_x_reg}) + dx_reg;
    assign y_tent = $signed({1'b0, ball_y_reg}) + dy_reg;

    // Does the ball's CURRENT vertical span overlap a given paddle's
    // vertical span? Evaluated at the moment the ball's horizontal plane
    // reaches that paddle.
    logic paddle1_y_overlap, paddle2_y_overlap;
    assign paddle1_y_overlap = ((ball_y_reg + BALL_SIZE) > paddle_y_1) && (ball_y_reg < (paddle_y_1 + PADDLE_HEIGHT));
    assign paddle2_y_overlap = ((ball_y_reg + BALL_SIZE) > paddle_y_2) && (ball_y_reg < (paddle_y_2 + PADDLE_HEIGHT));

    // Hit-position-based deflection: how far the ball's center currently
    // is from a paddle's center, scaled down with a shift instead of a
    // divider - the offset magnitude (at most half a paddle plus half
    // the ball) always fits after the shift.
    logic signed [12:0] ball_center_y, offset_p1, offset_p2;
    logic signed [3:0] deflect_p1, deflect_p2;
    assign ball_center_y = $signed({1'b0, ball_y_reg}) + (BALL_SIZE / 2);
    assign offset_p1 = ball_center_y - ($signed({1'b0, paddle_y_1}) + (PADDLE_HEIGHT / 2));
    assign offset_p2 = ball_center_y - ($signed({1'b0, paddle_y_2}) + (PADDLE_HEIGHT / 2));
    assign deflect_p1 = offset_p1 >>> 4;
    assign deflect_p2 = offset_p2 >>> 4;

    assign ball_x = ball_x_reg;
    assign ball_y = ball_y_reg;
    assign score_1 = p1_score_reg;
    assign score_2 = p2_score_reg;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            ball_x_reg <= 11'(SERVE_X);
            ball_y_reg <= 11'(SERVE_Y);
            state <= ST_START;
            dx_reg <= -START_SPEED;
            dy_reg <= '0;
            speed_reg <= START_SPEED;
            p1_score_reg <= '0;
            p2_score_reg <= '0;
            delay_counter <= '0;
        end
        else begin
            ball_x_reg <= ball_x_nxt;
            ball_y_reg <= ball_y_nxt;
            state <= state_nxt;
            dx_reg <= dx_nxt;
            dy_reg <= dy_nxt;
            speed_reg <= speed_nxt;
            p1_score_reg <= p1_score_nxt;
            p2_score_reg <= p2_score_nxt;
            delay_counter <= delay_counter_nxt;
        end
    end

    always_comb begin
        ball_x_nxt = ball_x_reg;
        ball_y_nxt = ball_y_reg;
        state_nxt = state;
        dx_nxt = dx_reg;
        dy_nxt = dy_reg;
        speed_nxt = speed_reg;
        p1_score_nxt = p1_score_reg;
        p2_score_nxt = p2_score_reg;
        delay_counter_nxt = delay_counter;

        if(flag_char != 3'b011) begin
            state_nxt = ST_START;
            ball_x_nxt = 11'(SERVE_X);
            ball_y_nxt = 11'(SERVE_Y);
            speed_nxt = START_SPEED;
            delay_counter_nxt = '0;
        end
        else if(ref_time) begin
            case(state)
                ST_START: begin
                    ball_x_nxt = 11'(SERVE_X);
                    ball_y_nxt = 11'(SERVE_Y);
                    speed_nxt = START_SPEED;
                    delay_counter_nxt = delay_counter + 1;

                    if(delay_counter == SERVE_DELAY) begin
                        dx_nxt = lfsr_reg[3] ? -START_SPEED : START_SPEED;

                        case(lfsr_reg[2:0])
                            3'd0: dy_nxt = -3;
                            3'd1: dy_nxt = -2;
                            3'd2: dy_nxt = -1;
                            3'd3: dy_nxt = 0;
                            3'd4: dy_nxt = 1;
                            3'd5: dy_nxt = 2;
                            3'd6: dy_nxt = 3;
                            default: dy_nxt = 0;
                        endcase

                        state_nxt = ST_MOVE;
                    end
                    else begin
                        state_nxt = ST_START;
                    end
                end


                ST_MOVE: begin
                    delay_counter_nxt = '0;

                    // --- Vertical axis: bounce off the top/bottom border ---
                    if(y_tent <= TOP_LIMIT) begin
                        ball_y_nxt = 11'(TOP_LIMIT);
                        dy_nxt = (dy_reg < 0) ? -dy_reg : dy_reg;
                    end
                    else if(y_tent >= BOTTOM_LIMIT) begin
                        ball_y_nxt = 11'(BOTTOM_LIMIT);
                        dy_nxt = (dy_reg > 0) ? -dy_reg : dy_reg;
                    end
                    else begin
                        ball_y_nxt = 11'(y_tent);
                        dy_nxt = dy_reg;
                    end

                    // --- Horizontal axis: paddle bounce, or a goal ---
                    if((dx_reg < 0) && paddle1_y_overlap && (x_tent <= P1_X_WALL)) begin
                        speed_nxt = (speed_reg < MAX_SPEED) ? (speed_reg + 4'sd1) : MAX_SPEED;
                        ball_x_nxt = 11'(P1_X_WALL);
                        dx_nxt = speed_nxt;
                        dy_nxt = deflect_p1;
                    end
                    else if((dx_reg > 0) && paddle2_y_overlap && ((x_tent + BALL_SIZE) >= P2_X_WALL)) begin
                        speed_nxt = (speed_reg < MAX_SPEED) ? (speed_reg + 4'sd1) : MAX_SPEED;
                        ball_x_nxt = 11'(P2_X_WALL - BALL_SIZE);
                        dx_nxt = -speed_nxt;
                        dy_nxt = deflect_p2;
                    end
                    else if(x_tent <= 0) begin
                        state_nxt = ST_GOAL;
                    end
                    else if((x_tent + BALL_SIZE) >= HOR_PIXELS) begin
                        state_nxt = ST_GOAL;
                    end
                    else begin
                        ball_x_nxt = 11'(x_tent);
                        dx_nxt = dx_reg;
                    end
                end


                ST_GOAL: begin
                    if(ball_x_reg < (HOR_PIXELS / 2)) begin
                        p2_score_nxt = p2_score_reg + 1;
                    end
                    else begin
                        p1_score_nxt = p1_score_reg + 1;
                    end

                    state_nxt = ST_START;
                end

                default: begin
                    state_nxt = ST_START;
                end
            endcase
        end
    end
endmodule
