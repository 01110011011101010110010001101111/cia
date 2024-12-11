`default_nettype none
module sample_extraction
 #(parameter H_PARAM = 1,
   parameter K_PARAM = 1,
   parameter N_PARAM = 1,
   parameter BRAM_DEPTH = 100,
   parameter ADDR_SIZE = 32,
   parameter VALUE_SIZE = 32)
  ( input wire                        clk_in,
    input wire                        rst_in,
    input wire   [VALUE_SIZE-1:0]   value,
    input wire   [ADDR_SIZE-1:0]  addr,
    input wire                        valid_data_in,
    output logic                      valid_data_out,
    // new addr is k * N
    output logic [($clog2(K_PARAM * N_PARAM) + ADDR_SIZE)-1:0]  new_addr,
    output logic [VALUE_SIZE-1:0]    data_out 
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        valid_data_out <= 0;
    end else if (valid_data_in) begin
        if (addr_y <= H_PARAM) begin
            new_addr <= H_PARAM - addr;
            data_out <= value;
        end else begin
            new_addr <= H_PARAM - addr + N_PARAM;
            data_out <= value;
        end
        valid_data_out <= 1;
    end else begin
        valid_data_out <= 0;
    end

  end
endmodule
`default_nettype wire
