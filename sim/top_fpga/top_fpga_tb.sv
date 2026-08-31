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
 * Testbench for top_fpga (player_2). This board drives no monitor, so
 * there is nothing to render/capture here - the test just wiggles the
 * up/down buttons and lets the waveform viewer show tx_pin activity.
 */

module top_fpga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 10;     // 100 MHz
    localparam RST_START_TIME = 1000;
    localparam RST_ACTIVE_TIME = 2000;


    /**
     * Local variables and signals
     */

    logic clk, rst, btnU, btnD;
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

    top_vga_basys3 dut (
        .clk(clk),
        .btnL(rst),
        .btnU(btnU),
        .btnD(btnD),
        .JXADC(tx_pin),
        .JA1()
    );


    /**
     * Main test
     */

    initial begin
        rst = 1'b0;
        btnU = 1'b0;
        btnD = 1'b0;

        #(RST_START_TIME) rst = 1'b1;
        #(RST_ACTIVE_TIME) rst = 1'b0;

        btnU = 1'b1;

        #1000000;

        btnU = 1'b0;
        btnD = 1'b1;

        #1000000;

        $display("Simulation is over, check tx_pin activity in the waveforms.");
        $finish;
    end

endmodule
