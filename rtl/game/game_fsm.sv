/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Local game state machine.
 *
 * flag_char encodes what should be shown/done on screen and is also the
 * value broadcast to the other board over UART so it can tell whether we
 * are idle, ready, playing or finished:
 *   3'b001 - IDLE    : "press button D to start" screen
 *   3'b010 - READY   : local player pressed start, waiting for the peer
 *   3'b011 - PLAYING : gameplay running
 *   3'b100 - END     : someone reached the winning score
 */
module game_fsm(
    input logic clk,
    input logic rst_n,
    input logic btn_C,
    input logic [3:0] score_1,
    input logic [3:0] score_2,
    input logic [2:0] peer_state,
    output logic [2:0] flag_char
);

    localparam bit [3:0] WIN_SCORE = 9;

    localparam logic [2:0] FLAG_IDLE    = 3'b001;
    localparam logic [2:0] FLAG_READY   = 3'b010;
    localparam logic [2:0] FLAG_PLAYING = 3'b011;
    localparam logic [2:0] FLAG_END     = 3'b100;

    enum logic [1:0] {
        ST_IDLE,
        ST_READY,
        ST_PLAYING,
        ST_END
    } state, state_nxt;

    logic [2:0] flag_char_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state <= ST_IDLE;
            flag_char <= FLAG_IDLE;
        end
        else begin
            state <= state_nxt;
            flag_char <= flag_char_nxt;
        end
    end

    always_comb begin
        state_nxt = state;
        flag_char_nxt = FLAG_IDLE;

        case(state)
            ST_IDLE: begin
                flag_char_nxt = FLAG_IDLE;

                if(btn_C) begin
                    state_nxt = ST_READY;
                end
            end

            ST_READY: begin
                flag_char_nxt = FLAG_READY;

                if(peer_state != FLAG_IDLE) begin
                    state_nxt = ST_PLAYING;
                end
            end

            ST_PLAYING: begin
                flag_char_nxt = FLAG_PLAYING;

                if((score_1 == WIN_SCORE) || (score_2 == WIN_SCORE)) begin
                    state_nxt = ST_END;
                end
            end

            ST_END: begin
                flag_char_nxt = FLAG_END;
            end

            default: begin
                state_nxt = ST_IDLE;
            end
        endcase
    end

endmodule
