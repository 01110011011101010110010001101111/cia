module nn_adder
    #(parameter K_VAL=502,
    parameter DEPTH = 100, parameter OUT_NODES = 10)
    (input wire clk_in,
                    input wire rst_in,
                    input wire data_valid,
                    input wire [9:0] idx_k_in, // 0 - 502/2
                    input wire [9:0] idx_N_in, // 0 - 100
                    input wire [31:0] ct_in, // A
                    input wire [2:0] weights_in,
                    input wire [5:0] weights_idx, // 0-10
                    input wire [31:0] mem_in,
                    input wire [8:0] bias_in,

                    output logic [31:0] sum_out,
                    output logic [9:0] sum_idx_k,
                    output logic [9:0] sum_idx_N,
                    output logic [5:0] sum_idx_w,
                    output logic sum_valid
              );

    localparam HALF_K = K_VAL/2;

    logic add_bias;


    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            sum_valid <= 0;
        end else begin
            if (data_valid) begin
                sum_valid <= 1;
                sum_out[15:0] <= $signed(ct_in[15:0]) * $signed(weights_in) + $signed(mem_in[15:0]) + $signed((idx_k_in == HALF_K-1 && idx_N_in == 0)?bias_in:3'b0);
                sum_out[31:16] <= $signed(ct_in[31:16]) * $signed(weights_in) + $signed(mem_in[31:16]);
                sum_idx_k <= idx_k_in;
                sum_idx_N <= idx_N_in;
                sum_idx_w <= weights_idx;
                add_bias <= (idx_k_in == HALF_K-1 && idx_N_in == 0)?1:0;
            end else begin
                sum_valid <= 0;
            end
        end
    end

    
endmodule
              