module b_adder
    #(parameter DEPTH=100, parameter ADD = 1)
    (input wire clk_in,
                    input wire rst_in,
                    input wire poly_valid,
                    input wire [47:0] poly_in,
                    input wire [9:0] poly_idx,
                    input wire e_valid,
                    input wire [31:0] e_in,
                    input wire [9:0] b_idx,
                    input wire b_valid,
                    input wire [31:0] b_in,
                    output logic sum_valid,
                    output logic [31:0] sum,
                    output logic [9:0] sum_idx,
                    input wire [9:0] h_in,
                    output logic [9:0] h_out
              );

/*
If ADD = 0, will subtract poly from b
*/
    logic [15:0] poly_top; 

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            sum_valid <= 0;
            poly_top <= 16'b0;
        end else begin
            if (poly_idx == b_idx) begin
                
                // set sum to valid and store sum
                sum_valid <= b_valid && poly_valid && e_valid;
                sum_idx <= poly_idx;
                poly_top <= (poly_idx < DEPTH - 2)?poly_in[47:32]:0;
                h_out <= h_in;

                if (ADD == 1) begin
                    sum[15:0] <= poly_top[15:0] + poly_in[15:0] + b_in[15:0] + e_in[15:0];
                    sum[31:16] <= poly_in[31:16] + b_in[31:16] + e_in[31:16];
                end else begin
                    sum[15:0] <= - poly_top[15:0] - poly_in[15:0] + b_in[15:0];
                    sum[31:16] <= - poly_in[31:16] + b_in[31:16];
                end
                
                
            end else if (poly_idx >= DEPTH) begin
                // only poly changes (poly index too high)
                sum_valid <= 0;
                poly_top <= 0;
                
            end else begin
                // waiting
                sum_valid <= 0;
            end
            
        end
    end

    
endmodule
              