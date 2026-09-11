/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * HOST: decodes the small CLIENT -> HOST frame - the peer's own paddle
 * position (fed straight into ball_pos as paddle_y_2) and its local
 * game_fsm state (fed into this board's game_fsm as peer_state for the
 * READY handshake).
 *
 * Frame layout: [header][paddle_y hi][paddle_y lo][0xAA]
 * header = {4'hB, flag_char[2:0]}
 */
module receive_paddle_frame(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic [10:0] paddle_y,
    output logic [2:0] peer_flag_char
);

    localparam logic [2:0] FLAG_IDLE = 3'b001;

    logic [10:0] temp_paddle, temp_paddle_nxt, paddle_y_nxt;
    logic [2:0] peer_flag_char_nxt;
    logic rd_en_nxt;

    enum logic [2:0] {
        BYTE_0,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } state, state_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            paddle_y <= 334;
            temp_paddle <= 334;
            peer_flag_char <= FLAG_IDLE;
            rd_en <= 1'b0;
            state <= BYTE_0;
        end
        else begin
            paddle_y <= paddle_y_nxt;
            temp_paddle <= temp_paddle_nxt;
            peer_flag_char <= peer_flag_char_nxt;
            rd_en <= rd_en_nxt;
            state <= state_nxt;
        end
    end

    always_comb begin
        temp_paddle_nxt = temp_paddle;
        paddle_y_nxt = paddle_y;
        peer_flag_char_nxt = peer_flag_char;
        rd_en_nxt = 1'b0;
        state_nxt = state;

        case(state)
            BYTE_0: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;

                    if(data_in[7:4] == 4'hB) begin
                        peer_flag_char_nxt = data_in[2:0];
                        state_nxt = BYTE_1;
                    end
                    // else: not our header - stay in BYTE_0, resync on the next byte
                end
            end

            BYTE_1: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
                    temp_paddle_nxt[10:8] = data_in[2:0];
                    state_nxt = BYTE_2;
                end
            end

            BYTE_2: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
                    temp_paddle_nxt[7:0] = data_in;
                    state_nxt = BYTE_3;
                end
            end

            BYTE_3: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;

                    if(data_in == 8'hAA) begin
                        paddle_y_nxt = temp_paddle;
                    end
                    state_nxt = BYTE_0;
                end
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase
    end

endmodule
