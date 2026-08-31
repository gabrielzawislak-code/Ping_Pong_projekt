/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Double-flop synchronizer for the UART tx/rx lines crossing from the pin
 * (asynchronous, board-to-board) domain into the local clock domain.
 */
module uart_sync(
    input logic clk,
    input logic tx,
    input logic rx,
    output logic tx_sync,
    output logic rx_sync
);

    always_ff @(posedge clk) begin
        tx_sync <= tx;
        rx_sync <= rx;
    end


endmodule