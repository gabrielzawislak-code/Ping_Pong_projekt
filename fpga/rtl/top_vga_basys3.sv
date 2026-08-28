/**
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnL,
        input  wire btnC,
        input wire btnU,
        input wire btnD,
        input wire [1:1] JA,
        output wire [0:0] JB, 
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
    wire tx_pin;
    wire pclk_mirror;
    wire btn_C, btn_U, btn_D;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    logic [7:0] safe_start = 0;
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;

    assign JB[0] = tx_pin;

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
        .locked()
    );

    /**
     *  Project functional top module
     */

    debounce u_debounce_btnC(
        .clk(pclk),
        .rst_n(!btnL),
        .sw(btnC),
        .db_level(),
        .db_tick(btn_C)
    );

    debounce u_debounce_btnU(
        .clk(pclk),
        .rst_n(!btnL),
        .sw(btnU),
        .db_level(btn_U),
        .db_tick()
    );

    debounce u_debounce_btnD(
        .clk(pclk),
        .rst_n(!btnL),
        .sw(btnD),
        .db_level(btn_D),
        .db_tick()
    );
    
    top_vga u_top_vga (
        .clk_65Mhz(pclk),
        .rst_n(!btnL),
        .btn_C(btn_C),
        .btn_up(btn_U),
        .btn_down(btn_D),
        .tx_pin(tx_pin),
        .rx_pin(JA[1]),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
