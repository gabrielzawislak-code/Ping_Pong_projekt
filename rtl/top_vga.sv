/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Modified by:
 * Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * The project top module. This board (player_2) drives no monitor and
 * runs no game logic - it only debounces its up/down buttons and
 * continuously forwards their state to the MASTER board over UART, which
 * runs the whole game and both paddles.
 */

module top_vga (
        input  logic clk_65Mhz,
        input  logic rst_n,
        input logic btn_up,
        input logic btn_down,
        output logic tx_pin
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    logic wr;
    logic [7:0] data_out;
    logic tx_full;
    logic tx;

    /**
     * Submodules instances
     */

    send_bytes u_send_bytes(
        .clk(clk_65Mhz),
        .rst_n,
        .btn_up(btn_up),
        .btn_down(btn_down),
        .tx_full(tx_full),
        .wr_en(wr),
        .data_out(data_out)
    );

    uart u_uart(
        .clk(clk_65Mhz),
        .rst_n,
        .wr_uart(wr),
        .w_data(data_out),
        .rd_uart(1'b0),
        .rx(1'b1),
        .r_data(),
        .rx_empty(),
        .tx(tx),
        .tx_full(tx_full)
    );

    uart_sync u_uart_sync(
        .clk(clk_65Mhz),
        .tx(tx),
        .rx(1'b1),
        .tx_sync(tx_pin),
        .rx_sync()
    );

endmodule
