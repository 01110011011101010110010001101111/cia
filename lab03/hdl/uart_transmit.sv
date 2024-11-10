module uart_transmit #(parameter INPUT_CLOCK_FREQ = 100000000,
parameter BAUD_RATE = 19200)
(
    input wire clk_in,
    input wire rst_in,
    input wire[7:0] data_byte_in,
    input wire trigger_in,
    output logic busy_out,
    output logic tx_wire_out
);
localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
localparam BAUD_BP_WIDTH = $clog2(BAUD_BIT_PERIOD);
logic[BAUD_BP_WIDTH-1:0] clock_counter;
logic start;
logic[4:0] curr_bit;
logic[7:0] store_data_in;

always_ff @(posedge clk_in) begin
    if(rst_in) begin
        busy_out <= 0;
        tx_wire_out <= 1;
        start <= 0;
        curr_bit <= 0;
        store_data_in <= 0;
        clock_counter <= 0;
    end else if (!start && trigger_in) begin
        busy_out <= 1;
        start <= 1;
        store_data_in <= data_byte_in;
        tx_wire_out <= 0;
        clock_counter <= 0;
        curr_bit <= 0;
    end else if (start) begin
        if(clock_counter == BAUD_BIT_PERIOD-1) begin
            if (curr_bit < 8) begin
                tx_wire_out <= store_data_in[curr_bit];
                curr_bit <= curr_bit + 1;
            end else if (curr_bit == 8) begin
                curr_bit <= 9;
                tx_wire_out <= 1;
            end else if (curr_bit == 9) begin
                busy_out <= 0;
                curr_bit <= 0;
                start <= 0;
                tx_wire_out <= 1;
            end else begin
                curr_bit <= 0;
                tx_wire_out <= 1;
            end
            clock_counter <= 0;
        end else begin
            clock_counter <= clock_counter+1;
        end
    end else begin
    end
end

endmodule