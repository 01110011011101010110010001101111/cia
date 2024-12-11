`default_nettype none
module blind_rotation
 #(parameter BITMASK_SIZE = 32,
   parameter BRAM_MAX_SIZE = 100,
   parameter DATA_SIZE = 2)
  ( input wire                        clk_in,
    input wire                        rst_in,
    input wire   [BITMASK_SIZE-1:0]   rotation_amount,
    input wire   [$clog2(BRAM_MAX_SIZE)-1:0]  addr,
    input wire   [DATA_SIZE-1:0]      data_in, 
    input wire                        valid_data_in,
    output logic                      valid_data_out,
    output logic [$clog2(BRAM_MAX_SIZE)-1:0]  new_addr,
    output logic [DATA_SIZE-1:0]    data_out 
  );

  logic [DATA_SIZE-1:0] prev_data_in;
  logic [$clog2(BRAM_MAX_SIZE)-1:0] prev_addr_in;
  logic valid_prev_data_in;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        valid_prev_data_in <= 0;
        prev_data_in <= 0;
        valid_data_out <= 0;
    end else if (valid_data_in) begin

        // even -- shift back by rotation_amount / 2
        if (rotation_amount[0] == 0) begin
            new_addr <= addr - ((rotation_amount) >> 1) < 0 ? addr - ((rotation_amount) >> 1) + BRAM_MAX_SIZE : addr - ((rotation_amount) >> 1);
            data_out <= data_in;
            valid_data_out <= 1;

        // odd -- problem child
        end else begin
            if (valid_prev_data_in) begin
                // have the previous thing existent!
                // concat the bottom of the previous and the top of the new
                data_out <= { prev_data_in[(DATA_SIZE >> 1)-1:0], data_in[DATA_SIZE-1 : (DATA_SIZE >> 1)] };
                // shift over
                prev_data_in <= data_in;
                prev_addr_in <= addr;
                // output the new address
                new_addr <= prev_addr_in - ((rotation_amount+1) >> 1) < 0 ? prev_addr_in - ((rotation_amount+1) >> 1) + BRAM_MAX_SIZE : prev_addr_in - ((rotation_amount+1) >> 1);
                valid_data_out <= 1;
            end else begin
                // first time recieving data! let's save the previous data
                prev_data_in <= data_in;
                valid_prev_data_in <= 1;
                prev_addr_in <= addr;
                // nothing to output yet
                valid_data_out <= 0;
            end
        end
    end else begin
        valid_data_out <= 0;
    end

  end
endmodule
`default_nettype wire
