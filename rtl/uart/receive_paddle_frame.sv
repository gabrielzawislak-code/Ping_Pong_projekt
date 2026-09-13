/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * HOST: decodes the small CLIENT -> HOST frame - the peer's paddle
 * position (fed into ball_pos as paddle_y_2) and its game_fsm state
 * (fed into this board's game_fsm as peer_state for the READY
 * handshake).
 *
 * Frame layout: [header][paddle_y hi][paddle_y lo][0xAA]
 * header = {4'hB, flag_char[2:0]}
 *
 * BYTE_0 checks and pops the byte in the same step. Every other byte
 * goes through WAIT first, to let the FIFO's one-cycle read latency
 * settle before the next state reads data_in.
 *
 * peer_flag_char is buffered the same way paddle_y is: BYTE_0 stashes
 * the header's flag bits into temp_flag, and it is only committed to
 * peer_flag_char once BYTE_3 confirms the 0xAA terminator.
 *
 * RESYNC: a failed frame usually means header hunting locked onto the
 * wrong byte. Going straight back to BYTE_0 would repeat the same
 * mistake every frame (fixed frame length), so RESYNC eats one extra
 * byte first to shift the alignment.
 */
module receive_paddle_frame(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic [10:0] paddle_y,
    output logic [2:0] peer_flag_char,
    output logic frame_valid // pulses when a frame is committed
);

    localparam logic [2:0] FLAG_IDLE = 3'b001;

    logic [10:0] temp_paddle, temp_paddle_nxt, paddle_y_nxt;
    logic [2:0] temp_flag, temp_flag_nxt;
    logic [2:0] peer_flag_char_nxt;
    logic rd_en_nxt;
    logic frame_valid_nxt;
    logic [1:0] counter, counter_nxt;

    enum logic [2:0] {
        BYTE_0,
        WAIT,
        BYTE_1,
        BYTE_2,
        BYTE_3,
        RESYNC
    } state, state_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            paddle_y <= 334;
            temp_paddle <= 334;
            temp_flag <= FLAG_IDLE;
            peer_flag_char <= FLAG_IDLE;
            rd_en <= 1'b0;
            frame_valid <= 1'b0;
            counter <= '0;
            state <= BYTE_0;
        end
        else begin
            paddle_y <= paddle_y_nxt;
            temp_paddle <= temp_paddle_nxt;
            temp_flag <= temp_flag_nxt;
            peer_flag_char <= peer_flag_char_nxt;
            rd_en <= rd_en_nxt;
            frame_valid <= frame_valid_nxt;
            counter <= counter_nxt;
            state <= state_nxt;
        end
    end

    always_comb begin
        temp_paddle_nxt = temp_paddle;
        paddle_y_nxt = paddle_y;
        temp_flag_nxt = temp_flag;
        peer_flag_char_nxt = peer_flag_char;
        rd_en_nxt = 1'b0;
        frame_valid_nxt = 1'b0;
        counter_nxt = counter;
        state_nxt = state;

        case(state)
            BYTE_0: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;

                    if(data_in[7:4] == 4'hB) begin
                        temp_flag_nxt = data_in[2:0];
                        counter_nxt = 2'd1;
                        state_nxt = WAIT;
                    end
                    else begin
                        // not a header, byte already popped
                        state_nxt = BYTE_0;
                    end
                end
            end

            WAIT: begin
                case(counter)
                    2'd1:    state_nxt = BYTE_1;
                    2'd2:    state_nxt = BYTE_2;
                    2'd3:    state_nxt = BYTE_3;
                    default: state_nxt = BYTE_0;
                endcase
            end

            BYTE_1: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
                    temp_paddle_nxt[10:8] = data_in[2:0];
                    counter_nxt = 2'd2;
                    state_nxt = WAIT;
                end
            end

            BYTE_2: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
                    temp_paddle_nxt[7:0] = data_in;
                    counter_nxt = 2'd3;
                    state_nxt = WAIT;
                end
            end

            BYTE_3: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
                    counter_nxt = 2'd0;

                    if(data_in == 8'hAA) begin
                        paddle_y_nxt = temp_paddle;
                        peer_flag_char_nxt = temp_flag;
                        frame_valid_nxt = 1'b1;
                        state_nxt = WAIT;
                    end
                    else begin
                        // bad terminator, see RESYNC above
                        state_nxt = RESYNC;
                    end
                end
            end

            RESYNC: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1'b1;
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
