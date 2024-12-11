`default_nettype none
module modulus_switching
 #(parameter Q_PARAM = 16,
   parameter W_PARAM = 4)
  ( input wire                        clk_in,
    input wire                        rst_in,
    input wire   [$clog2(Q_PARAM)+$clog2(Q_PARAM)-1:0]    b_val,
    input wire                        valid_data_in,
    output logic                      valid_data_out,
    output logic [$clog2(W_PARAM)+$clog2(W_PARAM)-1:0]    data_out 
  );

  /**
   * Change some input b_val from mod q to mod w where p < w < q
   * 
   * Assumes that b_val is compacted into 2 log2(q) values: [ val1  val2 ]
   */

  parameter Q_DIV_W = $clog2(Q_PARAM) - $clog2(W_PARAM);

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        valid_data_out <= 0;
        data_out <= 0;
    end else if (valid_data_in) begin
        // pack the two
        data_out[W_PARAM-1:0] <= (b_val[Q_PARAM-1:0] >> Q_DIV_W);
        data_out[W_PARAM+W_PARAM-1:W_PARAM] <= (b_val[Q_PARAM+Q_PARAM-1:Q_PARAM] >> Q_DIV_W);
        valid_data_out <= 1;
    end else begin
        valid_data_out <= 0;
    end
  end
endmodule
`default_nettype wire
