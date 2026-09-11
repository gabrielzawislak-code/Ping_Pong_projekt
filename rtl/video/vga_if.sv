/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * SystemVerilog interface bundling the VGA timing/blanking/sync signals
 * together with the pixel color, used to pass a whole pipeline stage's
 * worth of VGA state between drawing modules with a single port.
 */
interface vga_if;

    logic [10:0] hcount;
    logic hblnk;
    logic hsync;
    
    logic [10:0] vcount;
    logic vblnk;
    logic vsync;

    logic [11:0] rgb;

    modport in(
        input hcount,
        input hblnk,
        input hsync,
        input vcount,
        input vblnk,
        input vsync,
        input rgb
    );

    modport out(
        output hcount,
        output hblnk,
        output hsync,
        output vcount,
        output vblnk,
        output vsync,
        output rgb
    );


endinterface