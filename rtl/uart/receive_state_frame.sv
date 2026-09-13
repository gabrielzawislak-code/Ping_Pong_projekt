/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * CLIENT: decodes the 13-byte frame broadcast by the HOST board (both
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
 *
 * BYTE_1..BYTE_10 just shift the 10 raw payload bytes into raw_payload;
 * they are not unpacked into fields until PARITY has read the Hamming
 * byte and TERM has both checked the 0xAA terminator and asked
 * hamming_decode() whether the payload is clean/correctable/corrupt (see
 * hamming_secded.sv). The frame is only committed to paddle_1_y etc. if
 * the terminator matches AND the payload was clean or a single flipped
 * bit could be corrected - a frame with two or more flipped bits is
 * dropped instead of being displayed as garbage.
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
    output logic [2:0] flag_char
);

    import hamming_secded_pkg::*;

    localparam logic [2:0] FLAG_IDLE = 3'b001;

    logic [10:0] paddle_1_y_nxt, paddle_2_y_nxt, ball_x_nxt, ball_y_nxt;
    logic [3:0] score_1_nxt, score_2_nxt;

    logic [79:0] raw_payload, raw_payload_nxt;
    logic [7:0] parity_byte, parity_byte_nxt;
    logic [81:0] decoded; // {status[1:0], corrected raw_payload[79:0]}

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
        PARITY,
        TERM
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
           parity_byte <= '0;

           flag_char <= FLAG_IDLE;
           rd_en <= 0;
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
            parity_byte <= parity_byte_nxt;

            flag_char <= flag_char_nxt;
            rd_en <= rd_en_nxt;
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
        parity_byte_nxt = parity_byte;

        rd_en_nxt = 0;
        flag_char_nxt = flag_char;
        counter_nxt = counter;
        decoded = hamming_decode(raw_payload, parity_byte);

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
                    state_nxt = PARITY;
                end
                else if(counter == 12) begin
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

            PARITY: begin
                if(!rx_empty) begin
                    parity_byte_nxt = data_in;
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = PARITY;
                end
            end

            TERM: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;

                    if(data_in == 8'hAA) begin
                        if(decoded[81:80] != 2'd2) begin
                            paddle_1_y_nxt = {decoded[74:72], decoded[71:64]};
                            paddle_2_y_nxt = {decoded[58:56], decoded[55:48]};
                            ball_x_nxt = {decoded[42:40], decoded[39:32]};
                            ball_y_nxt = {decoded[26:24], decoded[23:16]};
                            score_1_nxt = decoded[11:8];
                            score_2_nxt = decoded[3:0];
                        end
                        // decoded[81:80] == 2 (uncorrectable, 2+ flipped
                        // bits): frame dropped, previous state keeps
                        // showing until the next good frame arrives.
                    end
                    // Go through WAIT like every other byte transition,
                    // instead of jumping straight back to BYTE_0.
                    counter_nxt = 0;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = TERM;
                end
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase
    end

endmodule
