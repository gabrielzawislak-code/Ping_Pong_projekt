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
 * Testbench for top_vga (player_2). This board drives no monitor, so
 * there is nothing to render/capture here - the test just wiggles the
 * up/down buttons and lets the waveform viewer show tx_pin activity.
 */

module top_vga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 15.38;     // 65 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;


    /**
     * Local variables and signals
     */

    logic clk, rst_n;
    logic btn_up, btn_down;
    wire tx_pin;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Submodules instances
     */

    top_vga dut (
        .clk_65Mhz(clk),
        .rst_n(rst_n),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .tx_pin(tx_pin)
    );


    /**
     * Main test
     */

    initial begin
        btn_up = 1'b0;
        btn_down = 1'b0;
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;

        btn_up = 1'b1;

        #1000000;

        $display("Simulation is over, check tx_pin activity in the waveforms.");
        $finish;
    end

endmodule
