`timescale 1ns / 1ps
`default_nettype none

module divider (input wire clk_in,
                input wire rst_in,
                input wire[15:0] dividend_in,
                input wire[15:0] divisor_in,
                input wire data_valid_in,
                output logic[15:0] quotient_out,
                output logic[15:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);

  typedef enum {IDLE, DIVIDING, RESULT} div_state;

  div_state state;

  logic [15:0] dividend, divisor, quotient;

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      quotient_out <= 0;
      remainder_out <= 0;
      data_valid_out <= 0;
      error_out <= 0;
      busy_out <= 0;
      quotient <= 0;
      dividend <= 0;
      divisor <= 0;
      busy_out <= 0;
      data_valid_out <= 0;
    end else begin
      case (state)
        IDLE: begin
          if (data_valid_in)begin
            if (divisor_in==0)begin //exit early
              quotient_out <= 0;
              remainder_out <= 0;
              data_valid_out <= 1;
              error_out <= 1;
              busy_out <= 0;
              state <= IDLE;
            end else begin
              dividend <= dividend_in;
              quotient <= 0;
              divisor <= divisor_in;
              state <= DIVIDING;
              busy_out <= 1;
              data_valid_out <= 0;
            end
          end else begin
            data_valid_out <= 0;
          end
        end DIVIDING: begin
          if (dividend >= divisor)begin
            dividend <= dividend-divisor;
            quotient <= quotient +1;
          end else begin
            state <= RESULT;
          end
        end RESULT: begin
          quotient_out <= quotient;
          remainder_out <= dividend;
          data_valid_out <= 1;
          error_out <= 0;
          busy_out <= 0;
          state <= IDLE;
        end default: begin
          state <= IDLE;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
