module nn_addr_looper
    #(parameter DEPTH=100, parameter K=502, parameter NN_OUT = 10, parameter BOOTSTRAP = 10)
    (input wire clk_in,
                    input wire rst_in,
                    input wire begin_nn,
                    output logic [9:0] outer_N_out,
                    output logic [7:0] outer_k_out,
                    output logic [5:0] nn_out,
                    output logic [16:0] A_addr,
                    output logic [16:0] nn_addr,
                    output logic [12:0] b_addr,
                    output logic addr_valid,
                    output logic done
              );

  /*
    e_zero describes if e term put into b adder should just be 0
  */

    localparam HALF_K = K/2;

    logic bootstrap; // False if not in bootstrapping stage

    logic [5:0] inner_nn_idx;
    logic [7:0] inner_k_idx;
    logic [9:0] outer_N_idx;
    logic [9:0] bootstrap_idx;

    evt_counter #(.MAX_COUNT(NN_OUT)) inner_nn_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in(begin_nn && ~bootstrap),
         .count_out(inner_nn_idx));

    evt_counter #(.MAX_COUNT(HALF_K)) inner_k_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in((inner_nn_idx == NN_OUT -1) && ~bootstrap),
         .count_out(inner_k_idx));

    evt_counter #(.MAX_COUNT(DEPTH)) outer_N_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in((inner_nn_idx == NN_OUT -1) && (inner_k_idx == HALF_K -1) && ~bootstrap),
         .count_out(outer_N_idx));

    evt_counter #(.MAX_COUNT(BOOTSTRAP)) bootstrap_loop(
         .clk_in(clk_in),
         .rst_in(rst_in),
         .evt_in(bootstrap && begin_nn),
         .count_out(bootstrap_idx));

    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            A_addr <= 0;
            nn_addr <= 0;
            b_addr <= 0;
            addr_valid <= 0;
            done <= 0;
            bootstrap <= 0;
        end else begin
            if(done)begin
                addr_valid <= 0;
            end else begin
                if(bootstrap) begin
                    addr_valid <= (bootstrap_idx == BOOTSTRAP-1)? 1:0;
                    bootstrap <= (bootstrap_idx == BOOTSTRAP-1)? 0:1;
                end else begin
                    // TODO: if this fails on first on means addr_valid needs correction
                    if (outer_N_idx[1:0] == 2'b11 && inner_nn_idx == 0 && inner_k_idx == 0) begin
                        bootstrap <= 1;
                        addr_valid <= 0;
                    end else begin
                        addr_valid <= addr_valid?(((inner_k_idx == HALF_K -1) && (inner_nn_idx == NN_OUT -1) && (outer_N_idx == DEPTH-1))? 0:1 ):begin_nn;
                    end

                    A_addr <= (outer_N_idx * (HALF_K)) + inner_k_idx; // add 1 to everything???
                    nn_addr <= (outer_N_idx * (NN_OUT)) + inner_nn_idx;
                    b_addr <= inner_nn_idx*HALF_K + inner_k_idx;

                    outer_N_out <= outer_N_idx;
                    outer_k_out <= inner_k_idx;
                    nn_out <= inner_nn_idx;
                    done <= ((inner_k_idx == HALF_K -1) && (inner_nn_idx == NN_OUT -1) && (outer_N_idx == DEPTH-1))? 1:0;
                end
                
            end
            
        end
    end

    
endmodule