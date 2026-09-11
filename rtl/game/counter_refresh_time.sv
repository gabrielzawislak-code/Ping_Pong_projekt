/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Free-running periodic timer producing a single-cycle ref_time pulse at
 * ~60 Hz. Used to pace paddle movement (paddle_mover) and, on both
 * boards, to pace the UART frame senders (send_state_frame /
 * send_paddle_frame).
 *
 * ref_time ticks unconditionally, regardless of flag_char - it used to
 * be gated to only tick during PLAYING, but paddle_mover and ball_pos
 * already re-check flag_char==PLAYING internally before acting on a
 * tick, so gating it here again was redundant AND harmful: it silently
 * froze the UART senders during IDLE/READY (they use the same ref_time
 * to pace frame transmission), which meant a fresh flag_char/paddle/ball
 * update could never reach the peer board outside PLAYING - deadlocking
 * the READY -> PLAYING handshake and freezing the peer's view of the
 * game. Keeping the tick free-running fixes that without changing any
 * gameplay behaviour.
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
