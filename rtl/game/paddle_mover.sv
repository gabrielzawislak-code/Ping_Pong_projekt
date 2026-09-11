/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Computes the position of ONE, LOCAL paddle from this board's own
 * up/down buttons. Instantiated once per board (the HOST drives paddle1
 * with it, the CLIENT drives paddle2) - the other board's paddle position
 * is never computed here, it always arrives over UART, so there is no
 * risk of the two boards' copies of "the same" paddle ever disagreeing.
 */
module paddle_mover(
    input logic clk,
    input logic rst_n,
    input logic btn_up,
    input logic btn_down,
    input logic [2:0] flag_char,
    input logic ref_time,
    output logic [10:0] paddle_y
);

    localparam bit [3:0] PADDLE_VEL = 4;

    logic [10:0] paddle_y_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            paddle_y <= 334;
        end
        else begin
            paddle_y <= paddle_y_nxt;
        end
    end

    always_comb begin
        paddle_y_nxt = paddle_y;

        if((ref_time == 1'b1) && (flag_char == 3'b011)) begin
            if((btn_up == 1) && (btn_down == 0)) begin
                if(paddle_y < 4) begin
                    paddle_y_nxt = '0;
                end
                else begin
                    paddle_y_nxt = paddle_y - PADDLE_VEL;
                end
            end
            else if((btn_down == 1) && (btn_up == 0)) begin
                if(paddle_y > 748) begin
                    paddle_y_nxt = 752;
                end
                else begin
                    paddle_y_nxt = paddle_y + PADDLE_VEL;
                end
            end
        end
    end

endmodule
