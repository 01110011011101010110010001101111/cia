`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 
  //your code here.
  logic [4:0] tally;
  logic [5:0] n1, n0;
  logic [2:0] path;
  logic less_than_0;
  logic condition_2;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        tally <= 0;
        tmds_out <= 0;
    end else if (ve_in) begin
        // n1 <= data_in[0] + data_in[1] + data_in[2] + data_in[3] + data_in[4] + data_in[5] + data_in[6] + data_in[7];
        n1 <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        n0 <= 8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
        less_than_0 <= tally < 0;
        condition_2 <= (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])) > (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
        // tally == 0 || n1 == n0
        if (tally == 0 || (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]) == (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]))) begin
        // if (prev_count == 0 || n1 == n0) begin
            tmds_out[9] <= ~q_m[8];
            tmds_out[8] <= q_m[8];
            tmds_out[7:0] <= q_m[8] ? q_m[7:0] : ~q_m[7:0];

            if (q_m[8] == 0) begin
                path <= 0;
                // tally + (n0 - n1)
                tally <= tally + ((8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])) - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]));
                // tally <= prev_count + (n0 - n1);
            end else begin
                path <= 1;
                // tally + (n1 - n0)
                // prev_count <= tally;
                tally <= tally + ((q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]) - (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])));
                // tally <= prev_count + (n1 - n0);
            end
        end else begin
            // tally > 0 && n1 > n0 || tally < 0 && n0 > n1
            if (
                ((tally[4] == 0 && tally != 0) && (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]) > (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]))) || 
                (tally[4] == 1 && (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])) > (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]))
            ) begin
            // if ((prev_count > 0 && (n1 > n0)) || (tally < 0 && n0 > n1)) begin
                path <= 2;
                tmds_out[9] = 1;
                tmds_out[8] = q_m[8];
                tmds_out[7:0] = ~q_m[7:0];
                // talyy = tally + (q_m[8] == 1 ? 2 : 0) + (n0 - n1)
                // prev_count <= tally;
                tally <= tally + (q_m[8] == 1 ? 2 : 0) + ((8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])) - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]));
                // tally <= tally + (q_m[8] == 1 ? 2 : 0) + (n0 - n1);
            end else begin
                path <= 3;
                tmds_out[9] = 0;
                tmds_out[8] = q_m[8];
                tmds_out[7:0] = q_m[7:0];
                // tally = tally + (q_m[8] == 1 ? -2 : 0) + (n1 - n0)
                // tally <= tally + (q_m[8] == 0 ? -2 : 0) + (n1 - n0);
                tally <= tally + (q_m[8] == 0 ? -2 : 0) + ((q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]) - (8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7])));
            end
        end
    end else begin
        tally <= 0;
        case (control_in)
            2'b00: tmds_out <= 10'b1101010100;
            2'b01: tmds_out <= 10'b0010101011;
            2'b10: tmds_out <= 10'b0101010100;
            2'b11: tmds_out <= 10'b1010101011;
            default: tmds_out <= 10'b0; // ERROR
        endcase
    end
  end
 
endmodule
 
`default_nettype wire
