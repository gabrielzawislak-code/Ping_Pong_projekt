module receive_bytes(
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic rx_empty,
    output logic rd_en,
    output logic [10:0] paddle_2_y,
    output logic rx_wait_info
);
    
    logic [10:0] temp_paddle_2, temp_paddle_2_nxt, paddle_2_y_nxt;
    logic rx_wait_nxt;
    logic rd_en_nxt;
    logic [2:0] counter, counter_nxt;
    
    enum logic [2:0] {
        IDLE,
        WAIT,
        BYTE_0,
        BYTE_1,
        BYTE_2,
        BYTE_3
    } state, state_nxt;
    
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
           paddle_2_y <= 334;
           temp_paddle_2 <= 334;
           rx_wait_info <= 0;
           rd_en <= 0;
           counter <= '0;
           state <= IDLE;
        end
        else begin
            paddle_2_y <= paddle_2_y_nxt;
            temp_paddle_2 <= temp_paddle_2_nxt;
            rx_wait_info <= rx_wait_nxt;
            rd_en <= rd_en_nxt;
            counter <= counter_nxt;
            state <= state_nxt;
        end
    end

    always_comb begin
        temp_paddle_2_nxt = temp_paddle_2;
        rd_en_nxt = 0;
        rx_wait_nxt = 0;
        paddle_2_y_nxt = paddle_2_y;
        counter_nxt = counter;

        case(state)
            IDLE: begin
                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = IDLE;
                end
            end

            WAIT: begin
                if(counter == 0) begin
                    state_nxt = BYTE_0;
                end
                else if(counter == 1) begin
                    state_nxt = BYTE_1;
                end
                else if(counter == 2) begin
                    state_nxt = BYTE_2;
                end
                else if(counter == 3) begin
                    state_nxt = BYTE_3;
                end
                else begin
                    state_nxt = IDLE;
                end
            end
            
            
            BYTE_0: begin
                if(data_in == 8'hA2) begin
                    rx_wait_nxt = 1;
                end
                
                if(!rx_empty) begin
                    if(data_in[7:4] == 4'hA) begin
                        rd_en_nxt = 1;
                        counter_nxt = counter + 1;
                        state_nxt = WAIT;
                    end
                    else begin
                        state_nxt = IDLE;
                    end
                end
                else begin
                    state_nxt = BYTE_0;
                end
            end

            BYTE_1: begin
                temp_paddle_2_nxt[10:8] = data_in[2:0];
                
                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_1;
                end
            end

            BYTE_2: begin
                temp_paddle_2_nxt[7:0] = data_in;

                if(!rx_empty) begin
                    rd_en_nxt = 1;
                    counter_nxt = counter + 1;
                    state_nxt = WAIT;
                end
                else begin
                    state_nxt = BYTE_2;
                end
            end

            BYTE_3: begin
                if(data_in == 8'hAA) begin
                    paddle_2_y_nxt = temp_paddle_2;
                end
                state_nxt = IDLE;
            end

            default: begin
                state_nxt = IDLE;
            end
        endcase
    end

endmodule