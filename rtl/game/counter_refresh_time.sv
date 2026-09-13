/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Free-running periodic timer producing a single-cycle ref_time pulse at
 * ~60 Hz. Used to pace paddle movement (paddle_mover) and the UART
 * frame senders (send_state_frame / send_paddle_frame) on both boards.
 * Ticks unconditionally, regardless of flag_char - paddle_mover and
 * ball_pos already check flag_char==PLAYING themselves before acting on
 * a tick.
 */
module counter_refresh_time(
    input logic clk,
    input logic rst_n,
    output logic ref_time
);

    localparam bit [21:0] SYNC_TIME = 1_083_659;

    logic [21:0] timer, timer_nxt;
    logic ref_time_nxt;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            timer <= '0;
            ref_time <= 0;
        end
        else begin
            timer <= timer_nxt;
            ref_time <= ref_time_nxt;
        end
    end

    always_comb begin
        timer_nxt = timer;
        ref_time_nxt = 1'b0;

        if(timer >= SYNC_TIME) begin
            timer_nxt = '0;
            ref_time_nxt = 1'b1;
        end
        else begin
            timer_nxt = timer + 1;
        end
    end

endmodule
