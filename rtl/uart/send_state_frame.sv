/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * HOST -> CLIENT frame. Periodically (every ref_time tick) sends a fixed
 * 13-byte frame describing the local game state and everything the peer
 * needs to render an identical screen: both paddles, the ball and the
 * score (the HOST owns the whole game simulation). Every write is gated
 * on tx_full so a byte is only pushed into the UART TX FIFO once there is
 * room for it - nothing is ever silently dropped, no matter how deep the
 * FIFO actually is.
 *
 * Frame layout: [header][paddle_1_y hi][paddle_1_y lo]
 *               [paddle_2_y hi][paddle_2_y lo]
 *               [ball_x hi][ball_x lo][ball_y hi][ball_y lo]
 *               [score_1][score_2][hamming parity][0xAA]
 * header = {4'hA, flag_char[2:0]} -> 0xA1 IDLE, 0xA2 READY, 0xA3 PLAYING, 0xA4 END
 * The 10 payload bytes (everything between header and parity) are
 * protected by a Hamming SECDED code - see hamming_secded.sv - so the
 * receiver can correct a single bit flipped on the wire instead of
 * silently committing a corrupted state.
 */
module send_state_frame(
    input logic clk,
    input logic rst_n,
    input logic [2:0] flag_char,
    input logic ref_time,
    input logic tx_full,
    input logic [10:0] paddle_1_y,
    input logic [10:0] paddle_2_y,
    input logic [10:0] ball_x,
    input logic [10:0] ball_y,
    input logic [3:0] score_1,
    input logic [3:0] score_2,
    output logic [7:0] data_out,
    output logic wr_en
);

    import hamming_secded_pkg::*;

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

    logic wr_en_nxt;
    logic [7:0] data_out_nxt;
    logic [79:0] payload, payload_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_out <= '0;
            wr_en <= '0;
            state <= BYTE_0;
            payload <= '0;
        end
        else begin
            data_out <= data_out_nxt;
            state <= state_nxt;
            wr_en <= wr_en_nxt;
            payload <= payload_nxt;
        end
    end

    always_comb begin
        data_out_nxt = data_out;
        wr_en_nxt = '0;
        state_nxt = state;
        payload_nxt = payload;

        case(state)
            BYTE_0: begin
                if(!tx_full) begin
                    if(flag_char == 3'b001) begin
                        data_out_nxt = 8'hA1;
                    end
                    else if(flag_char == 3'b010) begin
                        data_out_nxt = 8'hA2;
                    end
                    else if(flag_char == 3'b011) begin
                        data_out_nxt = 8'hA3;
                    end
                    else begin
                        data_out_nxt = 8'hA4;
                    end

                    wr_en_nxt = 1'b1;
                    state_nxt = ref_time ? BYTE_1 : WAIT;
                end
            end

            WAIT: begin
                if(ref_time) begin
                    state_nxt = BYTE_1;
                end
            end

            BYTE_1: begin
                if(!tx_full) begin
                    data_out_nxt = {5'b0, paddle_1_y[10:8]};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_2;
                end
            end

            BYTE_2: begin
                if(!tx_full) begin
                    data_out_nxt = paddle_1_y[7:0];
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_3;
                end
            end

            BYTE_3: begin
                if(!tx_full) begin
                    data_out_nxt = {5'b0, paddle_2_y[10:8]};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_4;
                end
            end

            BYTE_4: begin
                if(!tx_full) begin
                    data_out_nxt = paddle_2_y[7:0];
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_5;
                end
            end

            BYTE_5: begin
                if(!tx_full) begin
                    data_out_nxt = {5'b0, ball_x[10:8]};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_6;
                end
            end

            BYTE_6: begin
                if(!tx_full) begin
                    data_out_nxt = ball_x[7:0];
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_7;
                end
            end

            BYTE_7: begin
                if(!tx_full) begin
                    data_out_nxt = {5'b0, ball_y[10:8]};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_8;
                end
            end

            BYTE_8: begin
                if(!tx_full) begin
                    data_out_nxt = ball_y[7:0];
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_9;
                end
            end

            BYTE_9: begin
                if(!tx_full) begin
                    data_out_nxt = {4'b0, score_1};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_10;
                end
            end

            BYTE_10: begin
                if(!tx_full) begin
                    data_out_nxt = {4'b0, score_2};
                    payload_nxt = {payload[71:0], data_out_nxt};
                    wr_en_nxt = 1'b1;
                    state_nxt = PARITY;
                end
            end

            PARITY: begin
                if(!tx_full) begin
                    data_out_nxt = hamming_encode(payload_nxt);
                    wr_en_nxt = 1'b1;
                    state_nxt = TERM;
                end
            end

            TERM: begin
                if(!tx_full) begin
                    data_out_nxt = 8'hAA;
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_0;
                end
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase
    end

endmodule
