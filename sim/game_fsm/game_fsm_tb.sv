/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Smoke test for the symmetric, peer_state-based game_fsm used on both
 * boards: IDLE -> READY (own btn_C) -> PLAYING (once peer_state leaves
 * IDLE) -> END (once a score reaches WIN_SCORE).
 */
module game_fsm_tb;

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [2:0] FLAG_IDLE    = 3'b001;
    localparam logic [2:0] FLAG_READY   = 3'b010;
    localparam logic [2:0] FLAG_PLAYING = 3'b011;
    localparam logic [2:0] FLAG_END     = 3'b100;

    logic clk, rst_n;
    logic btnC;
    logic tick;
    logic [3:0] score_1, score_2;
    logic [2:0] peer_state;

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
        btnC = 1'b0;
        score_1 = '0;
        score_2 = '0;
        peer_state = FLAG_IDLE;
        rst_n = 1'b1;
        #(1000)
        rst_n = 1'b0;
        #(1000)
        rst_n = 1'b1;

        #(10000)

        // Sanity check: still idle before anyone presses start.
        if(flag_char !== FLAG_IDLE) $error("Expected IDLE after reset, got %b", flag_char);

        // Local player presses start - we should move to READY and stay
        // there while the peer is still IDLE.
        btnC = 1'b1;
        wait(tick == 1);
        #(1000)
        btnC = 1'b0;
        #(1000)
        if(flag_char !== FLAG_READY) $error("Expected READY, got %b", flag_char);

        // Peer presses start too - both should move to PLAYING.
        peer_state = FLAG_READY;
        #(1000)
        if(flag_char !== FLAG_PLAYING) $error("Expected PLAYING, got %b", flag_char);

        // Score reaches the winning value - should move to END.
        score_1 = 4'd9;
        #(1000)
        if(flag_char !== FLAG_END) $error("Expected END, got %b", flag_char);

        $display("game_fsm_tb finished");
        $finish;
    end

endmodule
