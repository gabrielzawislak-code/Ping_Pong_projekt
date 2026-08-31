/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Draws the on-screen text messages (start/waiting/game-over prompts) by
 * looking up character codes from char_rom and pixel rows from font_rom,
 * compositing them over the incoming vga_in stream.
 */
module draw_char(
    input logic clk,
    input logic rst_n,
    input logic [7:0] char_line_pixels,
    input logic [2:0] flag_char,
    output logic [6:0] char_xy,
    output logic [3:0] char_line,
    vga_if.in vga_in,
    vga_if.out vga_out
);

vga_if vga_sync();
vga_if vga_nxt();

logic [6:0] char_xy_nxt;
logic [3:0] char_line_nxt;
logic [10:0] local_x_low, local_y_low, local_x_high, local_y_high;
logic [2:0] pixel_sub_x;
logic [2:0] flag_char_sync;

localparam int XPOS_LOW = 384;
localparam int YPOS_LOW = 99;
localparam int XPOS_HIGH = 480;
localparam int YPOS_HIGH = 3;

delay #(.WIDTH(26), .CLK_DEL(3)) u_delay(
    .clk(clk),
    .rst_n(rst_n),
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
    char_line <= char_line_nxt;
    char_xy <= char_xy_nxt;
    flag_char_sync <= flag_char;
end

always_comb begin
    vga_nxt.hcount = vga_in.hcount;
    vga_nxt.hblnk = vga_in.hblnk;
    vga_nxt.hsync = vga_in.hsync;
    vga_nxt.vcount = vga_in.vcount;
    vga_nxt.vblnk = vga_in.vblnk;
    vga_nxt.vsync = vga_in.vsync;

    local_x_low = vga_in.hcount - XPOS_LOW;
    local_y_low = vga_in.vcount - YPOS_LOW;
    
    local_x_high = vga_in.hcount - XPOS_HIGH;
    local_y_high = vga_in.vcount - YPOS_HIGH;
    
    case(flag_char_sync)
        3'b001: begin
            char_xy_nxt = {2'b00, local_x_low[7:3]};
            char_line_nxt = local_y_low[3:0];
            pixel_sub_x = vga_sync.hcount[2:0] - XPOS_LOW;

            if((vga_sync.hcount >= XPOS_LOW) && (vga_sync.hcount < 256 + XPOS_LOW) && (vga_sync.vcount >= YPOS_LOW) && (vga_sync.vcount < 16 + YPOS_LOW)) begin
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
        
        3'b010: begin
            char_xy_nxt = {2'b01, local_x_low[7:3]};
            char_line_nxt = local_y_low[3:0];
            pixel_sub_x = vga_sync.hcount[2:0] - XPOS_LOW;

            if((vga_sync.hcount >= XPOS_LOW) && (vga_sync.hcount < 256 + XPOS_LOW) && (vga_sync.vcount >= YPOS_LOW) && (vga_sync.vcount < 16 + YPOS_LOW)) begin
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

        3'b100: begin
            char_xy_nxt = {4'b1001, local_x_high[5:3]};
            char_line_nxt = local_y_low[3:0];
            pixel_sub_x = vga_sync.hcount - XPOS_LOW;


            if((vga_sync.hcount >= XPOS_HIGH) && (vga_sync.hcount < (XPOS_HIGH + 64)) && (vga_sync.vcount >= YPOS_LOW) && (vga_sync.vcount < YPOS_LOW + 16)) begin
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
                
        default: begin
            char_xy_nxt = {4'b1000, local_x_high[5:3]};
            char_line_nxt = local_y_high[3:0];
            pixel_sub_x = vga_sync.hcount - XPOS_HIGH;

            if((vga_sync.hcount >= XPOS_HIGH) && (vga_sync.hcount < XPOS_HIGH + 64) && (vga_sync.vcount >= YPOS_HIGH) && (vga_sync.vcount < YPOS_HIGH + 16)) begin
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
    endcase
end

endmodule