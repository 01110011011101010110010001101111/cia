`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );

  // TODO: module to read UART rx wire
  localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
  localparam HALF_BAUD_BIT_PERIOD = BAUD_BIT_PERIOD / 2;

  typedef enum {IDLE, START, DATA, STOP, TRANSMIT} trans_state;
  trans_state state;
  logic [7:0] inner_data = 0;
  logic [$clog2(BAUD_BIT_PERIOD):0] clk_counter = 0;
  logic [$clog2(HALF_BAUD_BIT_PERIOD):0] inner_clk_counter = 0;
  logic [5:0] data_counter = 0;



  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        // reset output vars
        new_data_out <= 0;
        data_byte_out <= 0;

        // TODO: reset internal vars
        clk_counter <= 0;
        inner_clk_counter <= 0;
        data_counter <= 0;
        state <= IDLE;
        inner_data <= 0;
    end else begin
        case (state) 
            IDLE: begin
                // only trigger when we see a 0
                if (rx_wire_in == 0) begin
                    state <= START;
                    inner_clk_counter <= 0;
                    clk_counter <= 0;
                    inner_data <= 0;
                end
            end START: begin
                // we can read it
                if (inner_clk_counter + 1 == HALF_BAUD_BIT_PERIOD) begin
                    inner_clk_counter <= 0;
                    if (rx_wire_in == 0) begin
                        // expected, proceed
                        state <= DATA;
                        clk_counter <= 0;
                    end else begin
                        // bad input...
                        state <= IDLE;
                        clk_counter <= 0;
                    end
                end else begin
                    inner_clk_counter <= inner_clk_counter + 1;
                end
            end DATA: begin
                if (clk_counter + 1 == BAUD_BIT_PERIOD) begin
                    // read the bit, reset
                    // inner_data[7 - data_counter] <= rx_wire_in;
                    inner_data[data_counter] <= rx_wire_in;
                    clk_counter <= 0;

                    // move on if needed
                    if (data_counter+1 == 8) begin
                        state <= STOP;
                        data_counter <= 0;
                    end else begin
                        state <= DATA;
                        data_counter <= data_counter + 1;
                    end
                end else begin
                    clk_counter <= clk_counter + 1;
                end
                
            end STOP: begin
                if (clk_counter + 1 == BAUD_BIT_PERIOD) begin
                    clk_counter <= 0;
                    if (rx_wire_in == 1) begin
                        // yay it works!!
                        state <= TRANSMIT;
                        data_byte_out <= inner_data;
                        new_data_out <= 1;
                    end else begin
                        // nooo, we messed up
                        inner_data <= 0;
                        state <= IDLE;
                    end
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end TRANSMIT: begin
                new_data_out <= 0;
                state <= IDLE;
            end default: begin
                // should never be here...
                state <= IDLE;
            end
        endcase
     end
  end



endmodule // uart_receive

`default_nettype wire
