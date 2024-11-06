module public_private_mm 
    #(parameter DEPTH=784)
    (input wire clk_in,
                    input wire rst_in,
                    input wire A_valid,
                    input wire s_valid,
                    input wire [9:0] A_idx,
                    input wire [9:0] s_idx,
                    input wire [23:0] pk_A,
                    input wire [3:0] sk_s,
                    output logic A_ready,
                    output logic s_ready,
                    input wire B_ready,
                    output logic [9:0] idx_B,
                    output logic [41:0] B_out,
                    output logic B_valid
              );

    
  
  /*
    Takes in 4 values of A.
        Takes in 28 values of s.
        Multiply each value of A with s.

  */
    logic [23:0] A_pk;
    logic [3:0] s_sk;

    logic[9:0] A_idx_stored;
    logic [9:0] s_idx_stored;
 
    logic [4:0] state;
    /*
    [0] - is A loaded into A_pk
    [1] - is s loaded into s_sk
    [2] - new s needed after this (GOOD TO OUTPUT)
    [3] - new a needed after this
    [4] - done
    */

    // TODO figure out s_ready

    assign A_ready = ~state[0];

    always_ff @(posedge clk_in) begin
        if(~rst_in) begin
            // A_ready <= False;
            s_ready <= 1;
            B_valid <= 0;
            idx_B <= 0;
            state <= 0;
        end else begin
            if (A_valid) begin
                A_pk <= pk_A;
                A_idx_stored <= A_idx;
                state[0] <= 1;
            end else begin

            end

            if (s_valid) begin
                s_sk <= sk_s;
                s_idx_stored <= s_idx;
                state[1] <= 1;
                // s_ready <= 0;
            end else begin
            end

            if (!B_ready) begin

            end else begin
                
                if (state[1:0] == 2'b11) begin
                    idx_B <= s_idx_stored + A_idx_stored;

                    B_out[5:0] <= (s_sk[0] ? A_pk[5:0] : 6'b0);
                    B_out[11:6] <= (s_sk[0] ? A_pk[11:6] : 6'b0) + (s_sk[1] ? A_pk[5:0] : 6'b0);
                    B_out[17:12] <= (s_sk[0] ? A_pk[17:12] : 6'b0) + (s_sk[1] ? A_pk[11:6] : 6'b0) + (s_sk[2] ? A_pk[5:0] : 6'b0);
                    B_out[23:18] <= (s_sk[0] ? A_pk[23:18] : 6'b0) + (s_sk[1] ? A_pk[17:12] : 6'b0) + (s_sk[2] ? A_pk[16:11] : 6'b0) + (s_sk[3] ? A_pk[5:0] : 6'b0);
                    B_out[29:24] <= (s_sk[1] ? A_pk[23:18] : 6'b0) + (s_sk[2] ? A_pk[17:12] : 6'b0) + (s_sk[3] ? A_pk[11:6] : 6'b0);
                    B_out[35:30] <= (s_sk[2] ? A_pk[23:18] : 6'b0) + (s_sk[3] ? A_pk[17:12] : 6'b0);
                    B_out[41:36] <= (s_sk[3] ? A_pk[23:18] : 6'b0);

                    B_valid <= 1;

                    /*for (int i = 0; i < 4; i++) begin
                        if (i + s_counter< 8) begin
                            int index_start = 6 * s_counter + 6 * i + 5;
                            int index_end = 6 * s_counter + 6 * i;

                            B_out[index_start : index_end] <= B_out[index_start : index_end] + (s_sk[s_counter] ? A_pk[6 * i + 5 : 6 * i] : 6'b0);
                        end else begin
                        end
                    end
                    s_counter <= s_counter+1;

                    if (s_counter == 3) begin
                        s_ready <= 0;
                        B_valid <= 1;
                    end else begin
                        s_ready <= s_ready + 1;
                        B_valid <= 0;
                    end

                    */

                    if (s_idx_stored == DEPTH-4) begin
                        state[0] <= 0;
                        s_ready <= 0;
                    end else begin
                        s_ready <= 1;
                    end
                    
                end else begin
                end

            end
        end
    end

    
endmodule