`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`define FPATH(X) `"../data/X`"

module top_level
(
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic [15:0] led, //16 green output LEDs (located right above switches)
   output logic [2:0]  rgb0, //RGB channels of RGB LED0
   output logic [2:0]  rgb1, //RGB channels of RGB LED1
   output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
   input wire 				 uart_rxd, // UART computer-FPGA
   output logic 			 uart_txd // UART FPGA-computer
);

   parameter BAUD_RATE = 100_000; // 115_200;
   parameter MAX_COUNT = 150_000; // reading all 100k 

   //shut up those rgb LEDs for now (active high):
   assign rgb1 = 0; //set to 0.
   assign rgb0 = 0; //set to 0.
   assign led = 0;

   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];

    logic [7:0]                uart_data_in;
    logic                      uart_busy;
    logic [$clog2(MAX_COUNT)-1:0] total;
    logic [$clog2(MAX_COUNT)-1:0] total_count;
 
    // Checkoff 2: leave this stuff commented until you reach the second checkoff page!
    // Synchronizer
    // TODO: pass your uart_rx data through a couple buffers,
    // save yourself the pain of metastability!
    logic                      uart_rx_buf0, uart_rx_buf1;
 
    // UART Receiver
    // TODO: instantiate your uart_receive module, connected up to the buffered uart_rx signal
    // declare any signals you need to keep track of!
 
    logic [7:0] data_byte_out;
    logic [31:0] data_byte_out_buf;
    logic new_data_out;
    logic new_data_out_3;
    logic new_data_out_buf;
 
    uart_receive
    #(   .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
         .BAUD_RATE(BAUD_RATE)
    )my_uart_receive
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .rx_wire_in(uart_rx_buf1),
      .new_data_out(new_data_out),
      .data_byte_out(data_byte_out)
     );

    logic [6:0] ss_c; //used to grab output cathode signal for 7s leds
    logic [7:0] msg_byte;
    seven_segment_controller mssc(.clk_in(clk_100mhz),
                                  .rst_in(sys_rst),
                                  .val_in(sw[15] ? total_count : total),
                                  .cat_out(ss_c),
                                  .an_out({ss0_an, ss1_an}));

    assign ss0_c = ss_c; //control upper four digit's cathodes!
    assign ss1_c = ss_c; //same as above but for lower four digits!
 
    logic valid_data;
    logic valid_data_buf;
    // logic uart_busy = 0;
    // logic uart_data_valid;

    parameter BRAM_WIDTH = 8; // 32;
    parameter BRAM_DEPTH = 150_000; // 1 + 25_250;
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);

    logic [7:0] transmit_byte;

    xilinx_true_dual_port_read_first_2_clock_ram
      #(.RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE")) audio_bram
        // .INIT_FILE(`FPATH(inc.mem))) audio_bram
        (
         // PORT A
         .addra(total_count), // sw[14:0]),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(transmit_byte),
         // PORT B
         .addrb(total),
         .dinb(data_byte_out),
         .clkb(clk_100mhz),
         .web(new_data_out), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
         );

    logic uart_data_valid;
 
    uart_transmit
    #(  .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
        .BAUD_RATE(BAUD_RATE)
    )my_uart_transmit
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_byte_in(transmit_byte),
      .trigger_in(uart_data_valid),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
    );
 

    always_ff @(posedge clk_100mhz)begin
     if (sys_rst) begin
        total_count <= 0;
     end else begin
         uart_rx_buf0 <= uart_rxd;
         uart_rx_buf1 <= uart_rx_buf0;

         if (sw[15]) begin
           if (!uart_busy) begin
             uart_data_valid <= 1;
             total_count <= total_count + 1;
           end 
           // else begin
           //   uart_data_valid <= 0;
           // end
         end else begin
            total_count <= 0;
            uart_data_valid <= 0;
         end

     end
   end
 
   evt_counter #(.MAX_COUNT(MAX_COUNT)) port_b_counter(
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .evt_in(new_data_out),
        .count_out(total));
 

