/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Modified by:
 * Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * The project top module - identical on both boards. Each board drives
 * its own monitor and runs its own copy of the game: it always computes
 * its own paddle locally (paddle_mover) and always keeps a local
 * game_fsm in sync with the peer's over UART. The is_host input (from a
 * board switch, see top_vga_basys3.sv) selects which board is
 * authoritative for the ball physics and the score:
 *   - HOST (is_host=1, Player 1): ball_pos's output is used, and the
 *     full game state is broadcast to the peer every tick
 *     (send_state_frame / receive_paddle_frame).
 *   - CLIENT (is_host=0, Player 2): the ball, score and Player 1's
 *     paddle are mirrored from the HOST's frame instead
 *     (receive_state_frame / send_paddle_frame).
 * ball_pos itself is instantiated unconditionally on both boards (it is
 * tiny) - only its result is muxed away on the CLIENT, so nothing here
 * depends on a runtime-conditional instantiation, which SystemVerilog
 * cannot express anyway.
 */

module top_vga (
        input logic clk_65Mhz,
        input logic rst_n,
        input logic is_host,     // 1 = HOST / Player 1 (owns ball physics), 0 = CLIENT / Player 2
        input logic btn_C,
        input logic btn_up,
        input logic btn_down,
        input logic rx_pin,
        output logic tx_pin,
        input logic [7:0] speed_pct,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    vga_if vga_time();
    vga_if vga_bg();
    vga_if vga_hud();
    vga_if vga_char();
    vga_if vga_paddle();
    vga_if vga_score();

    logic [6:0] char_xy;
    logic [6:0] char_code;
    logic [3:0] char_line;
    logic [7:0] char_line_pixels;
    logic [7:0] char_line_hud;
    logic [10:0] addr_hud;
    logic [2:0] flag_char;
    logic [10:0] paddle_own_y, paddle1_y, paddle2_y;
    logic ref_time;
    logic ball_ref_time;
    logic [10:0] ball_x_local, ball_y_local, ball_x, ball_y;
    logic [3:0] score_1_local, score_2_local, score_1, score_2;
    logic [7:0] char_line_score;
    logic [10:0] addr_score;
    logic rd_uart;
    logic [7:0] r_data;
    logic rx_empty, tx_full;
    logic rx, tx;

    // Data received from the peer board
    logic [10:0] paddle1_rx, paddle2_rx, ball_x_rx, ball_y_rx;
    logic [3:0]  score_1_rx, score_2_rx;
    logic [2:0]  host_flag_rx;
    logic [10:0] paddle_peer_rx;
    logic [2:0]  client_flag_rx;
    logic        rd_en_state, rd_en_paddle;

    logic [2:0] peer_state;

    /**
     * Signals assignments
     */

    assign vs = vga_paddle.vsync;
    assign hs = vga_paddle.hsync;
    assign {r,g,b} = vga_paddle.rgb;

    // Final, role-muxed game state fed to the renderer and to ball_pos.
    // HOST: everything local. CLIENT: everything mirrored from the
    // HOST's frame, except its own paddle (paddle_own_y), which is
    // always computed locally for zero-latency response.
    assign peer_state = is_host ? client_flag_rx : host_flag_rx;
    assign paddle1_y  = is_host ? paddle_own_y   : paddle1_rx;
    assign paddle2_y  = is_host ? paddle_peer_rx : paddle_own_y;
    assign ball_x     = is_host ? ball_x_local   : ball_x_rx;
    assign ball_y     = is_host ? ball_y_local   : ball_y_rx;
    assign score_1    = is_host ? score_1_local  : score_1_rx;
    assign score_2    = is_host ? score_2_local  : score_2_rx;


    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk(clk_65Mhz),
        .rst_n,
        .vcount (vga_time.vcount),
        .vsync  (vga_time.vsync),
        .vblnk  (vga_time.vblnk),
        .hcount (vga_time.hcount),
        .hsync  (vga_time.hsync),
        .hblnk  (vga_time.hblnk)
    );

    draw_bg u_draw_bg (
        .clk(clk_65Mhz),
        .rst_n,
        .vga_in(vga_time),
        .vga_out(vga_bg)
    );

    draw_hud u_draw_hud(
        .clk(clk_65Mhz),
        .rst_n,
        .speed_pct(speed_pct),
        .char_line_pixels(char_line_hud),
        .addr(addr_hud),
        .vga_in(vga_bg),
        .vga_out(vga_hud)
    );

    font_rom u_font_rom_hud(
        .clk(clk_65Mhz),
        .addr(addr_hud),
        .char_line_pixels(char_line_hud)
    );

    ball_speed_ctrl u_ball_speed_ctrl(
        .clk(clk_65Mhz),
        .rst_n,
        .flag_char(flag_char),
        .speed_pct(speed_pct),
        .ball_ref_time(ball_ref_time)
    );

    game_fsm u_game_fsm(
        .clk(clk_65Mhz),
        .rst_n,
        .btn_C(btn_C),
        .score_1(score_1),
        .score_2(score_2),
        .peer_state(peer_state),
        .flag_char(flag_char)
    );

    draw_char u_draw_char(
        .clk(clk_65Mhz),
        .rst_n,
        .vga_in(vga_hud),
        .flag_char(flag_char),
        .char_line_pixels(char_line_pixels),
        .char_xy(char_xy),
        .char_line(char_line),
        .vga_out(vga_char)
    );

    char_rom u_char_rom(
        .clk(clk_65Mhz),
        .char_xy(char_xy),
        .char_code(char_code)
    );

    font_rom u_font_rom_char(
        .clk(clk_65Mhz),
        .addr({char_code, char_line}),
        .char_line_pixels(char_line_pixels)
    );

    counter_refresh_time u_counter_refresh_time(
        .clk(clk_65Mhz),
        .rst_n,
        .ref_time(ref_time)
    );


    paddle_mover u_paddle_mover(
        .clk(clk_65Mhz),
        .rst_n,
        .btn_up(btn_up),
        .btn_down(btn_down),
        .flag_char(flag_char),
        .ref_time(ref_time),
        .paddle_y(paddle_own_y)
    );

    // Always instantiated; only used downstream when is_host=1.
    ball_pos u_ball_pos(
        .clk(clk_65Mhz),
        .rst_n,
        .flag_char(flag_char),
        .ref_time(ball_ref_time),
        .paddle_y_1(paddle1_y),
        .paddle_y_2(paddle2_y),
        .ball_x(ball_x_local),
        .ball_y(ball_y_local),
        .score_1(score_1_local),
        .score_2(score_2_local)
    );

    draw_score u_draw_score(
        .clk(clk_65Mhz),
        .rst_n,
        .score_1(score_1),
        .score_2(score_2),
        .char_line_pixels(char_line_score),
        .addr(addr_score),
        .vga_in(vga_char),
        .vga_out(vga_score)
    );

    font_rom u_font_rom_score(
        .clk(clk_65Mhz),
        .addr(addr_score),
        .char_line_pixels(char_line_score)
    );

    draw_paddle_ball u_draw_paddle_ball (
        .clk(clk_65Mhz),
        .rst_n,
        .paddle1_y(paddle1_y),
        .paddle2_y(paddle2_y),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .vga_in(vga_score),
        .vga_out(vga_paddle)
    );

    /**
     * UART TX mux: only the frame encoder matching our own role actually
     * drives the shared FIFO. The other encoder is told the FIFO is
     * always full, so it simply stalls instead of running its state
     * machine against writes that never happen.
     */
    logic wr_en_state, wr_en_paddle;
    logic [7:0] data_state, data_paddle;
    logic wr_uart;
    logic [7:0] w_data;

    assign wr_uart = is_host ? wr_en_state : wr_en_paddle;
    assign w_data  = is_host ? data_state  : data_paddle;

    send_state_frame u_send_state_frame(
        .clk(clk_65Mhz),
        .rst_n,
        .flag_char(flag_char),
        .ref_time(ref_time),
        .tx_full(is_host ? tx_full : 1'b1),
        .paddle_1_y(paddle1_y),
        .paddle_2_y(paddle2_y),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .score_1(score_1),
        .score_2(score_2),
        .data_out(data_state),
        .wr_en(wr_en_state)
    );

    send_paddle_frame u_send_paddle_frame(
        .clk(clk_65Mhz),
        .rst_n,
        .flag_char(flag_char),
        .ref_time(ref_time),
        .tx_full(is_host ? 1'b1 : tx_full),
        .paddle_y(paddle_own_y),
        .data_out(data_paddle),
        .wr_en(wr_en_paddle)
    );

    /**
     * UART RX mux: the decoder NOT matching our own role is told the
     * FIFO is always empty, so it never asserts rd_en and never
     * consumes a byte meant for the other decoder.
     */
    assign rd_uart = is_host ? rd_en_paddle : rd_en_state;

    receive_state_frame u_receive_state_frame(
        .clk(clk_65Mhz),
        .rst_n,
        .data_in(r_data),
        .rx_empty(is_host ? 1'b1 : rx_empty),
        .rd_en(rd_en_state),
        .paddle_1_y(paddle1_rx),
        .paddle_2_y(paddle2_rx),
        .ball_x(ball_x_rx),
        .ball_y(ball_y_rx),
        .score_1(score_1_rx),
        .score_2(score_2_rx),
        .flag_char(host_flag_rx)
    );

    receive_paddle_frame u_receive_paddle_frame(
        .clk(clk_65Mhz),
        .rst_n,
        .data_in(r_data),
        .rx_empty(is_host ? rx_empty : 1'b1),
        .rd_en(rd_en_paddle),
        .paddle_y(paddle_peer_rx),
        .peer_flag_char(client_flag_rx)
    );

    uart u_uart(
        .clk(clk_65Mhz),
        .rst_n,
        .wr_uart(wr_uart),
        .w_data(w_data),
        .rd_uart(rd_uart),
        .rx(rx),
        .r_data(r_data),
        .rx_empty(rx_empty),
        .tx(tx),
        .tx_full(tx_full)
    );

    uart_sync u_uart_sync(
        .clk(clk_65Mhz),
        .tx(1'b1),      // this synchronizer channel is unused here
        .rx(rx_pin),
        .tx_sync(),
        .rx_sync(rx)
    );

    // tx originates in our own clock domain already - no need to
    // synchronize it before driving the physical output pin.
    assign tx_pin = tx;

endmodule
