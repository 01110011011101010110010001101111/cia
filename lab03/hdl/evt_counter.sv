`default_nettype none
module evt_counter
 #(parameter MAX_COUNT = 100)
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          evt_in,
    output logic[$clog2(MAX_COUNT):0]  count_out
  );
 
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      count_out <= 0;
    end else if (evt_in) begin
      /* your code here */
      count_out <= count_out + 1 == MAX_COUNT ? 0 : count_out + 1;
    end
  end
endmodule
`default_nettype wire
