`default_nettype none
module modulus_switching
 #(parameter Q_PARAM = 1,
   parameter W_PARAM = 32,
   parameter B_SIZE_BITS = 32)
  ( input wire                        clk_in,
    input wire                        rst_in,
    input wire   [B_SIZE_BITS-1:0]    b_val,
    input wire                        valid_data_in,
    output logic                      valid_data_out,
    output logic [B_SIZE_BITS-1:0]    data_out 
  );

  parameter W_DIV_Q = $clog2(W_PARAM / Q_PARAM);

  logic [31:0] four_bytes;
  logic [1:0] count_out = 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      four_bytes <= 32'b0;
      count_out <= 0;
    end else if (valid_data_in) begin
        data_out <= b_val << W_DIV_Q;
        valid_data_out <= 1;
    end else begin
        valid_data_out <= 0;
    end
  end
endmodule
`default_nettype wire
