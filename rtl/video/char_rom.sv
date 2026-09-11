/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * ROM holding the fixed on-screen text messages (start/waiting/game-over
 * prompts), built at elaboration time from the TEXT parameter and indexed
 * by char_xy.
 */
module char_rom #(
    parameter string TEXT = {
        "PRESS THE MIDDLE BUTTON TO START",
        "WAITING FOR THE SECOND PLAYER!!!",
        "PINGPONG",
        "GAMEOVER"                       
    }
)(
    input logic clk,
    input logic [6:0] char_xy,
    output logic [6:0] char_code
);


// DATA_WIDTH should be 8-bit to properly load characters from string
    logic [7:0] rom [0:79];

    always_ff @(posedge clk) begin
        char_code <= rom[char_xy];
    end

    initial begin
        for (int i = 0; i < 80; i++) rom[i] = TEXT[i];
    end

endmodule