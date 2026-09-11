/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Draws a small "speed: +XXX%" readout, in yellow, just under the top
 * playfield border, reflecting the live ball-speed boost selected on the
 * speed switches (see top_vga_basys3.sv). speed_pct is always a multiple
 * of 10 in 0..150, so the last digit is always '0' and only the hundreds/
 * tens digits ever need computing.
 */
module draw_hud(
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] speed_pct,
    input  logic [7:0] char_line_pixels,
    output logic [10:0] addr,
    vga_if.in vga_in,
    vga_if.out vga_out
);

    localparam int YPOS = 20;
    localparam int XPOS = 144; // must stay a multiple of 8 - pixel_sub_x below relies on it
    localparam int N_CHARS = 12; // "speed: +XXX%"

    localparam logic [6:0] CH_HUNDRED_ZERO = 7'h30; // '0'
    localparam logic [6:0] CH_HUNDRED_ONE  = 7'h31; // '1'

    vga_if vga_sync();
    vga_if vga_nxt();

    logic [10:0] addr_nxt;
    logic [10:0] local_y;
    logic [3:0]  char_idx;
    logic [2:0]  pixel_sub_x;
    logic [6:0]  hundreds_char, tens_char;

    // speed_pct is always a multiple of 10, 0..150 - hundreds digit is 1
    // only for 100..150, tens digit is the remainder (0..90) divided by 10.
    assign hundreds_char = (speed_pct >= 8'd100) ? CH_HUNDRED_ONE : CH_HUNDRED_ZERO;

    always_comb begin
        case(speed_pct >= 8'd100 ? (speed_pct - 8'd100) : speed_pct)
            8'd0:  tens_char = 7'h30;
            8'd10: tens_char = 7'h31;
            8'd20: tens_char = 7'h32;
            8'd30: tens_char = 7'h33;
            8'd40: tens_char = 7'h34;
            8'd50: tens_char = 7'h35;
            8'd60: tens_char = 7'h36;
            8'd70: tens_char = 7'h37;
            8'd80: tens_char = 7'h38;
            8'd90: tens_char = 7'h39;
            default: tens_char = 7'h30;
        endcase
    end

    logic [6:0] char_code;

    always_comb begin
        case(char_idx)
            4'd0:  char_code = 7'h73; // s
            4'd1:  char_code = 7'h70; // p
            4'd2:  char_code = 7'h65; // e
            4'd3:  char_code = 7'h65; // e
            4'd4:  char_code = 7'h64; // d
            4'd5:  char_code = 7'h3a; // :
            4'd6:  char_code = 7'h20; // (space)
            4'd7:  char_code = 7'h2b; // +
            4'd8:  char_code = hundreds_char;
            4'd9:  char_code = tens_char;
            4'd10: char_code = 7'h30; // 0 (last digit is always 0)
            4'd11: char_code = 7'h25; // %
            default: char_code = 7'h20;
        endcase
    end

    delay #(.WIDTH(26), .CLK_DEL(2)) u_delay(
        .clk,
        .rst_n,
        .din({vga_nxt.hcount, vga_nxt.hblnk, vga_nxt.hsync, vga_nxt.vcount, vga_nxt.vblnk, vga_nxt.vsync}),
        .dout({vga_sync.hcount, vga_sync.hblnk, vga_sync.hsync, vga_sync.vcount, vga_sync.vblnk, vga_sync.vsync})
    );

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            vga_out.hcount <= '0;
            vga_out.hblnk  <= '0;
            vga_out.hsync  <= '0;
            vga_out.vcount <= '0;
            vga_out.vblnk  <= '0;
            vga_out.vsync  <= '0;
            vga_out.rgb    <= '0;
        end
        else begin
            vga_out.hcount <= vga_sync.hcount;
            vga_out.hblnk  <= vga_sync.hblnk;
            vga_out.hsync  <= vga_sync.hsync;
            vga_out.vcount <= vga_sync.vcount;
            vga_out.vblnk  <= vga_sync.vblnk;
            vga_out.vsync  <= vga_sync.vsync;
            vga_out.rgb    <= vga_sync.rgb;
        end
    end

    always_ff @(posedge clk) begin
        addr <= addr_nxt;
    end

    always_comb begin
        vga_nxt.hcount = vga_in.hcount;
        vga_nxt.hblnk  = vga_in.hblnk;
        vga_nxt.hsync  = vga_in.hsync;
        vga_nxt.vcount = vga_in.vcount;
        vga_nxt.vblnk  = vga_in.vblnk;
        vga_nxt.vsync  = vga_in.vsync;

        local_y     = vga_in.vcount - YPOS;
        char_idx    = (vga_in.hcount - XPOS) >> 3;
        addr_nxt    = '0;

        if((vga_in.hcount >= XPOS) && (vga_in.hcount < (XPOS + N_CHARS*8)) &&
           (vga_in.vcount >= YPOS) && (vga_in.vcount < (YPOS + 16))) begin
            addr_nxt = {char_code, local_y[3:0]};
        end

        if((vga_sync.hcount >= XPOS) && (vga_sync.hcount < (XPOS + N_CHARS*8)) &&
           (vga_sync.vcount >= YPOS) && (vga_sync.vcount < (YPOS + 16))) begin
            pixel_sub_x = vga_sync.hcount[2:0];

            if(char_line_pixels[3'd7 - pixel_sub_x]) begin
                vga_sync.rgb = 12'hFF0; // yellow
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
