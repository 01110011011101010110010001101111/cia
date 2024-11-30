module public_private_mm
    #(parameter DEPTH=100)
    (input wire clk_in,
                    input wire rst_in,
                    input wire A_valid,
                    input wire s_valid,
                    input wire [9:0] A_idx,
                    input wire [31:0] pk_A,
                    input wire [1:0] sk_s,
                    output logic [9:0] idx_B,
                    output logic [31:0] B_out,
                    output logic B_valid,
                    input logic [9:0] h_in,
                    output logic [9:0] h_out
              );

  /*
    Takes in 2 values of A.
        Takes in 2 values of s.
        Multiply each value of A with s.

  */

    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            B_valid <= 0;
            idx_B <= 0;
        end else begin
            h_out <= h_in;
            idx_B <= A_idx;
            B_valid <= A_valid && s_valid;

            B_out[15:0] <= (sk_s[0] ? pk_A[15:0] : 16'b0);
            B_out[31:16] <= (sk_s[1] ? pk_A[31:16] : 16'b0);
        end
    end

    
endmodule