module game_fsm_tb;

    timeunit 1ns;
    timeprecision 1ps;

    logic clk, rst_n;
    logic btnD;
    logic rx_info;
    logic tick;

    wire tx_info;
    wire [1:0] flag_char;

    debounce u_debounce(
        .clk(clk),
        .rst_n(rst_n),
        .sw(btnD),
        .db_level(),
        .db_tick(tick)
    );

    game_fsm u_game_fsm(
    .clk(clk),    
    .rst_n(rst_n),
    .btn_D(tick),
    .rx_info(rx_info),
    .flag_char(flag_char),
    .tx_info(tx_info)
    );

    initial begin
        clk = 1'b0;
        forever #15.4 clk = ~clk;
    end

    initial begin
        rx_info = 1'b0;
        btnD = 1'b0;
        rst_n = 1'b1;
        #(1000)
        rst_n = 1'b0;
        #(1000)
        rst_n = 1'b1;

        #(10000)

        btnD = 1'b1;
        rx_info = 1'b1;
        wait(tick == 1);
        #(1000)
        


        $finish;
    end

endmodule