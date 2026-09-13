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
 * peer_flag_char is buffered the same way paddle_y already was: BYTE_0
 * only stashes the header's flag bits into temp_flag, it is not
 * committed to peer_flag_char until BYTE_3 confirms the 0xAA terminator.
 * A bare header-nibble match (data_in[7:4]==4'hB) is weak on its own -
 * about 1 in 16 for a stray/noise byte, which is exactly the kind of
 * thing that can show up on the link before both boards are sending
 * real frames - so committing on the header alone risked the peer
 * looking "ready" before it actually was.
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
    logic [2:0] temp_flag, temp_flag_nxt;
    logic [2:0] peer_flag_char_nxt;
    logic rd_en_nxt;
    logic [1:0] counter, counter_nxt;

    enum logic [2:0] {
        BYTE_0,
        WAIT,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } state, state_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            paddle_y <= 334;
            temp_paddle <= 334;
            temp_flag <= FLAG_IDLE;
            peer_flag_char <= FLAG_IDLE;
            rd_en <= 1'b0;
            counter <= '0;
            state <= BYTE_0;
        end
        else begin
            paddle_y <= paddle_y_nxt;
            temp_paddle <= temp_paddle_nxt;
            temp_flag <= temp_flag_nxt;
            peer_flag_char <= peer_flag_char_nxt;
            rd_en <= rd_en_nxt;
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
                        // Not a header byte - it has still been popped
                        // above, so the next cycle examines a fresh
                        // byte instead of re-checking this same one.
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

                    if(data_in == 8'hAA) begin
                        paddle_y_nxt = temp_paddle;
                        peer_flag_char_nxt = temp_flag;
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
