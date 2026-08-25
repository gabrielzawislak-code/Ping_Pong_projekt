module counter_refresh_time(
    input logic clk,
    input logic rst_n,
    input logic [2:0] flag_char,
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
        ref_time_nxt = ref_time;

        if(flag_char == 3'b011) begin
            if(timer >= SYNC_TIME) begin
                timer_nxt = '0;
                ref_time_nxt = 1'b1;
            end
            else begin
                timer_nxt = timer + 1;
                ref_time_nxt = 1'b0;
            end
        end
    end

endmodule