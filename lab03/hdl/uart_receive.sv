module uart_receive #(parameter INPUT_CLOCK_FREQ = 100000000,
parameter BAUD_RATE = 19200)
(
    input wire clk_in,
    input wire rst_in,
    input wire rx_wire_in,
    output logic new_data_out,
    output logic [7:0] data_byte_out
);
localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
localparam BAUD_BP_WIDTH = $clog2(BAUD_BIT_PERIOD);
localparam HALF_BAUD_BP = BAUD_BIT_PERIOD/2;
logic[BAUD_BP_WIDTH-1:0] clock_counter;
logic start;
logic[4:0] curr_bit;

always_ff @(posedge clk_in) begin
    if(rst_in) begin
        curr_bit <= 0;
        new_data_out <= 0;
        data_byte_out <= 0;
        clock_counter <= 0;
        start <= 0;
    end else if (!start && !rx_wire_in) begin
        start <= 1;
        curr_bit <= 0;
        clock_counter <= 1;
        new_data_out <= 0;
    end else if (start) begin
        if(clock_counter == HALF_BAUD_BP) begin
            if (curr_bit == 0) begin
                if(rx_wire_in == 0) begin
                    curr_bit <= curr_bit + 1;
                end else begin
                    start <= 0;
                    new_data_out <= 0;
                    curr_bit <= 0;
                end
            end else if (curr_bit < 9) begin
                data_byte_out[curr_bit-1] <= rx_wire_in;
                curr_bit <= curr_bit + 1;
            end else if (curr_bit == 9) begin
                if(rx_wire_in == 1) begin
                    new_data_out <= 1;
                    curr_bit <= 0;
                    start <= 0;
                    clock_counter <= 0;
                end else begin
                    start <= 0;
                    new_data_out <= 0;
                    curr_bit <= 0;
                end
            end else begin
            end
            clock_counter <= clock_counter+1;
        end else if (clock_counter == BAUD_BIT_PERIOD-1) begin
            clock_counter <= 0;
        end else begin
            clock_counter <= clock_counter+1;
        end
    end else if (new_data_out) begin
        new_data_out <= 0;
    end else begin
    end
end

endmodule