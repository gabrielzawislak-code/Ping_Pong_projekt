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
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnL,
        input wire btnU,
        input wire btnD,
        output logic [0:0] JXADC,
        output wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire pclk;
    wire tx_pin;
    wire pclk_mirror;
    wire btn_U, btn_D;
    wire clk_locked;
    wire rst_n;

    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;
    assign JXADC[0] = tx_pin;



    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(pclk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    clk_wiz_0 u_clk_wiz_0 (
        .clk,
        .clk_65Mhz(pclk),
        .clk_100Mhz(),
        .locked(clk_locked)
    );

    /**
     *  Project functional top module
     */

    reset_ctrl u_reset_ctrl(
        .clk(pclk),
        .rst_in_n(!btnL && clk_locked),
        .rst_n(rst_n)
    );

    debounce u_debounce_btnU(
        .clk(pclk),
        .rst_n(rst_n),
        .sw(btnU),
        .db_level(btn_U),
        .db_tick()
    );

    debounce u_debounce_btnD(
        .clk(pclk),
        .rst_n(rst_n),
        .sw(btnD),
        .db_level(btn_D),
        .db_tick()
    );

    top_vga u_top_vga (
        .clk_65Mhz(pclk),
        .rst_n(rst_n),
        .btn_up(btn_U),
        .btn_down(btn_D),
        .tx_pin(tx_pin)
    );

endmodule
