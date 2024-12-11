`default_nettype none
module blind_rotation
 #(parameter Q_PARAM = 1,
   parameter W_PARAM = 32,
   parameter BITMASK_SIZE = 32,
   parameter BRAM_MAX_SIZE = 100)
  ( input wire                        clk_in,
    input wire                        rst_in,
    input wire   [BITMASK_SIZE-1:0]   rotation_amount,
    input wire   [$clog2(BRAM_MAX_SIZE)-1:0]  addr,
    input wire                        valid_data_in,
    output logic                      valid_data_out,
    output logic [$clog2(BRAM_MAX_SIZE)-1:0]  new_addr,
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
       new_addr <= addr - rotation_amount < 0 ? addr - rotation_amount + BRAM_MAX_SIZE : addr - rotation_amount;
       valid_data_out <= 1;
       // integer i;
       // for (i = 0; i < BITMASK_SIZE; i = i + 1) begin
       //    
       // end
    end else begin
        valid_data_out <= 0;
    end

  end
endmodule
`default_nettype wire
