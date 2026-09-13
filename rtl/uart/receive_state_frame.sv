/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * CLIENT: decodes the 12-byte frame sent by the HOST (paddles, ball,
 * score, game state) and passes it to the rendering pipeline / ball_pos
 * mux in top_vga. The CLIENT does not compute the ball or score itself,
 * it just mirrors the HOST; its own paddle is still computed locally by
 * paddle_mover.
 *
 * BYTE_0 checks and pops the byte in the same step. Every other byte
 * goes through WAIT first, to let the FIFO's one-cycle read latency
 * settle before the next state reads data_in.
 *
 * Payload bytes are unpacked into fields only once TERM sees the 0xAA
 * terminator; a bad terminator drops the frame. flag_char works the
 * same way - the header byte alone is not enough to trust it, so it is
 * held in pending_flag until TERM confirms the frame.
 *
 * RESYNC: a failed frame usually means header hunting locked onto the
 * wrong byte. Going straight back to BYTE_0 would repeat the same
 * mistake every frame (fixed frame length), so RESYNC eats one extra
 * byte first to shift the alignment.
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
    output logic frame_valid, // pulses when a frame is committed
    output logic header_seen, // pulses when BYTE_0 finds a candidate header
    output logic resync_hit   // pulses when a failed frame triggers RESYNC
);

    localparam logic [2:0] FLAG_IDLE = 3'b001;

    logic [10:0] paddle_1_y_nxt, paddle_2_y_nxt, ball_x_nxt, ball_y_nxt;
    logic [3:0] score_1_nxt, score_2_nxt;

    logic [79:0] raw_payload, raw_payload_nxt;
    logic [2:0] pending_flag, pending_flag_nxt;

    logic [2:0] flag_char_nxt;
    logic rd_en_nxt;
    logic frame_valid_nxt;
    logic header_seen_nxt;
    logic resync_hit_nxt;
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
        TERM,
        RESYNC
    } state, state_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
           paddle_1_y <= 334;
           paddle_2_y <= 334;
           ball_x <= 504;
           ball_y <= 376;
           score_1 <= '0;
           score_2 <= '0;

           raw_payload <= '0;
           pending_flag <= FLAG_IDLE;

           flag_char <= FLAG_IDLE;
           rd_en <= 0;
           frame_valid <= 0;
           header_seen <= 0;
           resync_hit <= 0;
           counter <= '0;
           state <= BYTE_0;
        end
        else begin
            paddle_1_y <= paddle_1_y_nxt;
            paddle_2_y <= paddle_2_y_nxt;
            ball_x <= ball_x_nxt;
            ball_y <= ball_y_nxt;
            score_1 <= score_1_nxt;
            score_2 <= score_2_nxt;

            raw_payload <= raw_payload_nxt;
            pending_flag <= pending_flag_nxt;

            flag_char <= flag_char_nxt;
            rd_en <= rd_en_nxt;
            frame_valid <= frame_valid_nxt;
            header_seen <= header_seen_nxt;
            resync_hit <= resync_hit_nxt;
            counter <= counter_nxt;
            state <= state_nxt;
        end
    end

    always_comb begin
        paddle_1_y_nxt = paddle_1_y;
        paddle_2_y_nxt = paddle_2_y;
        ball_x_nxt = ball_x;
        ball_y_nxt = ball_y;
        score_1_nxt = score_1;
        score_2_nxt = score_2;

        raw_payload_nxt = raw_payload;
        pending_flag_nxt = pending_flag;

        rd_en_nxt = 0;
        flag_char_nxt = flag_char;
        frame_valid_nxt = 0;
        header_seen_nxt = 0;
        resync_hit_nxt = 0;
        counter_nxt = counter;

        case(state)
            BYTE_0: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;

                    if(data_in[7:4] == 4'hA) begin
                        // held until TERM confirms the frame
                        pending_flag_nxt = data_in[2:0];
                        header_seen_nxt = 1;
                        counter_nxt = 1;
                        state_nxt = WAIT;
                    end
                    else begin
                        // not a header, byte already popped
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
                    state_nxt = TERM;
                end
                else begin
                    state_nxt = BYTE_0;
                end
            end

            BYTE_1: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_1;
                end
            end

            BYTE_2: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_2;
                end
            end

            BYTE_3: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_3;
                end
            end

            BYTE_4: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_4;
                end
            end

            BYTE_5: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_5;
                end
            end

            BYTE_6: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_6;
                end
            end

            BYTE_7: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_7;
                end
            end

            BYTE_8: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_8;
                end
            end

            BYTE_9: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_9;
                end
            end

            BYTE_10: begin
                if(!rx_empty) begin
                    raw_payload_nxt = {raw_payload[71:0], data_in};
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_10;
                end
            end

            TERM: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = 0;

                    if(data_in == 8'hAA) begin
                        paddle_1_y_nxt = {raw_payload[74:72], raw_payload[71:64]};
                        paddle_2_y_nxt = {raw_payload[58:56], raw_payload[55:48]};
                        ball_x_nxt = {raw_payload[42:40], raw_payload[39:32]};
                        ball_y_nxt = {raw_payload[26:24], raw_payload[23:16]};
                        score_1_nxt = raw_payload[11:8];
                        score_2_nxt = raw_payload[3:0];
                        flag_char_nxt = pending_flag;
                        frame_valid_nxt = 1;
                        state_nxt = WAIT;
                    end
                    else begin
                        // bad terminator, see RESYNC above
                        resync_hit_nxt = 1;
                        state_nxt = RESYNC;
                    end
                end
                else begin
                    state_nxt = TERM;
                end
            end

            RESYNC: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = RESYNC;
                end
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase
    end

endmodule
