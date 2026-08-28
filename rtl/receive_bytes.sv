module receive_bytes(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic [10:0] paddle_1_y,
    output logic [10:0] ball_x,
    output logic [10:0] ball_y,
    output logic [3:0] score_1,
    output logic [3:0] score_2,
    output logic rx_wait_info
);
    
    logic [10:0] temp_paddle_1, temp_paddle_1_nxt, paddle_1_y_nxt;
    logic [10:0] temp_ball_x, temp_ball_x_nxt, ball_x_nxt;
    logic [10:0] temp_ball_y, temp_ball_y_nxt, ball_y_nxt;
    logic [3:0] temp_score_1_nxt, temp_score_1, score_1_nxt;
    logic [3:0] temp_score_2_nxt, temp_score_2, score_2_nxt;
    
    logic rx_wait_nxt;
    logic rd_en_nxt;
    logic [2:0] counter, counter_nxt;
    
    enum logic [3:0] {
        IDLE,
        WAIT,
        BYTE_0,
        BYTE_1,
        BYTE_2,
        BYTE_3,
        BYTE_4,
        BYTE_5,
        BYTE_6,
        BYTE_7,
        BYTE_8,
        BYTE_9
    } state, state_nxt;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
           paddle_1_y <= 334;
           temp_paddle_1 <= 334;
           ball_x <= 504;
           temp_ball_x <= 504;
           ball_y <= 376;
           temp_ball_y <= 376;
           score_1 <= '0;
           temp_score_1 <= '0;
           score_2 <= '0;
           temp_score_2 <= '0;

           
           rx_wait_info <= 0;
           rd_en <= 0;
           counter <= '0;
           state <= IDLE;
        end
        else begin
            paddle_1_y <= paddle_1_y_nxt;
            temp_paddle_1 <= temp_paddle_1_nxt;
            ball_x <= ball_x_nxt;
            temp_ball_x <= temp_ball_x_nxt;
            ball_y <= ball_y_nxt;
            temp_ball_y <= temp_ball_y_nxt;
            score_1 <= score_1_nxt;
            temp_score_1 <= temp_score_1_nxt;
            score_2 <= score_2_nxt;
            temp_score_2 <= temp_score_2_nxt;
            
            rx_wait_info <= rx_wait_nxt;
            rd_en <= rd_en_nxt;
            counter <= counter_nxt;
            state <= state_nxt;
        end
    end

    always_comb begin
        temp_paddle_1_nxt = temp_paddle_1;
        paddle_1_y_nxt = paddle_1_y;
        temp_ball_x_nxt = temp_ball_x;
        ball_x_nxt = ball_x;
        temp_ball_y_nxt = temp_ball_y;
        ball_y_nxt = ball_y;
        score_1_nxt = score_1;
        temp_score_1_nxt = temp_score_1;
        score_2_nxt = score_2;
        temp_score_2_nxt = temp_score_2;
        
        rd_en_nxt = 0;
        rx_wait_nxt = 0;
        counter_nxt = counter;

        case(state)
            IDLE: begin
                counter_nxt = '0;
                
                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = IDLE;
                end
            end

            WAIT: begin
                if(counter == 0) begin
                    state_nxt = BYTE_0;
                end
                else if(counter == 1) begin
                    state_nxt = BYTE_1;
                end
                else if(counter == 2) begin
                    state_nxt = BYTE_2;
                end
                else if(counter == 3) begin
                    state_nxt = BYTE_3;
                end
                else if(counter == 4) begin
                    state_nxt = BYTE_4;
                end
                else if(counter == 5) begin
                    state_nxt = BYTE_5;
                end
                else if(counter == 6) begin
                    state_nxt = BYTE_6;
                end
                else if(counter == 7) begin
                    state_nxt = BYTE_7;
                end
                else if(counter == 8) begin
                    state_nxt = BYTE_8;
                end
                else if(counter == 9) begin
                    state_nxt = BYTE_9;
                end
                else begin
                    state_nxt = IDLE;
                end
            end
            
            
            BYTE_0: begin
                if(data_in == 8'hA2) begin
                    rx_wait_nxt = 1;
                end
                
                if(rx_empty == 0) begin
                    if(data_in[7:4] == 4'hA) begin
                        rd_en_nxt = 1;
                        counter_nxt = counter + 1;
                        state_nxt = WAIT;
                    end
                    else begin
                        state_nxt = IDLE;
                    end
                end
                else begin
                    state_nxt = BYTE_0;
                end
            end

            BYTE_1: begin
                temp_paddle_1_nxt[10:8] = data_in[2:0];
                state_nxt = BYTE_1;
                end

            BYTE_2: begin
                temp_paddle_1_nxt[7:0] = data_in;
                state_nxt = BYTE_2;
            end

            BYTE_3: begin
                temp_ball_x_nxt[10:8] = data_in[2:0];
                state_nxt = BYTE_3;
            end

            BYTE_4: begin
                temp_ball_x_nxt[7:0] = data_in;
                state_nxt = BYTE_4;
            end

            BYTE_5: begin
                temp_ball_y_nxt[10:8] = data_in[2:0];
                state_nxt = BYTE_5;
            end

            BYTE_6: begin
                temp_ball_y_nxt[7:0] = data_in;
                state_nxt = BYTE_6;
            end

            BYTE_7: begin
                temp_score_1_nxt = data_in[3:0];
                state_nxt = BYTE_7;
            end

            BYTE_8: begin
                temp_score_2_nxt = data_in[3:0];
                state_nxt = BYTE_8;
            end

            BYTE_9: begin
                if(data_in == 8'hAA) begin
                    paddle_1_y_nxt = temp_paddle_1;
                    ball_x_nxt = temp_ball_x;
                    ball_y_nxt = temp_ball_y;
                    score_1_nxt = temp_score_1;
                    score_2_nxt = temp_score_2;
                    state_nxt = IDLE;
                end
                else begin
                    state_nxt = IDLE;
                end
            end

            default:  begin
                state_nxt = IDLE;
            end
        endcase

        if(!rx_empty) begin
            rd_en_nxt = 1'b1;
            counter_nxt = counter + 1;
            state_nxt = WAIT;
        end
    end
endmodule