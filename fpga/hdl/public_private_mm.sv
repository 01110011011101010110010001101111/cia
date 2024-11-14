module public_private_mm
    #(parameter DEPTH=784)
    (input wire clk_in,
                    input wire rst_in,
                    input wire A_valid,
                    input wire s_valid,
                    input wire [9:0] A_idx,
                    input wire [9:0] s_idx,
                    input wire [35:0] pk_A,
                    input wire [1:0] sk_s,
                    output logic A_ready,
                    output logic s_ready,
                    output logic [9:0] idx_B,
                    output logic [53:0] B_out,
                    input wire B_ready,
                    output logic B_valid
              );

    
  // ignoring B_ready because the sum module should always be able to take a B.

  /*
    Takes in 4 values of A.
        Takes in 28 values of s.
        Multiply each value of A with s.

  */
    logic [35:0] A_pk;
    logic [2:0] s_sk;

    logic[9:0] A_idx_stored;
    logic [9:0] s_idx_stored;
 
    logic [2:0] state;
    /*
    [0] - is A loaded into A_pk
    [1] - is s loaded into s_sk
    */

    always_ff @(posedge clk_in) begin
        if(~rst_in) begin
            // A_ready <= False;
            s_ready <= 1;
            A_ready <= 1;
            B_valid <= 0;
            idx_B <= 0;
            state <= 0;
        end else begin
            case (state)
                3'b000 : begin
                    B_valid <= 0;
                    if (A_ready && A_valid && s_ready && s_valid) begin
                        A_pk <= pk_A;
                        A_idx_stored <= A_idx;
                        s_sk <= sk_s;
                        s_idx_stored <= s_idx;
                        state <= 3'b011;
                    end else if (A_ready && A_valid) begin
                        A_ready <= 0;
                        A_pk <= pk_A;
                        A_idx_stored <= A_idx;
                        state <= 3'b001;
                    end else if (s_ready && s_valid) begin
                        s_ready <= 0;
                        s_sk <= sk_s;
                        s_idx_stored <= s_idx;
                        state <= 3'b010;
                    end else begin
                        A_ready <= 1;
                        s_ready <= 1;
                    end
                end
                3'b001 : begin
                    B_valid <= 0;
                    if (s_ready && s_valid) begin
                        s_ready <= 1;
                        s_sk <= sk_s;
                        s_idx_stored <= s_idx;
                        state <= 3'b011;
                    end else begin
                    end
                end
                3'b010 : begin
                    B_valid <= 0;
                     if (A_ready && A_valid) begin
                        s_ready <= 1;
                        A_ready <= 0;
                        A_pk <= pk_A;
                        A_idx_stored <= A_idx;
                        state <= 3'b011;
                     end else begin
                     end
                end
                3'b011 : begin
                    idx_B <= s_idx_stored + A_idx_stored;

                    B_out[17:0] <= (s_sk[0] ? A_pk[17:0] : 18'b0);
                    B_out[35:18] <= (s_sk[1] ? A_pk[17:0] : 18'b0) + (s_sk[0] ? A_pk[35:18] : 18'b0);
                    B_out[53:36] <= (s_sk[1] ? A_pk[35:18] : 18'b0);

                    /* B_out[5:0] <= (s_sk[0] ? A_pk[5:0] : 6'b0);
                    B_out[11:6] <= 6'b111111 & ((s_sk[0] ? A_pk[11:6] : 6'b0) + (s_sk[1] ? A_pk[5:0] : 6'b0));
                    B_out[17:12] <= 6'b111111 & ((s_sk[0] ? A_pk[17:12] : 6'b0) + (s_sk[1] ? A_pk[11:6] : 6'b0) + (s_sk[2] ? A_pk[5:0] : 6'b0));
                    B_out[23:18] <= 6'b111111 & ((s_sk[0] ? A_pk[23:18] : 6'b0) + (s_sk[1] ? A_pk[17:12] : 6'b0) + (s_sk[2] ? A_pk[11:6] : 6'b0) + (s_sk[3] ? A_pk[5:0] : 6'b0));
                    B_out[29:24] <= 6'b111111 & ((s_sk[1] ? A_pk[23:18] : 6'b0) + (s_sk[2] ? A_pk[17:12] : 6'b0) + (s_sk[3] ? A_pk[11:6] : 6'b0));
                    B_out[35:30] <= 6'b111111 & ((s_sk[2] ? A_pk[23:18] : 6'b0) + (s_sk[3] ? A_pk[17:12] : 6'b0));
                    B_out[41:36] <= (s_sk[3] ? A_pk[23:18] : 6'b0);*/

                    B_valid <= 1;
                    
                    if (B_ready) begin
                        if (s_idx_stored == DEPTH-2) begin
                            A_ready <= 1;
                            if(s_ready && s_valid) begin
                                s_sk <= sk_s;
                                s_idx_stored <= s_idx;
                                state <= 3'b010;
                                s_ready <= 0;
                                
                            end else begin
                                state <= 3'b000;
                                s_ready <= 1;
                            end
                            
                        end else begin
                            A_ready <= 0;

                            if(s_ready && s_valid) begin
                                s_sk <= sk_s;
                                s_idx_stored <= s_idx;
                            end else begin
                                state <= 3'b001;
                            end
                        end
                    end else begin
                        s_ready <= 0;
                        A_ready <= 0;
                    end
                    
                    
                end
                default: state <= 0;
            endcase
        end
    end

    
endmodule