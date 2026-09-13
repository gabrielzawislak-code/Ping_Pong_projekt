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
 * Top level synthesizable module including the project top and all the
 * FPGA-referred modules. This single bitstream is programmed onto BOTH
 * Basys3 boards; sw_role picks which role each board plays at run time
 * (0 = HOST / Player 1, 1 = CLIENT / Player 2). Both boards always drive
 * their own VGA monitor.
 *
 * UART wiring (same on both boards, cross-connected between them):
 *   JC[0]    (Pmod JC1)    - RX, from the other board's JXADC[0]
 *   JXADC[0] (Pmod XA1_P)  - TX, to the other board's JC[0]
 * The two boards also need a common GND between them for the UART
 * signal levels to be meaningful.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnL,
        input  wire btnC,
        input  wire btnU,
        input  wire btnD,
        input  wire sw_role,      // 0 = HOST / Player 1, 1 = CLIENT / Player 2
        input  wire [4:0] speed_sw,
        input  wire [0:0] JC,     // UART RX <- other board
        output wire [0:0] JXADC,  // UART TX -> other board
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire pclk;
    wire pclk_mirror;
    wire btn_C, btn_U, btn_D;
    wire clk_locked;
    wire rst_n;
    wire tx_pin_local;

    // Role and speed switches are toggled fully asynchronously to pclk -
    // both are double-flopped before touching any synchronous logic, the
    // same pattern already used for speed_sw.
    logic sw_role_meta, sw_role_sync;
    logic [4:0] speed_sw_meta, speed_sw_sync;
    logic [7:0] speed_pct;
    logic is_host;

    always_ff @(posedge pclk, negedge rst_n) begin
        if(!rst_n) begin
            sw_role_meta  <= '0;
            sw_role_sync  <= '0;
            speed_sw_meta <= '0;
            speed_sw_sync <= '0;
        end
        else begin
            sw_role_meta  <= sw_role;
            sw_role_sync  <= sw_role_meta;
            speed_sw_meta <= speed_sw;
            speed_sw_sync <= speed_sw_meta;
        end
    end

    assign is_host = !sw_role_sync;

    assign speed_pct = (speed_sw_sync[0] ? 8'd10 : 8'd0) +
                        (speed_sw_sync[1] ? 8'd20 : 8'd0) +
                        (speed_sw_sync[2] ? 8'd30 : 8'd0) +
                        (speed_sw_sync[3] ? 8'd40 : 8'd0) +
                        (speed_sw_sync[4] ? 8'd50 : 8'd0);

    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;
    assign JXADC[0] = tx_pin_local;

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

    debounce u_debounce_btnC(
        .clk(pclk),
        .rst_n(rst_n),
        .sw(btnC),
        .db_level(),
        .db_tick(btn_C)
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
        .is_host(is_host),
        .btn_C(btn_C),
        .btn_up(btn_U),
        .btn_down(btn_D),
        .rx_pin(JC[0]),
        .tx_pin(tx_pin_local),
        .speed_pct(speed_pct),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
