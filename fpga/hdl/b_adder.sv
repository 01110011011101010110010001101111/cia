module b_adder
    #(parameter DEPTH=100, parameter ADD = 1)
    (input wire clk_in,
                    input wire rst_in,
                    input wire poly_valid,
                    input wire [47:0] poly_in,
                    input wire [9:0] poly_idx,
                    output logic poly_ready,
                    input wire e_valid,
                    input wire [31:0] e_in,
                    input wire [9:0] e_idx,
                    output logic e_ready,
                    input wire b_valid,
                    input wire [31:0] b_in,
                    output logic b_ready,
                    input wire sum_ready,
                    output logic sum_valid,
                    output logic [35:0] sum,
                    output logic [9:0] sum_idx,
              );

/*
If ADD = 0, will subtract poly from b
*/
    logic [15:0] poly_top; // top 17 bits of polynomial [43:24]
    //logic poly_idx_buffer[9:0];
    //logic e_buffer[23:0];
    //logic b_buffer[23:0];
    logic sum_valid_buffer;

    // DOES NOT HAVE A READY/VALID HANDSHAKE AT ITS OUTPUT

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            sum_valid <= 0;
            poly_top <= 16'b0;
            poly_ready <= 0;
            b_ready <= 0;
            e_ready <= 0;
        end else begin

            // output their sum, decide if its valid or not (if see a ready handshake when its valid pull sum_valid to low)
            if (sum_valid && ~sum_ready) begin
                // pull all ready to low and wait
                poly_ready <= 0;
                b_ready <= 0;
                e_ready <= 0;
            end else begin
                // input handshake happen (all 3 are valid and poly has same)
                if (b_valid && e_valid && poly_valid && (poly_idx == e_idx)) begin
                    // ready handshake
                    poly_ready <= 1;
                    b_ready <= 1;
                    e_ready <= 1;
                    // set sum to valid and store sum
                    sum_valid <= 1;
                    sum_idx <= poly_idx;
                    poly_top <= (poly_idx < DEPTH - 2)?poly_in[47:32]:0;

                    if (ADD == 1) begin
                        sum[15:0] <= poly_top[15:0] + poly_in[15:0] + b_in[15:0] + e_in[15:0];
                        sum[31:15] <= poly_in[31:16] + b_in[31:16] + e_in[31:16];
                    end else begin
                        sum[15:0] <= - poly_top[15:0] - poly_in[15:0] + b_in[15:0];
                        sum[31:16] <= - poly_in[31:16] + b_in[31:16];
                    end
                    
                    //sum[5:0] <= poly_top[5:0] + poly[5:0] + b_in[5:0] + e_in[5:0];
                    //sum[11:6] <= poly_top[11:6] + poly[11:6] + b_in[11:6] + e_in[11:6];
                    //sum[17:12] <= poly_top[17:12] + poly[17:12] + b_in[17:12] + e_in[17:12];
                    //sum[23:18] <= poly_top[23:18] + poly[23:18] + b_in[23:18] + e_in[23:18];
                    
                end else if (poly_idx >= DEPTH) begin
                    // only poly changes (poly index too high)
                    sum_valid <= 0;
                    poly_ready <= 1;
                    b_ready <= 0;
                    e_ready <= 0;
                    poly_top <= 0;
                    
                end else begin
                    // nothing waiting for all valid
                    sum_valid <= 0;
                    poly_ready <= 0;
                    b_ready <= 0;
                    e_ready <= 0;
                end
                
                

                
            end
            
            
            /* if (poly_valid) begin

                // check if index b + something is less than something else put a 0 in there
                poly_top <= poly[43:24];
                poly_bottom <= poly[23:0] + poly_bottom;
                poly_idx_buffer <= poly_idx;
                inputs_ready[0] <= 1;
            end else begin
            end

            if (e_valid) begin
                e_buffer <= e_in;
                inputs_ready[1] <= 1;
            end else begin
            end

            if (b_valid) begin
                b_buffer <= b_in;
                inputs_ready[2] <= 1;
            end else begin
            end

            if (inputs_ready == 3'b111) begin
                // if poly is -16, have it hold off 1 cycle? buffer might be better?

                sum_valid <= 1;
                sum <= e_buffer + b_buffer + poly_bottom;
                poly_bottom <= poly_top;

                if (!poly_valid) begin
                    inputs_ready[0] <= 0;
                end else begin
                end

                if (!e_valid) begin
                    inputs_ready[1] <= 0;
                end else begin
                end

                if (!b_valid) begin
                    inputs_ready[2] <= 0;
                end else begin
                end
            end else begin

            end */
        end
    end

    
endmodule
              