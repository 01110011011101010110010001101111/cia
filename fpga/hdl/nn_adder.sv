// TODO LATER?? Add previous memory value too

module nn_adder
    #(parameter K_VAL=501,
    parameter DEPTH = 100, parameter OUT_NODES = 10)
    (input wire clk_in,
                    input wire rst_in,
                    input wire pk_valid,
                    input wire [9:0] idx_k_in,
                    input wire [9:0] idx_N_in,
                    input wire [35:0] ct_in,
                    output logic ct_ready,
                    input wire weights_valid,
                    input wire [2:0] weights_in,
                    input wire [5:0] weight_idx, // 0-10
                    output logic weights_ready,

                    input wire sum_ready,
                    output logic sum_valid,
                    output logic [35:0] sum_out,
                    output logic [9:0] sum_idx_k,
                    output logic [9:0] sum_idx_N,
                    output logic [5:0] sum_idx_w
              );

/*
If ADD = 0, will subtract poly from b
*/
    
    logic [35:0] ct_buffer;
    logic ct_buff_valid,
    logic [9:0] ct_idx_buff_k;
    logic [9:0] ct_idx_buff_N;

    always_comb begin

        
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            ct_ready <= 0;
            weights_ready <= 0;
            ct_buff_valid <= 0;
            sum_valid <= 0;
        end else begin

            // output their sum, decide if its valid or not (if see a ready handshake when its valid pull sum_valid to low)
            if (sum_valid && ~sum_ready) begin
                // pull all ready to low and wait
                ct_ready <= 0;
                weights_ready <= 0;
            end else begin
                // get weights >> iterate over A in that row
                if(~ct_buff_valid) begin
                    if(ct_valid) begin
                        ct_ready <= 1;
                        ct_buff_valid <= 1;
                        ct_buffer <= ct_in;
                        weights_ready <= 0;
                        ct_idx_buff_k <= idx_k_in;
                        ct_idx_buff_N <= idx_N_in;
                    end else begin
                        ct_ready <= 1;
                        weights_ready <= 0;
                        ct_buff_valid <= 0;
                        sum_valid <= 0;
                    end
                end else begin
                    // input handshake happens
                    if (weights_valid) begin
                        // ready handshake
                        weights_ready <= 1;
                        ct_ready <= 0;
                        
                        // set sum to valid and store sum
                        sum_valid <= 1;
                        sum_idx_k <= ct_idx_buff_k;
                        sum_idx_N <= ct_idx_buff_N;
                        sum_idx_w <= weights_idx;

                        sum[17:0] <= $signed(ct_buffer[17:0]) * $signed(weights_in)
                        sum[35:18] <= $signed(ct_buffer[35:18]) * $signed(weights_in)

                        if(weight_idx == OUT_NODES - 1) begin
                            ct_buff_valid <= 0;
                        end else begin
                        end
                        
                    end else begin
                        // nothing waiting for all valid
                        ct_ready <= 0;
                        weights_ready <= 0;
                        sum_valid <= 0
                    end
                end
                
                

                
            end
        end
    end

    
endmodule
              