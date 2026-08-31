/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Continuously transmits the current, debounced up/down button state to
 * the MASTER board. Every byte is a complete, independent snapshot -
 * {6'b101100, btn_down, btn_up} - so there is no framing/state machine
 * needed: whenever the TX FIFO has room, the latest button state is
 * written into it.
 */
module send_bytes(
    input logic clk,
    input logic rst_n,
    input logic btn_up,
    input logic btn_down,
    input logic tx_full,
    output logic wr_en,
    output logic [7:0] data_out
);

    localparam logic [5:0] BUTTON_BYTE_HEADER = 6'b101100;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            wr_en <= 1'b0;
            data_out <= '0;
        end
        else begin
            wr_en <= !tx_full;
            data_out <= {BUTTON_BYTE_HEADER, btn_down, btn_up};
        end
    end

endmodule