endmodule // top_level

`default_nettype wire


// `default_nettype none // prevents system from inferring an undeclared logic (good practice)
// 
// `define FPATH(X) `"../data/X`"
// 
// module top_level
// (
//    input wire          clk_100mhz, //100 MHz onboard clock
//    input wire [15:0]   sw, //all 16 input slide switches
//    input wire [3:0]    btn, //all four momentary button switches
//    output logic [15:0] led, //16 green output LEDs (located right above switches)
//    output logic [2:0]  rgb0, //RGB channels of RGB LED0
//    output logic [2:0]  rgb1, //RGB channels of RGB LED1
//    output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
//    output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
//    output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
//    output logic [6:0] ss1_c, //cathode controls for the segments of lower four digits
//    input wire 				 uart_rxd, // UART computer-FPGA
//    output logic 			 uart_txd // UART FPGA-computer
// );
// 
//     parameter BAUD_RATE = 115_200;
// 
//     //shut up those rgb LEDs for now (active high):
//     assign rgb1 = 0; //set to 0.
//     assign rgb0 = 0; //set to 0.
//     assign led = 0;
// 
//     //have btnd control system reset
//     logic               sys_rst;
//     assign sys_rst = btn[0];
// 
// 
//     logic uart_rx_buf0, uart_rx_buf1;
//     logic [7:0] msg_byte;
//     logic valid_data;
//     logic valid_data_buf;
//     logic uart_busy = 0;
//     logic uart_data_valid;
// 
//     parameter BRAM_WIDTH = 8; // 32;
//     parameter BRAM_DEPTH = 100_000; // 1 + 25_250;
//     parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
// 
//     logic [ADDR_WIDTH-1:0] total_count;
// 
//     xilinx_true_dual_port_read_first_2_clock_ram
//       #(.RAM_WIDTH(BRAM_WIDTH),
//         .RAM_DEPTH(BRAM_DEPTH),
//         .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
//         .INIT_FILE(`FPATH(inc.mem))) audio_bram
//         (
//          // PORT A
//          .addra(100),
//          .dina(0), // we only use port A for reads!
//          .clka(clk_100mhz),
//          .wea(1'b0), // read only
//          .ena(1'b1),
//          .rsta(sys_rst),
//          .regcea(1'b1),
//          .douta(msg_byte),
//          // PORT B
//          .addrb(),
//          .dinb(),
//          .clkb(clk_100mhz),
//          .web(), // write always
//          .enb(1'b1),
//          .rstb(sys_rst),
//          .regceb(1'b1),
//          .doutb() // we only use port B for writes!
//          );
// 
//     pipeline #(
//       .BITS(1),
//       .STAGES(2)
//     )new_data_out_pipeline (
//         .clk_in(clk_100mhz),
//         .rst_in(sys_rst),
//         .data_in(uart_data_valid),
//         .data_out(valid_data_buf)
//     );
// 
//     uart_transmit
//     #(  .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
//         .BAUD_RATE(BAUD_RATE)
//     )my_uart_transmit
//     ( .clk_in(clk_100mhz),
//       .rst_in(sys_rst),
//       .data_byte_in(msg_byte),
//       .trigger_in(valid_data_buf),
//       .busy_out(uart_busy),
//       .tx_wire_out(uart_txd)
//     );
//  
//     always_ff @(posedge clk_100mhz)begin
//       if (sys_rst) begin
//          total_count <= 0;
//          uart_data_valid <= 0;
//       end else begin
//          if (sw[0]) begin
//             if (!uart_busy) begin
//                 total_count <= total_count + 1;
//                 uart_data_valid <= 1;
//             end else begin
//                 uart_data_valid <= 0;
//             end
//          end else begin
//             uart_data_valid <= 0;
//          end
//       end
//     end
// 
// 
// 
// endmodule // top_level
// 
// `default_nettype wire
