module char_rom #(
    parameter string TEXT = {
        "PRESS BUTTON D TO START THE GAME",
        "WAITING FOR THE SECOND PLAYER!!!",
        "PINGPONG"                         
    }
)(
    input logic clk,
    input logic [6:0] char_xy,
    output logic [6:0] char_code
);


// DATA_WIDTH should be 8-bit to properly load characters from string
    logic [7:0] rom [0:71];

    always_ff @(posedge clk) begin
        char_code <= rom[char_xy];
    end

    initial begin
        for (int i = 0; i < 72; i++) rom[i] = TEXT[i];
    end

endmodule