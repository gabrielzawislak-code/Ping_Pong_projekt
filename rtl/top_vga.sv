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
    vga_if vga_paddle();


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

    draw_paddle_ball u_draw_paddle_ball (
        .clk,
        .rst_n,
        .vga_in(vga_bg),
        .vga_out(vga_paddle)
    );

endmodule
