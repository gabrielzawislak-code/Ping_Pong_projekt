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

    localparam int SCREEN_WIDTH = 1024;
    localparam int SCREEN_HEIGHT = 768;
    localparam int P1_X_WALL = 46;
    localparam int P2_X_WALL = 978;
    localparam int BALL_SIZE = 16;

    
    enum logic [1:0] {
        ST_START,
        ST_MOVE,
        ST_GOAL
    } state, state_nxt;

    logic [10:0] ball_x_reg, ball_y_reg, ball_x_nxt, ball_y_nxt;
    logic signed [3:0] dx_reg, dy_reg, dx_nxt, dy_nxt;
    logic [3:0] p1_score_reg, p2_score_reg, p1_score_nxt, p2_score_nxt;
    logic [5:0] delay_counter, delay_counter_nxt;

    logic collision_p1, collision_p2;

    assign collision_p1 = (ball_x_reg <= P1_X_WALL) && (ball_x_reg >= (P1_X_WALL - 5)) && ((ball_y_reg + BALL_SIZE) >= paddle_y_1) && (ball_y_reg <= (paddle_y_1 + 100));
    assign collision_p2 = ((ball_x_reg + BALL_SIZE) >= P2_X_WALL) && ((ball_x_reg + BALL_SIZE) <= (P2_X_WALL + 5)) && ((ball_y_reg + BALL_SIZE) >= paddle_y_2) && (ball_y_reg <= (paddle_y_2 + 100));

    assign ball_x = ball_x_reg;
    assign ball_y = ball_y_reg;
    assign score_1 = p1_score_reg;
    assign score_2 = p2_score_reg;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            ball_x_reg <= (SCREEN_WIDTH / 2) - 8;
            ball_y_reg <= (SCREEN_HEIGHT / 2) - 8;
            state <= ST_START;
            dx_reg <= -3;
            dy_reg <= '0;
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
        p1_score_nxt = p1_score_reg;
        p2_score_nxt = p2_score_reg;
        delay_counter_nxt = delay_counter; 
        
        if(flag_char != 3'b011) begin
            state_nxt = ST_START;
            ball_x_nxt = (SCREEN_WIDTH / 2) - 8;
            ball_y_nxt = (SCREEN_HEIGHT / 2) - 8;
            dx_nxt = -3;
            dy_nxt = '0;
            p1_score_nxt = 9;
            p2_score_nxt = 8;
            delay_counter_nxt = '0;
        end
        else if(ref_time) begin
            case(state)
                ST_START: begin
                    ball_x_nxt = (SCREEN_WIDTH / 2) - 8;
                    ball_y_nxt = (SCREEN_HEIGHT / 2) - 8;
                    dx_nxt = -3;
                    dy_nxt = '0;
                    delay_counter_nxt = delay_counter + 1;
                    
                    if(delay_counter == 60) begin
                        state_nxt = ST_MOVE;
                    end
                    else begin
                        state_nxt = ST_START;
                    end
                end

                
                ST_MOVE: begin
                    delay_counter_nxt = '0;
                    ball_x_nxt = ball_x_reg + dx_reg;
                    ball_y_nxt = ball_y_reg + dy_reg;

                    if((ball_y_reg <= 0) || (ball_y_reg >= (SCREEN_HEIGHT - BALL_SIZE))) begin
                        dy_nxt = -dy_reg;
                    end

                    if(collision_p1 && (dx_reg < 0)) begin
                        dx_nxt = 3;
                        
                        if(ball_y_reg < (paddle_y_1 + 20)) begin
                            dy_nxt = -3;
                        end
                        else if(ball_y_reg > (paddle_y_1 + 80)) begin
                            dy_nxt = 3;
                        end
                        else begin
                            dy_nxt = '0;
                        end
                    end

                    if(collision_p2 && (dx_reg > 0)) begin
                        dx_nxt = -3;

                        if(ball_y_reg < (paddle_y_2 + 20)) begin
                            dy_nxt = 3;
                        end
                        else if(ball_y_reg > (paddle_y_2 + 80)) begin
                            dy_nxt = 3;
                        end
                        else begin
                            dy_nxt = '0;
                        end
                    end

                    if((ball_x_reg < 16) || (ball_x_reg > (SCREEN_WIDTH - 16))) begin
                        state_nxt = ST_GOAL;
                    end

                    state_nxt = ST_MOVE;
                end


                ST_GOAL: begin
                    if(ball_x_reg < 16) begin
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