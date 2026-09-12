//Listing 8.4
module uart
   #( // Default setting:
      // ~9,600 baud, 8 data bits, 1 stop bit, 2^4 FIFO
      //
      // Lowered from the original 19,200 baud: board-to-board UART now
      // runs over unshielded jumper wires between two independently
      // powered Basys3 boards (no termination, no level-matched grounds
      // beyond a single shared GND wire) - halving the baud rate doubles
      // the time budget per bit, which is the standard first response to
      // marginal signal integrity on a link like this. The 12-byte
      // HOST->CLIENT frame still comfortably fits in the ~60 Hz tick
      // budget: 12 bytes * 10 bits / 9600 baud =~ 12.5 ms, versus a
      // ~16.7 ms period between frames.
      parameter DBIT = 8,     // # data bits
                SB_TICK = 16, // # ticks for stop bits, 16/24/32
                              // for 1/1.5/2 stop bits
                DVSR = 424,   // baud rate divisor
                              // DVSR = 65M/(16*baud rate)
                DVSR_BIT = 9, // # bits of DVSR
                FIFO_W = 4    // # addr bits of FIFO
                              // # words in FIFO=2^FIFO_W
   )
   (
    input wire clk, rst_n,
    input wire rd_uart, wr_uart, rx,
    input wire [7:0] w_data,
    output wire tx_full, rx_empty, tx,
    output wire [7:0] r_data
   );

   // signal declaration
   wire tick, rx_done_tick, tx_done_tick;
   wire tx_empty, tx_fifo_not_empty;
   wire [7:0] tx_fifo_out, rx_data_out;

   //body
   mod_m_counter #(.M(DVSR), .N(DVSR_BIT)) baud_gen_unit
      (.clk(clk), .rst_n(rst_n), .q(), .max_tick(tick));

   uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit
      (.clk(clk), .rst_n(rst_n), .rx(rx), .s_tick(tick),
       .rx_done_tick(rx_done_tick), .dout(rx_data_out));

   fifo #(.B(DBIT), .W(FIFO_W)) fifo_rx_unit
      (.clk(clk), .rst_n(rst_n), .rd(rd_uart),
       .wr(rx_done_tick), .w_data(rx_data_out),
       .empty(rx_empty), .full(), .r_data(r_data));

   fifo #(.B(DBIT), .W(FIFO_W)) fifo_tx_unit
      (.clk(clk), .rst_n(rst_n), .rd(tx_done_tick),
       .wr(wr_uart), .w_data(w_data), .empty(tx_empty),
       .full(tx_full), .r_data(tx_fifo_out));

   uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit
      (.clk(clk), .rst_n(rst_n), .tx_start(tx_fifo_not_empty),
       .s_tick(tick), .din(tx_fifo_out),
       .tx_done_tick(tx_done_tick), .tx(tx));

   assign tx_fifo_not_empty = ~tx_empty;

endmodule