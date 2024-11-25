module enc_addr_looper
    #(parameter DEPTH=100, parameter K=500)
    (input wire clk_in,
                    input wire rst_in,
                    input wire begin_enc,
                    output logic [6:0] inner_N_out,
                    output logic [6:0] outer_N_out,
                    output logic [9:0] k_out,
                    output logic [16:0] A_addr,
                    output logic [16:0] s_addr,
                    output logic [12:0] b_addr,
                    output logic [9:0] e_addr,
                    output logic e_zero,
                    output logic addr_valid,
                    output logic done
              );

  /*
    e_zero describes if e term put into b adder should just be 0
  */

    localparam HALF_DEPTH = DEPTH/2;

    logic [6:0] inner_s_idx;
    logic [6:0] inner_A_idx;
    logic [9:0] outer_k_idx;

    logic addr_valid_buffer;

    evt_counter #(.MAX_COUNT(HALF_DEPTH)) inner_s_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in(begin_enc),
         .count_out(inner_s_idx));

    evt_counter #(.MAX_COUNT(HALF_DEPTH)) inner_A_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in((inner_s_idx == HALF_DEPTH -1)),
         .count_out(inner_A_idx));

    evt_counter #(.MAX_COUNT(K)) outer_k_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in((inner_s_idx == HALF_DEPTH -1) && (inner_A_idx == HALF_DEPTH -1)),
         .count_out(outer_k_idx));

    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            A_addr <= 0;
            s_addr <= 0;
            e_addr <= 0;
            b_addr <= 0;
            addr_valid <= 0;
            addr_valid_buffer <= 0;
            done <= 0;
        end else begin
            if(done)begin
                addr_valid <= 0;
            end else begin
                // addr_valid_buffer <= addr_valid_buffer?1:begin_enc;
                // addr_valid <= addr_valid_buffer;

                // TODO: if this fails on first on means addr_valid needs correction
                addr_valid <= addr_valid?1:begin_enc;
                A_addr <= (outer_k_idx << 5) + (outer_k_idx << 4) + (outer_k_idx << 1) + inner_A_idx; // add 1 to everything???
                s_addr <= (outer_k_idx << 5) + (outer_k_idx << 4) + (outer_k_idx << 1) + inner_s_idx;
                // A_addr <= (outer_k_idx * (HALF_DEPTH)) + inner_A_idx; // add 1 to everything???
                // s_addr <= (outer_k_idx * (HALF_DEPTH)) + inner_s_idx;
                b_addr <= (inner_A_idx + inner_s_idx >= HALF_DEPTH) ? 0: inner_A_idx + inner_s_idx;
                e_addr <= inner_s_idx;
                e_zero <= ~(inner_A_idx == 0 && outer_k_idx == 0);

                inner_N_out <= inner_s_idx;
                outer_N_out <= inner_A_idx;
                k_out <= outer_k_idx;
                done <= ((outer_k_idx == K-1) && (inner_s_idx == HALF_DEPTH -1) && (inner_A_idx == HALF_DEPTH -1))? 1:0;
            end
            
        end
    end

    
endmodule