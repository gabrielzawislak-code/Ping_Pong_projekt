/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Generates ball_pos's movement tick at a rate boosted by speed_pct
 * percent (0..150, steps of 10, from the speed switches) over the base
 * ~60 Hz rate used elsewhere in the game. Produces its own separate
 * tick, independent of counter_refresh_time and paddle_mover's ref_time.
 * Period per speed_pct value is a precomputed table, same structure as
 * counter_refresh_time.
 */
module ball_speed_ctrl(
    input  logic clk,
    input  logic rst_n,
    input  logic [2:0] flag_char,
    input  logic [7:0] speed_pct,
    output logic ball_ref_time
);

    logic [20:0] period;
    logic [20:0] timer, timer_nxt;
    logic        ball_ref_time_nxt;

    always_comb begin
        case(speed_pct)
            8'd0:   period = 21'd1083659; // same period as counter_refresh_time's SYNC_TIME (no boost)
            8'd10:  period = 21'd985145;
            8'd20:  period = 21'd903049;
            8'd30:  period = 21'd833584;
            8'd40:  period = 21'd773999;
            8'd50:  period = 21'd722439;
            8'd60:  period = 21'd677287;
            8'd70:  period = 21'd637446;
            8'd80:  period = 21'd601922;
            8'd90:  period = 21'd570348;
            8'd100: period = 21'd541830;
            8'd110: period = 21'd516028;
            8'd120: period = 21'd492572;
            8'd130: period = 21'd471156;
            8'd140: period = 21'd451525;
            8'd150: period = 21'd433464;
            default: period = 21'd1083659;
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            timer         <= '0;
            ball_ref_time <= 1'b0;
        end
        else begin
            timer         <= timer_nxt;
            ball_ref_time <= ball_ref_time_nxt;
        end
    end

    always_comb begin
        timer_nxt         = timer;
        ball_ref_time_nxt = 1'b0;

        if(flag_char == 3'b011) begin
            if(timer >= period) begin
                timer_nxt         = '0;
                ball_ref_time_nxt = 1'b1;
            end
            else begin
                timer_nxt = timer + 21'd1;
            end
        end
    end

endmodule
