`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );
   
      // TODO: module to transmit on UART
      localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
      logic [9:0] data_formatted_in = 10'b1_0000_0000_0;
      // count 0-9
      logic [5:0] data_counter = 0;
      logic [$clog2(BAUD_BIT_PERIOD):0] clk_counter = 0;
   
      always_ff @(posedge clk_in) begin
        if (rst_in) begin
            // RESET OUTPUTS
            // high on reset when no data
            tx_wire_out <= 1;
            // not busy any more
            busy_out <= 0;
            // RESET INTERNAL FUNCTIONS
            data_formatted_in <= 10'b1_0000_0000_0;
            data_counter <= 0;
            clk_counter <= 0;
        end else begin
            // trigger_in when we're NOT busy
            if (!busy_out && trigger_in) begin
                busy_out <= 1;
                tx_wire_out <= 0;
                data_formatted_in[8:1] <= data_byte_in;
                // init a counter to go in REVERSE ORDER
                data_counter <= 0;
            // we're in the middle of transmitting...
            end else if (busy_out) begin
                // TODO
                // NOTE: MAY NEED TO ADD ONE HERE
                if (clk_counter+1 == BAUD_BIT_PERIOD) begin
                    if (data_counter == 9) begin
                        // we're done!
                        busy_out <= 0;
                        data_counter <= 0;
                        clk_counter <= 0;
                        data_formatted_in <= 10'b1_0000_0000_0;
                        tx_wire_out <= 1;
                    end else begin
                        data_counter <= data_counter + 1;
                        clk_counter <= 0;
                    end
                end else begin
                    // increment clock
                    clk_counter <= clk_counter + 1;
                    tx_wire_out <= data_formatted_in[data_counter];
                end
            end
        end
      end
endmodule // uart_transmit

`default_nettype wire
