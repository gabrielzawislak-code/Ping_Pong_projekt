/**
 *  Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for vga_timing module.
 */

module vga_timing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 25;     // 40 MHz
    localparam RST_START_TIME  = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;


    /**
     * Local variables and signals
     */

    logic clk;
    logic rst_n;

    wire [10:0] vcount, hcount;
    wire        vsync,  hsync;
    wire        vblnk,  hblnk;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Reset generation
     */

    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
    end


    /**
     * Dut placement
     */

    vga_timing dut(
        .clk,
        .rst_n,
        .vcount,
        .vsync,
        .vblnk,
        .hcount,
        .hsync,
        .hblnk
    );

    /**
     * Tasks and functions
     */

    // Here you can declare tasks with immediate assertions (assert).


    /**
     * Assertions
     */

    // Here you can declare concurrent assertions (assert property).
/* hcount : max value */
     assert property (
        /* run assertion at each positive clock edge: */
        @(posedge clk)
        /* except during reset (optional): */
        disable iff (!rst_n || $realtime < RST_START_TIME)
        /* check whether this condition is true: */
        hcount < HOR_TOTAL_TIME
    ) else begin
        /* if condition is not true, display error message */
        $error("hcount: max value exceeded");
    end
    
    /* hcount : zero after max value */
    assert property (
        @(posedge clk)
        hcount == (HOR_TOTAL_TIME - 1) |=> hcount == 0
    ) else begin
        $error("hcount: return to 0 after expected max value failed");
    end
    
    /* hcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (hcount < HOR_TOTAL_TIME - 1) |=> (hcount == $past(hcount) + 1)
    ) else begin
        $error("hcount: increment at every clk failed");
    end
    
    /* vcount : max value */
    assert property (
        @(posedge clk)
        disable iff (!rst_n || $realtime < RST_START_TIME)
        vcount < VER_TOTAL_TIME
    ) else begin
        $error("vcount: max value exceeded");
    end
    
    /* vcount : zero after max value */
    assert property (
        @(posedge clk)
        vcount == (VER_TOTAL_TIME - 1) |=> ##(HOR_TOTAL_TIME - 1) vcount == 0
    ) else begin
        $error("vcount: return to 0 after expected max value failed");
    end
    
    /* vcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        (hcount == HOR_TOTAL_TIME - 1) && vcount < (VER_TOTAL_TIME - 1) |=> (vcount == $past(vcount) + 1)
    ) else begin
        $error("vcount: increment at hcount reset failed");
    end
    
    /* hblnk : set */
    assert property (
        @(posedge clk)
        hcount >= HOR_BLNK_START && hcount < HOR_BLNK_START + HOR_BLNK_TIME - 1 |-> hblnk
    ) else begin
        $error("hblnk: set failed");
    end
    
    /* hblnk : clear */
    assert property (
        @(posedge clk)
        hcount < HOR_BLNK_START |-> !hblnk
    ) else begin
        $error("hblnk: clear failed");
    end
    
    /* vblnk : set */
    assert property (
        @(posedge clk)
        vcount >= VER_BLNK_START && vcount < VER_BLNK_START + VER_BLNK_TIME - 1 |-> vblnk
    ) else begin
        $error("vblnk set failed");
    end
    
    /* vblnk : clear */
    assert property (
        @(posedge clk)
        vcount < VER_BLNK_START |-> !vblnk
    ) else begin
        $error("vblnk: clear failed");
    end
    
    /* hsync : set */
    assert property (
        @(posedge clk)
        hcount >= HOR_SYNC_START && hcount < HOR_SYNC_START + HOR_SYNC_TIME - 1 |-> hsync
    ) else begin
        $error("hsync: set failed");
    end
    
    /* hsync : clear */
    assert property (
        @(posedge clk)
        (hcount < HOR_SYNC_START) || (hcount > (HOR_SYNC_START + HOR_SYNC_TIME - 1)) |-> !hsync
    ) else begin
        $error("hsync: clear failed");
    end
    
    /* vsync : set */
    assert property (
        @(posedge clk)
        vcount >= VER_SYNC_START && vcount < VER_SYNC_START + VER_SYNC_TIME - 1 |-> vsync
    ) else begin
        $error("vsync: set failed");
    end
    
    /* vsync : clear */
    assert property (
        @(posedge clk)
        vcount < VER_SYNC_START || vcount > VER_SYNC_START + VER_SYNC_TIME - 1 |-> !vsync
    ) else begin
        $error("vsync: clear failed");
    end

    /**
     * Main test
     */

    
     
     initial begin
        @(negedge rst_n);
        @(posedge rst_n);

        wait (vsync == 1'b0);
        @(negedge vsync);
        @(negedge vsync);

        $finish;
    end

endmodule
