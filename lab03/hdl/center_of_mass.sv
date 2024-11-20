module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);
	 // your code here
     // logic [29:0] x_sum;
     // logic [29:0] y_sum;
     // logic [20:0] m_cnt;
     logic [31:0] x_sum;
     logic [31:0] y_sum;
     logic [31:0] m_cnt;
     logic valid_out_x;
     logic valid_out_y;
     logic error_out_x;
     logic error_out_y;
     logic rxo, ryo, bxo, byo;
     logic saw_valid_x, saw_valid_y;
     logic valid_div_x, valid_div_y;

     divider com_calculate_x(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(x_sum),
        .divisor_in(m_cnt),
        .data_valid_in(tabulate_in),
        .quotient_out(x_out),
        .remainder_out(rxo),
        .data_valid_out(valid_out_x),
        .error_out(error_out_x),
        .busy_out(bxo)
     );

     divider com_calculate_y(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(y_sum),
        .divisor_in(m_cnt),
        .data_valid_in(tabulate_in),
        .quotient_out(y_out),
        .remainder_out(ryo),
        .data_valid_out(valid_out_y),
        .error_out(error_out_y),
        .busy_out(byo)
     );

     always_ff @(posedge clk_in) begin
        if (rst_in) begin
            x_sum <= 0;
            y_sum <= 0;
            m_cnt <= 0;
            saw_valid_x <= 0;
            saw_valid_y <= 0;
            valid_div_x <= 0;
            valid_div_y <= 0;
        end else begin
            // x_out <= 640;
            // y_out <= 360;
            // valid_out <= 1;

            if (valid_in) begin
                x_sum <= x_sum + x_in;
                y_sum <= y_sum + y_in;
                m_cnt <= m_cnt + 1;
            end

            if (tabulate_in) begin
                valid_div_x <= 1;
                valid_div_y <= 1;
            end             

            if (((valid_out_x && !error_out_x) || saw_valid_x) && ((valid_out_y && !error_out_y) || saw_valid_y)) begin
                valid_out <= 1;
                saw_valid_x <= 0;
                saw_valid_y <= 0;
                x_sum <= 0;
                y_sum <= 0;
                m_cnt <= 0;
            end else begin
                valid_out <= 0;

                if (valid_out_x && !error_out_x) begin
                    saw_valid_x <= 1;
                    valid_div_x <= 0;
                end

                if (valid_out_y && !error_out_y) begin
                    saw_valid_y <= 1;
                    valid_div_y <= 0;
                end


                
            end

            // if (valid_out_x && !valid_out_y) begin
            //     saw_valid_x <= !error_out_x;
            //     valid_div_x <= 0;
            // end

            // if (valid_out_y && !valid_out_x) begin
            //     saw_valid_y <= !error_out_y;
            //     valid_div_y <= 0;
            // end

            // if (((valid_out_x && !error_out_x) || saw_valid_x) && ((valid_y && !error_out_y) || saw_valid_y)) begin
            //     // valid_out <= valid_out_x && valid_out_y && !error_out_y && !error_out_x;
            //     valid_out <= 1;
            //     saw_valid_y <= 0;
            //     saw_valid_x <= 0;
            //     x_sum <= 0;
            //     y_sum <= 0;
            //     m_cnt <= 0;
            // end else begin
            //     valid_out <= 0;
            // end

        end
     end
endmodule
