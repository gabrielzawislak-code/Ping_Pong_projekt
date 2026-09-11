/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Draws the two-digit score counters for both players by looking up ASCII
 * character rows from font_rom and compositing them over the incoming
 * vga_in stream.
 */
module draw_score(
    input logic clk,
    input logic rst_n,
    input logic [3:0] score_1,
    input logic [3:0] score_2,
    input logic [7:0] char_line_pixels,
    output logic [10:0] addr,
    vga_if.in vga_in,
    vga_if.out vga_out
);

    localparam int YPOS = 20;
    localparam int XPOS_LEFT = 492;
    localparam int XPOS_RIGHT = 516;

    vga_if vga_sync();
    vga_if vga_nxt();

    logic [10:0] addr_nxt;
    logic [6:0] score_1_ascii, score_2_ascii;
    logic [10:0] local_y;
    logic [2:0] pixel_sub_x;

    delay #(.WIDTH(26), .CLK_DEL(2)) u_delay(
        .clk,
        .rst_n,
        .din({vga_nxt.hcount, vga_nxt.hblnk, vga_nxt.hsync, vga_nxt.vcount, vga_nxt.vblnk, vga_nxt.vsync}),
        .dout({vga_sync.hcount, vga_sync.hblnk, vga_sync.hsync, vga_sync.vcount, vga_sync.vblnk, vga_sync.vsync})
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            vga_out.hcount <= '0;
            vga_out.hblnk <= '0;
            vga_out.hsync <= '0;
            vga_out.vcount <= '0;
            vga_out.vblnk <= '0;
            vga_out.vsync <= '0;
            vga_out.rgb <= '0;
        end
        else begin
            vga_out.hcount <= vga_sync.hcount;
            vga_out.hblnk <= vga_sync.hblnk;
            vga_out.hsync <= vga_sync.hsync;
            vga_out.vcount <= vga_sync.vcount;
            vga_out.vblnk <= vga_sync.vblnk;
            vga_out.vsync <= vga_sync.vsync;
            vga_out.rgb <= vga_sync.rgb;
        end
    end

    always_ff @(posedge clk) begin
        addr <= addr_nxt;
    end
    
    assign score_1_ascii = score_1 + 8'h30;
    assign score_2_ascii = score_2 + 8'h30;

    
    always_comb begin
        vga_nxt.hcount = vga_in.hcount;
        vga_nxt.hblnk = vga_in.hblnk;
        vga_nxt.hsync = vga_in.hsync;
        vga_nxt.vcount = vga_in.vcount;
        vga_nxt.vblnk = vga_in.vblnk;
        vga_nxt.vsync = vga_in.vsync;
        
    
        local_y = vga_in.vcount - YPOS;
        addr_nxt = '0;
        
        
        if(vga_in.hcount >= XPOS_LEFT && vga_in.hcount <= (XPOS_LEFT + 7) && vga_in.vcount >= YPOS && vga_in.vcount <= (YPOS + 16)) begin
            addr_nxt = {score_1_ascii, local_y[3:0]};
        end
        else if(vga_in.hcount >= XPOS_RIGHT && vga_in.hcount <= (XPOS_RIGHT + 7) && vga_in.vcount >= YPOS && vga_in.vcount <= (YPOS + 16)) begin
            addr_nxt = {score_2_ascii, local_y[3:0]};
        end


        if(vga_sync.hcount >= XPOS_LEFT && vga_sync.hcount <= (XPOS_LEFT + 7) && vga_sync.vcount >= YPOS && vga_sync.vcount <= (YPOS + 16)) begin
            pixel_sub_x = vga_sync.hcount - XPOS_LEFT;

            if(char_line_pixels[3'd7 - pixel_sub_x]) begin
                vga_sync.rgb = 12'h48B;
            end
            else begin
                vga_sync.rgb = vga_in.rgb;
            end
        end
        
        else if(vga_sync.hcount >= XPOS_RIGHT && vga_sync.hcount <= (XPOS_RIGHT + 7) && vga_sync.vcount >= YPOS && vga_sync.vcount <= (YPOS + 16)) begin
            pixel_sub_x = vga_sync.hcount - XPOS_RIGHT;

            if(char_line_pixels[3'd7 - pixel_sub_x]) begin
                vga_sync.rgb = 12'h48B;
            end
            else begin
                vga_sync.rgb = vga_in.rgb;
            end
        end
        
        else begin
            vga_sync.rgb = vga_in.rgb;
        end
    end

endmodule