`default_nettype none

module pipeline #(
  parameter BITS = 16,
  parameter STAGES = 5
) (
  input wire clk_in, //system clock
  input wire rst_in, //system reset

  input wire [BITS-1:0] data_in, //current hcount being read
  output logic [BITS-1:0] data_out //current vcount being read
);
   logic [BITS-1:0] hcount_pipe [STAGES-1:0];

   always_ff @(posedge clk_in)begin
    if (rst_in) begin
        for (int i=1; i<STAGES; i = i+1)begin
            hcount_pipe[i] <= 0;
        end
        data_out <= 0;
    end else begin
        hcount_pipe[0] <= data_in;
        for (int i=1; i<STAGES-1; i = i+1)begin
          hcount_pipe[i] <= hcount_pipe[i-1];
        end
        if (STAGES > 1) begin
           data_out <= hcount_pipe[STAGES-2];
        end else begin
           data_out <= data_in;
        end
    end
   end

endmodule

`default_nettype wire
