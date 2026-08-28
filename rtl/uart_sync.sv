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