`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module image_sprite #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [7:0] red_out,
  output logic [7:0] green_out,
  output logic [7:0] blue_out
  );

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic in_sprite;
  // assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
  //                     (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));
  assign in_sprite = ((hcount_pipe[4-1] >= x_pipe[4-1] && hcount_pipe[4-1] < (x_pipe[4-1] + WIDTH)) &&
                      (vcount_pipe[4-1] >= y_pipe[4-1] && vcount_pipe[4-1] < (y_pipe[4-1] + HEIGHT)));



  logic [7:0] tmp_out;
  logic [23:0] rgb_out;

  // TODO: DO THIS PIPELINE BY 4

  // Modify the module below to use your BRAMs!
  assign red_out =    in_sprite ? rgb_out[23:16] : 0;
  assign green_out =  in_sprite ? rgb_out[15:8] : 0;
  assign blue_out =   in_sprite ? rgb_out[7:0] : 0;

  logic [10:0] hcount_pipe [4-1:0];
  logic [9:0] vcount_pipe [4-1:0];
  logic [10:0] x_pipe [4-1:0];
  logic [9:0] y_pipe [4-1:0];

  always_ff @(posedge pixel_clk_in)begin
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;
    x_pipe[0] <= x_in;
    y_pipe[0] <= y_in;
    for (int i=1; i<4; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      x_pipe[i] <= x_pipe[i-1];
      y_pipe[i] <= y_pipe[i-1];
    end
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(WIDTH * HEIGHT), // 256*256                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_ram (
    // TODO
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    // TODO
    .douta(tmp_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(24),                       // Specify RAM data width
    .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) palette_ram (
    // TODO
    .addra(tmp_out),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    // TODO
    .douta(rgb_out)      // RAM output data, width determined from RAM_WIDTH
  );



endmodule






`default_nettype none

