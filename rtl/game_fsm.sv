module game_fsm(
    input logic clk,
    input logic rst_n,
    input logic btn_C,
    input logic [3:0] score_1,
    input logic [3:0] score_2,
    input logic rx_info,
    output logic tx_info,
    output logic [2:0] flag_char
);

    enum logic [1:0] {
        ST_START,
        ST_WAIT,
        ST_GAMEPLAY,
        ST_END
    } state, state_nxt;

    logic [2:0] flag_char_nxt;
    logic tx_info_nxt;


    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state <= ST_START;
            flag_char <= 3'b0;
            tx_info <= 1'b0;
        end
        else begin
            state <= state_nxt;
            flag_char <= flag_char_nxt;
            tx_info <= tx_info_nxt;
        end
    end

    always_comb begin
        state_nxt = state;
        flag_char_nxt = 3'b001;
        tx_info_nxt = 1'b0;

        case(state)
            ST_START: begin
                if(btn_C && rx_info) begin
                    state_nxt = ST_GAMEPLAY;
                    flag_char_nxt = 3'b011;
                    tx_info_nxt = 1'b0;
                end
                else if(btn_C && !rx_info) begin
                    state_nxt = ST_WAIT;
                    flag_char_nxt = 3'b010;
                    tx_info_nxt = 1'b1;
                end
                else begin
                    state_nxt = ST_START;
                    flag_char_nxt = 3'b001;
                    tx_info_nxt = 1'b0;
                end
            end

            ST_WAIT: begin
                tx_info_nxt = 1'b0;
                if(rx_info) begin
                    state_nxt = ST_GAMEPLAY;
                    flag_char_nxt = 3'b011;
                end
                else begin
                    state_nxt = ST_WAIT;
                    flag_char_nxt = 3'b010;
                end
            end

            ST_GAMEPLAY: begin
                state_nxt = ST_GAMEPLAY;
                flag_char_nxt = 3'b011;
                tx_info_nxt = 1'b0;

                if(score_1 == 9 || score_2 == 9) begin
                    state_nxt = ST_END;
                    flag_char_nxt = 3'b100;
                end
            end

            ST_END: begin
                state_nxt = ST_END;
                flag_char_nxt = 3'b100;
                tx_info_nxt = 1'b0;
            end

            default: state_nxt = ST_START;
        endcase
    end

endmodule