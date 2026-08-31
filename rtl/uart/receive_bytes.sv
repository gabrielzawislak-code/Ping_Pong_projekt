/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Decodes player 2's button state. The other board continuously
 * transmits a single self-contained byte - 6'b101100 header bits followed
 * by {btn_down, btn_up} - so there is nothing to frame or assemble: every
 * byte that passes the header check is immediately a complete, fresh
 * snapshot of the buttons.
 */
module receive_bytes(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic btn_up_2,
    output logic btn_down_2
);

    localparam logic [5:0] BUTTON_BYTE_HEADER = 6'b101100;

    logic rd_en_nxt;
    logic btn_up_2_nxt, btn_down_2_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            rd_en <= 1'b0;
            btn_up_2 <= 1'b0;
            btn_down_2 <= 1'b0;
        end
        else begin
            rd_en <= rd_en_nxt;
            btn_up_2 <= btn_up_2_nxt;
            btn_down_2 <= btn_down_2_nxt;
        end
    end

    always_comb begin
        rd_en_nxt = 1'b0;
        btn_up_2_nxt = btn_up_2;
        btn_down_2_nxt = btn_down_2;

        if(!rx_empty) begin
            rd_en_nxt = 1'b1;

            if(data_in[7:2] == BUTTON_BYTE_HEADER) begin
                btn_up_2_nxt = data_in[0];
                btn_down_2_nxt = data_in[1];
            end
        end
    end

endmodule
