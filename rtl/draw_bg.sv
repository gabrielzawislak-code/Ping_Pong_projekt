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

        input  logic [10:0] vcount_in,
        input  logic        vsync_in,
        input  logic        vblnk_in,
        input  logic [10:0] hcount_in,
        input  logic        hsync_in,
        input  logic        hblnk_in,

        output logic [10:0] vcount_out,
        output logic        vsync_out,
        output logic        vblnk_out,
        output logic [10:0] hcount_out,
        output logic        hsync_out,
        output logic        hblnk_out,

        output logic [11:0] rgb_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    logic [11:0] rgb_nxt;


    /**
     * Internal logic
     */

    always_ff @(posedge clk) begin : bg_ff_blk
        if (!rst_n) begin
            vcount_out <= '0;
            vsync_out  <= '0;
            vblnk_out  <= '0;
            hcount_out <= '0;
            hsync_out  <= '0;
            hblnk_out  <= '0;
            rgb_out    <= '0;
        end else begin
            vcount_out <= vcount_in;
            vsync_out  <= vsync_in;
            vblnk_out  <= vblnk_in;
            hcount_out <= hcount_in;
            hsync_out  <= hsync_in;
            hblnk_out  <= hblnk_in;
            rgb_out    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        if (vblnk_in || hblnk_in) begin             // Blanking region:
            rgb_nxt = 12'h0_0_0;                    // - make it it black.
        end else begin                              // Active region:
            if (vcount_in == 0)                     // - top edge:
                rgb_nxt = 12'hf_f_0;                // - - make a yellow line.
            else if (vcount_in == VER_PIXELS - 1)   // - bottom edge:
                rgb_nxt = 12'hf_0_0;                // - - make a red line.
            else if (hcount_in == 0)                // - left edge:
                rgb_nxt = 12'h0_f_0;                // - - make a green line.
            else if (hcount_in == HOR_PIXELS - 1)   // - right edge:
                rgb_nxt = 12'h0_0_f;                // - - make a blue line.

            else if (((hcount_in <= 120) && ((((hcount_in - 100) ** 2) + ((vcount_in - 250) ** 2) >= 5000) && (((hcount_in - 100) ** 2) + ((vcount_in - 250) ** 2) <= 6000))) || (((hcount_in >= 100) && (vcount_in >=250) && ((((hcount_in - 100) ** 2) + ((vcount_in - 250) ** 2) >= 5000) && (((hcount_in - 100) ** 2) + ((vcount_in - 250) ** 2) <= 6000)))) || ((vcount_in >= 245) && (vcount_in <=255) && (hcount_in >= 160) && (hcount_in <= 200)))
                rgb_nxt = 12'h0_f_0;
            
            else if (((vcount_in >= 200 && vcount_in <= 210) && (hcount_in >= 220 && hcount_in <= 300)) || 
            ((vcount_in >= 290 && vcount_in <= 300) && (hcount_in >= 220 && hcount_in <= 300)) ||
            ((hcount_in + vcount_in >= 510 && hcount_in + vcount_in <= 525) && (hcount_in >= 220 && hcount_in <= 300))) 
                rgb_nxt = 12'hf_0_0;
            
            /*else if (((hcount_in >= 493) && (hcount_in <= 500) && (vcount_in >= 172) && (vcount_in <= 330)) || ((vcount_in <= (-3 * hcount_in) - 1053) && (vcount_in >= (-3 * hcount_in) - 1065) && (vcount_in >= 172) && (vcount_in <= 330)) || (vcount_in >= ((-3 * hcount_in) + 1712)) && (vcount_in <= (-3 * hcount_in) + 1727) && (hcount_in >= 560) && (hcount_in <= 624) || (hcount_in >= 624) && (hcount_in <= 630) && (vcount_in >= 172) && (vcount_in <= 330)) 
                rgb_nxt = 12'h0_0_f;
            
            else if ((hcount_in >= 650) && (hcount_in <= 780) && (vcount_in >= 172) && (vcount_in <= 180) || (vcount_in <= (-1.215 * hcount_in) + 1120) && (vcount_in >= (-1.215 * hcount_in) + 1110) && (hcount_in >= 650) && (hcount_in <= 780) || (vcount_in >= 330) && (vcount_in <= 335) && (hcount_in >= 650) && (hcount_in <= 780))
                rgb_nxt = 12'hf_f_0; */
             
            else 
                rgb_nxt =  12'h8_8_8;                         // The rest of active display pixels:
            
        end
    end

endmodule