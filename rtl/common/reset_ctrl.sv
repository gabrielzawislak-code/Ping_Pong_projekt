/**
 * Author: Mateusz Zybura, Gabriel Zawiślak
 *
 * Description:
 * Reset controller. This is the only place in the design allowed to use
 * a raw, unsynchronized asynchronous reset source (the board's reset
 * button, combined with the clocking wizard's lock signal). It produces
 * rst_n: a reset that still asserts immediately/asynchronously (so the
 * rest of the design still reacts to the button right away), but whose
 * release is re-synchronized to clk, so every register in the design
 * comes out of reset on the same clock edge instead of racing each other
 * if the raw source happens to release close to a clock edge.
 */
module reset_ctrl(
    input logic clk,
    input logic rst_in_n,
    output logic rst_n
);

    (* ASYNC_REG = "TRUE" *) logic sync_stage1;

    always_ff @(posedge clk, negedge rst_in_n) begin
        if(!rst_in_n) begin
            sync_stage1 <= 1'b0;
            rst_n <= 1'b0;
        end
        else begin
            sync_stage1 <= 1'b1;
            rst_n <= sync_stage1;
        end
    end

endmodule
