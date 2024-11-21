module enc_addr_looper
    #(parameter DEPTH=100, parameter K=500)
    (input wire clk_in,
                    input wire rst_in,
                    input wire begin_enc,
                    output logic [9:0] A_addr,
                    output logic [9:0] s_addr,
                    output logic [9:0] b_addr,
                    output logic [9:0] e_addr,
                    output logic e_zero,
                    output logic addr_valid
              );

  /*
    e_zero describes if e term put into b adder should just be 0
  */

    logic [5:0] inner_s_idx;
    logic [5:0] inner_A_idx;
    logic [6:0] outer_k_idx;

    evt_counter #(.MAX_COUNT(DEPTH/2)) inner_s_loop(
         .clk_in(clk_in),
         .rst_in(begin_enc),
         .evt_in(clk_in),
         .count_out(inner_s_idx));

    evt_counter #(.MAX_COUNT(DEPTH/2)) inner_A_loop(
         .clk_in(clk_in),
         .rst_in(begin_enc),
         .evt_in((inner_s_idx == DEPTH/2 -1)),
         .count_out(inner_A_idx));

    evt_counter #(.MAX_COUNT(K)) outer_k_loop(
         .clk_in(clk_in),
         .rst_in(begin_enc),
         .evt_in((inner_s_idx == DEPTH/2 -1) && (inner_A_idx == DEPTH/2 -1)),
         .count_out(outer_k_idx));

    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            A_addr <= 0;
            s_addr <= 0;
            e_addr <= 0;
            b_addr <= 0;
            addr_valid <= 0;
        end else if (begin_enc) begin
            addr_valid <= 1;
        end else begin
            A_addr <= outer_k_idx * DEPTH>>1 + inner_A_idx;
            s_addr <= outer_k_idx * DEPTH>>1 + inner_s_idx;
            b_addr <= (inner_A_idx + inner_s_idx >= DEPTH>>1) ? 0: inner_A_idx + inner_s_idx;
            e_addr <= inner_s_idx;
            e_zero <= inner_A_idx == 0 && outer_k_idx == 0;
        end
    end

    
endmodule