`default_nettype none
module compress_4
  ( input wire          clk_in,
    input wire          rst_in,
    input wire          valid_data_in,
    input wire [7:0]   data_in, 
    output logic         valid_data_out,
    output logic[31:0]   data_out 
  );
  logic [31:0] four_bytes;
  logic [1:0] count_out = 0;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      four_bytes <= 32'b0;
      count_out <= 0;
      valid_data_out <= 0;
    end else if (valid_data_in) begin
        case (count_out)
            2'b00: begin
                // four_bytes[31:24] <= data_in;
                four_bytes[7:0] <= data_in;
                count_out <= 2'b01;
                valid_data_out <= 0;
            end
            2'b01: begin
                // four_bytes[23:16] <= data_in;
                four_bytes[15:8] <= data_in;
                count_out <= 2'b10;
                valid_data_out <= 0;
            end
            2'b10: begin
                // four_bytes[15:8] <= data_in;
                four_bytes[23:16] <= data_in;
                count_out <= 2'b11;
                valid_data_out <= 0;
            end
            2'b11: begin
                // four_bytes[7:0] <= data_in;
                // data_out <= {four_bytes[31:8], data_in};
                data_out <= {data_in, four_bytes[23:0]};
                valid_data_out <= 1;
                four_bytes <= 0;
                count_out <= 2'b00;
            end
            default: begin
                valid_data_out <= 0;
            end
        endcase
    end else begin
        valid_data_out <= 0;
    end
  end
endmodule
`default_nettype wire
