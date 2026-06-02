module draw_paddle_ball(
    input logic clk,
    input logic rst_n,
    vga_if.in vga_in,
    vga_if.out vga_out
);

vga_if vga_nxt();

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
        vga_out.hcount <= vga_nxt.hcount;
        vga_out.hblnk <= vga_nxt.hblnk;
        vga_out.hsync <= vga_nxt.hsync;
        vga_out.vcount <= vga_nxt.vcount;
        vga_out.vblnk <= vga_nxt.vblnk;
        vga_out.vsync <= vga_nxt.vsync;
        vga_out.rgb <= vga_nxt.rgb;
    end
end

always_comb begin
    vga_nxt.vcount = vga_in.vcount;
    vga_nxt.vblnk = vga_in.vblnk;
    vga_nxt.vsync = vga_in.vsync;
    vga_nxt.hcount = vga_in.hcount;
    vga_nxt.hblnk = vga_in.hblnk;
    vga_nxt.hsync = vga_in.hsync;
    vga_nxt.rgb = vga_in.rgb;
    
    if((vga_in.hcount >= 30 && vga_in.hcount <= 46 && vga_in.vcount >= 50 && vga_in.vcount <= 150) || (vga_in.hcount >= 978 && vga_in.hcount <= 994 && vga_in.vcount >= 50 && vga_in.vcount <= 150)) begin
        vga_nxt.rgb = 12'h0FF;
    end
    else if(vga_in.hcount >= 300 && vga_in.hcount <= 316 && vga_in.vcount >= 200 && vga_in.vcount <= 216) begin
        vga_nxt.rgb = 12'h BF0;
    end
    else begin
        vga_nxt.rgb = vga_in.rgb;
    end
end

endmodule