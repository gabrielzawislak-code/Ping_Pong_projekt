/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * CLIENT -> HOST frame. Periodically (every ref_time tick) sends this
 * board's own, locally computed paddle position and its local game_fsm
 * state - the only two things the HOST cannot derive by itself. Every
 * write is gated on tx_full, same convention as send_state_frame.
 *
 * Frame layout: [header][paddle_y hi][paddle_y lo][0xAA]
 * header = {4'hB, flag_char[2:0]} -> 0xB1 IDLE, 0xB2 READY, 0xB3 PLAYING, 0xB4 END
 */
module send_paddle_frame(
    input logic clk,
    input logic rst_n,
    input logic [2:0] flag_char,
    input logic ref_time,
    input logic tx_full,
    input logic [10:0] paddle_y,
    output logic [7:0] data_out,
    output logic wr_en
);

    enum logic [2:0] {
        BYTE_0,
        WAIT,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } state, state_nxt;

    logic wr_en_nxt;
    logic [7:0] data_out_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_out <= '0;
            wr_en <= '0;
            state <= BYTE_0;
        end
        else begin
            data_out <= data_out_nxt;
            state <= state_nxt;
            wr_en <= wr_en_nxt;
        end
    end

    always_comb begin
        data_out_nxt = data_out;
        wr_en_nxt = '0;
        state_nxt = state;

        case(state)
            BYTE_0: begin
                if(!tx_full) begin
                    if(flag_char == 3'b001) begin
                        data_out_nxt = 8'hB1;
                    end
                    else if(flag_char == 3'b010) begin
                        data_out_nxt = 8'hB2;
                    end
                    else if(flag_char == 3'b011) begin
                        data_out_nxt = 8'hB3;
                    end
                    else begin
                        data_out_nxt = 8'hB4;
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
                    data_out_nxt = {5'b0, paddle_y[10:8]};
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_2;
                end
            end

            BYTE_2: begin
                if(!tx_full) begin
                    data_out_nxt = paddle_y[7:0];
                    wr_en_nxt = 1'b1;
                    state_nxt = BYTE_3;
                end
            end

            BYTE_3: begin
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
