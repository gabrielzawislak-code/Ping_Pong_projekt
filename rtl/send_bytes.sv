module send_bytes(
    input logic clk,
    input logic rst_n,
    input logic [2:0] flag_char,
    input logic ref_time,
    input logic [10:0] paddle_2_y,
    output logic [7:0] data_out,
    output logic wr_en
);


    enum logic [2:0] {
        BYTE_0,
        WAIT,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } state, state_nxt;
    
    logic wr_en_nxt;
    logic [7:0] data_out_nxt;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            data_out <= '0;
            wr_en <= '0;
            state <= BYTE_0;
        end
        else begin
            data_out <= data_out_nxt;
            state <= state_nxt;
            wr_en <= wr_en_nxt;
        end
    end

    always_comb begin
        data_out_nxt = data_out;
        wr_en_nxt = '0;
        
        case(state)
            BYTE_0: begin
                if(flag_char == 3'b001) begin
                    data_out_nxt = 8'hA1;
                end
                else if(flag_char == 3'b010) begin
                    data_out_nxt = 8'hA2;
                end
                else if(flag_char == 3'b011) begin
                    data_out_nxt = 8'hA3;
                end
                else begin
                    data_out_nxt = 8'hA4;
                end

                wr_en_nxt = 1'b1;
                
                if(ref_time) begin
                    state_nxt = BYTE_1;
                end
                else begin
                    state_nxt = WAIT;
                end
            end

            WAIT: begin
                if(ref_time) begin
                    state_nxt = BYTE_1;
                end
                else begin
                    state_nxt = WAIT;
                end
            end


            BYTE_1: begin
                data_out_nxt = {5'b0, paddle_2_y[10:8]};
                wr_en_nxt = 1'b1;
                state_nxt = BYTE_2;
            end

            BYTE_2: begin
                data_out_nxt = paddle_2_y[7:0];
                wr_en_nxt = 1'b1;
                state_nxt = BYTE_3;
            end

            BYTE_3: begin
                data_out_nxt = 8'hAA;
                wr_en_nxt = 1'b1;
                state_nxt = BYTE_0;
            end

            default: begin
                state_nxt = BYTE_0;
            end
        endcase
    end

endmodule