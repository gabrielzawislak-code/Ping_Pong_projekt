/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Computes both paddles' positions. Paddle 1 moves from this board's own
 * buttons, paddle 2 moves from the up/down button levels forwarded by the
 * other board over UART - both are driven by the exact same movement
 * logic and the same ref_time tick, so they move at an identical rate.
 */
module paddle_pos(
    input logic clk,
    input logic rst_n,
    input logic btn_up_1,
    input logic btn_down_1,
    input logic btn_up_2,
    input logic btn_down_2,
    input logic [2:0] flag_char,
    input logic ref_time,
    output logic [10:0] paddle1_y,
    output logic [10:0] paddle2_y
);

localparam bit [3:0] PADDLE_VEL = 4;

logic [10:0] paddle1_y_nxt, paddle2_y_nxt;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        paddle1_y <= 334;
        paddle2_y <= 334;
    end
    else begin
        paddle1_y <= paddle1_y_nxt;
        paddle2_y <= paddle2_y_nxt;
    end
end

always_comb begin
    paddle1_y_nxt = paddle1_y;
    paddle2_y_nxt = paddle2_y;

    if((ref_time == 1'b1) && (flag_char == 3'b011)) begin
        if((btn_up_1 == 1) && (btn_down_1 == 0)) begin
            if(paddle1_y < 4) begin
                paddle1_y_nxt = '0;
            end
            else begin
                paddle1_y_nxt = paddle1_y - PADDLE_VEL;
            end
        end
        else if((btn_down_1 == 1) && (btn_up_1 == 0)) begin
            if(paddle1_y > 748) begin
                paddle1_y_nxt = 752;
            end
            else begin
                paddle1_y_nxt = paddle1_y + PADDLE_VEL;
            end
        end

        if((btn_up_2 == 1) && (btn_down_2 == 0)) begin
            if(paddle2_y < 4) begin
                paddle2_y_nxt = '0;
            end
            else begin
                paddle2_y_nxt = paddle2_y - PADDLE_VEL;
            end
        end
        else if((btn_down_2 == 1) && (btn_up_2 == 0)) begin
            if(paddle2_y > 748) begin
                paddle2_y_nxt = 752;
            end
            else begin
                paddle2_y_nxt = paddle2_y + PADDLE_VEL;
            end
        end
    end
end

endmodule
