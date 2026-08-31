/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Testbench for game_fsm.
 */
module game_fsm_tb;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk, rst_n;
    logic btnC;
    logic [2:0] peer_state;
    logic [3:0] score_1, score_2;
    logic tick;

    wire [2:0] flag_char;

    debounce u_debounce(
        .clk(clk),
        .rst_n(rst_n),
        .sw(btnC),
        .db_level(),
        .db_tick(tick)
    );

    game_fsm u_game_fsm(
    .clk(clk),
    .rst_n(rst_n),
    .btn_C(tick),
    .score_1(score_1),
    .score_2(score_2),
    .peer_state(peer_state),
    .flag_char(flag_char)
    );

    initial begin
        clk = 1'b0;
        forever #15.4 clk = ~clk;
    end

    initial begin
        peer_state = 3'b001;
        score_1 = '0;
        score_2 = '0;
        btnC = 1'b0;
        rst_n = 1'b1;
        #(1000)
        rst_n = 1'b0;
        #(1000)
        rst_n = 1'b1;

        #(10000)

        btnC = 1'b1;
        peer_state = 3'b011;
        wait(tick == 1);
        #(1000)


        $finish;
    end

endmodule
