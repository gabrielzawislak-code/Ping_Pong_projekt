/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_bg (
        input  logic clk,
        input  logic rst_n,
        vga_if.in vga_in,
        vga_if.out vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */
   
    vga_if vga_nxt();

    /**
     * Internal logic
     */

    always_ff @(posedge clk) begin : bg_ff_blk
        if (!rst_n) begin
            vga_out.vcount <= '0;
            vga_out.vblnk <= '0;
            vga_out.vsync <= '0;
            vga_out.hcount <= '0;
            vga_out.hblnk <= '0;
            vga_out.hsync <= '0;
            vga_out.rgb <= '0;
        end else begin
            vga_out.vcount <= vga_nxt.vcount;
            vga_out.vblnk <= vga_nxt.vblnk;
            vga_out.vsync <= vga_nxt.vsync;
            vga_out.hcount <= vga_nxt.hcount;
            vga_out.hblnk <= vga_nxt.hblnk;
            vga_out.hsync <= vga_nxt.hsync;
            vga_out.rgb <= vga_nxt.rgb;
        end
    end

    always_comb begin : bg_comb_blk
        vga_nxt.vcount = vga_in.vcount;
        vga_nxt.vblnk = vga_in.vblnk;
        vga_nxt.vsync = vga_in.vsync;
        vga_nxt.hcount = vga_in.hcount;
        vga_nxt.hblnk = vga_in.hblnk;
        vga_nxt.hsync = vga_in.hsync;
        vga_nxt.rgb = vga_in.rgb;
        
        if (vga_in.vblnk || vga_in.hblnk) begin             // Blanking region:
            vga_nxt.rgb= 12'h0_0_0;                    // - make it it black.
        
        end else begin                              // Active region:
            if(vga_in.hcount >= 507 && vga_in.hcount <= 517 && vga_in.vcount[4]) begin
                vga_nxt.rgb= 12'hF_F_F;
            end
            else if(&vga_in.hcount[3:0] && &vga_in.vcount[4:0]) begin
                vga_nxt.rgb= 12'h5_5_5;
            end
             
            else begin
                vga_nxt.rgb= 12'h0_0_1; 
            end                 
            
        end
    end

endmodule