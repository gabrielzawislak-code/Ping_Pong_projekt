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
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic rst_n,
        input logic btn_D,
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
    vga_if vga_char();

    logic [6:0] char_xy;
    logic [6:0] char_code;
    logic [3:0] char_line;
    logic [7:0] char_line_pixels;
    logic [1:0] flag_char;
    /**
     * Signals assignments
     */

    assign vs = vga_char.vsync;
    assign hs = vga_char.hsync;
    assign {r,g,b} = vga_char.rgb;


    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vcount (vga_time.vcount),
        .vsync  (vga_time.vsync),
        .vblnk  (vga_time.vblnk),
        .hcount (vga_time.hcount),
        .hsync  (vga_time.hsync),
        .hblnk  (vga_time.hblnk)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .vga_in(vga_time),
        .vga_out(vga_bg)
    );

    game_fsm u_game_fsm(
        .clk,
        .rst_n,
        .btn_D(btn_D),
        .flag_char(flag_char),
        .rx_info(1'b1),
        .tx_info()
    );
    
    draw_char u_draw_char(
        .clk,
        .rst_n,
        .vga_in(vga_bg),
        .flag_char(flag_char),
        .char_line_pixels(char_line_pixels),
        .char_xy(char_xy),
        .char_line(char_line),
        .vga_out(vga_char)
    );

    char_rom u_char_rom(
        .clk,
        .char_xy(char_xy),
        .char_code(char_code)
    );
    
    font_rom u_font_rom(
        .clk,
        .addr({char_code, char_line}),
        .char_line_pixels(char_line_pixels)
    );
    
    /*draw_paddle_ball u_draw_paddle_ball (
        .clk,
        .rst_n,
        .vga_in(vga_bg),
        .vga_out(vga_paddle)
    );*/

endmodule
