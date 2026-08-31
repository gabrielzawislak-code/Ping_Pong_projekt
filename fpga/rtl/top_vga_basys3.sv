/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnL,
        input  wire btnC,
        input wire btnU,
        input wire btnD,
        input wire [0:0] JC,
        input wire [4:0] speed_sw,
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

    // Speed switches (SW15..SW11) - synchronized since they are toggled
    // fully asynchronously to pclk, then summed into a single 0..150
    // percent ball-speed boost (each switch is worth a fixed +10..+50%).
    logic [4:0] speed_sw_meta, speed_sw_sync;
    logic [7:0] speed_pct;

    always_ff @(posedge pclk, negedge rst_n) begin
        if(!rst_n) begin
            speed_sw_meta <= '0;
            speed_sw_sync <= '0;
        end
        else begin
            speed_sw_meta <= speed_sw;
            speed_sw_sync <= speed_sw_meta;
        end
    end

    assign speed_pct = (speed_sw_sync[0] ? 8'd10 : 8'd0) +
                        (speed_sw_sync[1] ? 8'd20 : 8'd0) +
                        (speed_sw_sync[2] ? 8'd30 : 8'd0) +
                        (speed_sw_sync[3] ? 8'd40 : 8'd0) +
                        (speed_sw_sync[4] ? 8'd50 : 8'd0);

    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;

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
        .btn_C(btn_C),
        .btn_up(btn_U),
        .btn_down(btn_D),
        .rx_pin(JC[0]),
        .speed_pct(speed_pct),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
