/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * CLIENT: decodes the 12-byte frame broadcast by the HOST board (both
 * paddles, the ball, the score and the current game state) and hands it
 * straight to the local rendering pipeline / ball_pos mux in top_vga -
 * the CLIENT never computes the ball or the score itself, it only
 * mirrors what the HOST reports (its own paddle is still computed
 * locally by paddle_mover, for zero-latency response).
 *
 * BYTE_0 both examines AND (on any outcome) pops the byte it is looking
 * at, so header-hunting always makes forward progress one byte at a
 * time and never re-examines a byte it has already rejected. Every
 * other byte read goes through the WAIT state, which exists purely to
 * let the one-cycle FIFO read latency settle (rd asserted this cycle ->
 * the new byte is only visible on r_data the cycle after) before the
 * next BYTE_x state samples data_in - skipping that settle cycle would
 * make every field read the previous byte instead of its own.
 */
module receive_state_frame(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic [10:0] paddle_1_y,
    output logic [10:0] paddle_2_y,
    output logic [10:0] ball_x,
    output logic [10:0] ball_y,
    output logic [3:0] score_1,
    output logic [3:0] score_2,
    output logic [2:0] flag_char,
    input logic resync,             // periodic force-restart, see top_vga.sv
    output logic [3:0] dbg_state,   // DEBUG: raw FSM state, for LED bring-up
    output logic dbg_frame_ok       // DEBUG: 1-cycle pulse, trailer (0xAA) matched
);

    localparam logic [2:0] FLAG_IDLE = 3'b001;

    logic [10:0] temp_paddle_1, temp_paddle_1_nxt, paddle_1_y_nxt;
    logic [10:0] temp_paddle_2, temp_paddle_2_nxt, paddle_2_y_nxt;
    logic [10:0] temp_ball_x, temp_ball_x_nxt, ball_x_nxt;
    logic [10:0] temp_ball_y, temp_ball_y_nxt, ball_y_nxt;
    logic [3:0] temp_score_1_nxt, temp_score_1, score_1_nxt;
    logic [3:0] temp_score_2_nxt, temp_score_2, score_2_nxt;

    logic [2:0] flag_char_nxt;
    logic rd_en_nxt;
    logic [3:0] counter, counter_nxt;

    enum logic [3:0] {
        BYTE_0,
        WAIT,
        BYTE_1,
        BYTE_2,
        BYTE_3,
        BYTE_4,
        BYTE_5,
        BYTE_6,
        BYTE_7,
        BYTE_8,
        BYTE_9,
        BYTE_10,
        BYTE_11
    } state, state_nxt;

    assign dbg_state = state;

    logic dbg_frame_ok_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
           dbg_frame_ok <= 1'b0;
           paddle_1_y <= 334;
           temp_paddle_1 <= 334;
           paddle_2_y <= 334;
           temp_paddle_2 <= 334;
           ball_x <= 504;
           temp_ball_x <= 504;
           ball_y <= 376;
           temp_ball_y <= 376;
           score_1 <= '0;
           temp_score_1 <= '0;
           score_2 <= '0;
           temp_score_2 <= '0;

           flag_char <= FLAG_IDLE;
           rd_en <= 0;
           counter <= '0;
           state <= BYTE_0;
        end
        else begin
            paddle_1_y <= paddle_1_y_nxt;
            temp_paddle_1 <= temp_paddle_1_nxt;
            paddle_2_y <= paddle_2_y_nxt;
            temp_paddle_2 <= temp_paddle_2_nxt;
            ball_x <= ball_x_nxt;
            temp_ball_x <= temp_ball_x_nxt;
            ball_y <= ball_y_nxt;
            temp_ball_y <= temp_ball_y_nxt;
            score_1 <= score_1_nxt;
            temp_score_1 <= temp_score_1_nxt;
            score_2 <= score_2_nxt;
            temp_score_2 <= temp_score_2_nxt;

            flag_char <= flag_char_nxt;
            rd_en <= rd_en_nxt;
            counter <= counter_nxt;
            state <= state_nxt;
            dbg_frame_ok <= dbg_frame_ok_nxt;
        end
    end

    always_comb begin
        dbg_frame_ok_nxt = 1'b0;
        temp_paddle_1_nxt = temp_paddle_1;
        paddle_1_y_nxt = paddle_1_y;
        temp_paddle_2_nxt = temp_paddle_2;
        paddle_2_y_nxt = paddle_2_y;
        temp_ball_x_nxt = temp_ball_x;
        ball_x_nxt = ball_x;
        temp_ball_y_nxt = temp_ball_y;
        ball_y_nxt = ball_y;
        score_1_nxt = score_1;
        temp_score_1_nxt = temp_score_1;
        score_2_nxt = score_2;
        temp_score_2_nxt = temp_score_2;

        rd_en_nxt = 0;
        flag_char_nxt = flag_char;
        counter_nxt = counter;

        case(state)
            BYTE_0: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;

                    if(data_in[7:4] == 4'hA) begin
                        flag_char_nxt = data_in[2:0];
                        counter_nxt = 1;
                        state_nxt = WAIT;
                    end
                    else begin
                        // Not a header byte - it has still been popped
                        // above, so the next cycle examines a fresh
                        // byte instead of re-checking this same one.
                        state_nxt = BYTE_0;
                    end
                end
                else begin
                    state_nxt = BYTE_0;
                end
            end

            WAIT: begin
                if(counter == 1) begin
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
                else if(counter == 10) begin
                    state_nxt = BYTE_10;
                end
                else if(counter == 11) begin
                    state_nxt = BYTE_11;
                end
                else begin
                    state_nxt = BYTE_0;
                end
            end

            BYTE_1: begin
                temp_paddle_1_nxt[10:8] = data_in[2:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_1;
                end
            end

            BYTE_2: begin
                temp_paddle_1_nxt[7:0] = data_in;

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_2;
                end
            end

            BYTE_3: begin
                temp_paddle_2_nxt[10:8] = data_in[2:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_3;
                end
            end

            BYTE_4: begin
                temp_paddle_2_nxt[7:0] = data_in;

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_4;
                end
            end

            BYTE_5: begin
                temp_ball_x_nxt[10:8] = data_in[2:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_5;
                end
            end

            BYTE_6: begin
                temp_ball_x_nxt[7:0] = data_in;

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_6;
                end
            end

            BYTE_7: begin
                temp_ball_y_nxt[10:8] = data_in[2:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_7;
                end
            end

            BYTE_8: begin
                temp_ball_y_nxt[7:0] = data_in;

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_8;
                end
            end

            BYTE_9: begin
                temp_score_1_nxt = data_in[3:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_9;
                end
            end

            BYTE_10: begin
                temp_score_2_nxt = data_in[3:0];

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_10;
                end
            end

            BYTE_11: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;

                    if(data_in == 8'hAA) begin
                        paddle_1_y_nxt = temp_paddle_1;
                        paddle_2_y_nxt = temp_paddle_2;
                        ball_x_nxt = temp_ball_x;
                        ball_y_nxt = temp_ball_y;
                        score_1_nxt = temp_score_1;
                        score_2_nxt = temp_score_2;
                        dbg_frame_ok_nxt = 1'b1;
                    end
                    state_nxt = BYTE_0;
                end
                else begin
                    state_nxt = BYTE_11;
                end
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase

        // Periodic forced restart: if this FSM is ever stalled waiting on
        // something that never comes (e.g. tx_full stuck, or any other
        // wedge we have not fully root-caused under time pressure), this
        // guarantees it re-tries a fresh frame at least every ~200 ms
        // instead of staying stuck indefinitely. Does not touch the
        // already-committed outputs (ball/paddle/score/flag_char) -
        // only abandons whatever in-progress decode attempt is running.
        if(resync) begin
            state_nxt = BYTE_0;
        end
    end

endmodule
