module rgb_controller(   input wire clk_in,
              input wire rst_in,
              input wire [7:0] r_in,
              input wire [7:0] g_in,
              input wire [7:0] b_in,
              output logic r_out,
              output logic g_out,
              output logic b_out);

    // assign r_out = 1;
    // assign g_out = 1;
    // assign b_out = 1;

     pwmnew mcr (.clk_in(clk_in),
                .rst_in(rst_in),
                .dc_in(r_in),
                .sig_out(r_out));

     pwmnew mcg (.clk_in(clk_in),
                .rst_in(rst_in),
                .dc_in(g_in),
                .sig_out(g_out));

     pwmnew mcb (.clk_in(clk_in),
                .rst_in(rst_in),
                .dc_in(b_in),
                .sig_out(b_out));

endmodule
