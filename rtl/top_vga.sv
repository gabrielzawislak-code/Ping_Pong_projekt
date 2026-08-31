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
 * The project top module. This board (MASTER) is the only one driving a
 * monitor: it runs the whole game (both paddles, the ball and the score)
 * and only receives the up/down button state of the other board over
 * UART - it never transmits anything back.
 */

module top_vga (
        input logic clk_65Mhz,
        input logic rst_n,
        input logic btn_C,
        input logic btn_up,
        input logic btn_down,
        input logic rx_pin,
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
    logic [10:0] paddle1_y, paddle2_y;
    logic ref_time;
    logic ball_ref_time;
    logic [10:0] ball_x, ball_y;
    logic [3:0] score_1, score_2;
    logic [7:0] char_line_score;
    logic [10:0] addr_score;
    logic rd;
    logic [7:0] r_data;
    logic rx_empty;
    logic btn_up_2, btn_down_2;
    logic rx;
    /**
     * Signals assignments
     */

    assign vs = vga_paddle.vsync;
    assign hs = vga_paddle.hsync;
    assign {r,g,b} = vga_paddle.rgb;


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
        .ref_time(ref_time),
        .flag_char(flag_char)
    );


    paddle_pos u_paddle_pos(
        .clk(clk_65Mhz),
        .rst_n,
        .btn_up_1(btn_up),
        .btn_down_1(btn_down),
        .btn_up_2(btn_up_2),
        .btn_down_2(btn_down_2),
        .flag_char(flag_char),
        .ref_time(ref_time),
        .paddle1_y(paddle1_y),
        .paddle2_y(paddle2_y)
    );

    ball_pos u_ball_pos(
        .clk(clk_65Mhz),
        .rst_n,
        .flag_char(flag_char),
        .ref_time(ball_ref_time),
        .paddle_y_1(paddle1_y),
        .paddle_y_2(paddle2_y),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .score_1(score_1),
        .score_2(score_2)
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

    uart u_uart(
        .clk(clk_65Mhz),
        .rst_n,
        .wr_uart(1'b0),
        .w_data(8'h00),
        .rd_uart(rd),
        .rx(rx),
        .r_data(r_data),
        .rx_empty(rx_empty),
        .tx(),
        .tx_full()
    );

    receive_bytes u_receive_bytes(
        .clk(clk_65Mhz),
        .rst_n,
        .data_in(r_data),
        .rx_empty(rx_empty),
        .rd_en(rd),
        .btn_up_2(btn_up_2),
        .btn_down_2(btn_down_2)
    );

    uart_sync u_uart_sync(
        .clk(clk_65Mhz),
        .tx(1'b1),
        .rx(rx_pin),
        .tx_sync(),
        .rx_sync(rx)
    );

endmodule
