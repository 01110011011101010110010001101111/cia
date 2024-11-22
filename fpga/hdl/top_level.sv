`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level
(
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic [15:0] led, //16 green output LEDs (located right above switches)
   output logic [2:0]  rgb0, //RGB channels of RGB LED0
   output logic [2:0]  rgb1, //RGB channels of RGB LED1
   input wire 				 uart_rxd, // UART computer-FPGA
   output logic 			 uart_txd // UART FPGA-computer
);

   //shut up those rgb LEDs for now (active high):
   assign rgb1 = 0; //set to 0.
   assign rgb0 = 0; //set to 0.
   assign led = 0;

   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];

   // these don't need to be 8-bit but uhhhh yes
   // each is 1 << q or 1 << p
   logic [7:0] q = 16;
   logic [7:0] p = 10;

   // Checkoff 1: Microphone->SPI->UART->Computer

    // 8kHz trigger using a week 1 counter!

    // TODO: set this parameter to the number of clock cycles between each cycle of an 8kHz trigger
    localparam CYCLES_PER_TRIGGER = 12500; // MUST CHANGE
 
    // logic [31:0]        trigger_count;
    // logic               spi_trigger;
 
 /*
    counter counter_8khz_trigger
      (.clk_in(clk_100mhz),
       .rst_in(sys_rst),
       .period_in(CYCLES_PER_TRIGGER),
       .count_out(trigger_count));
 */

/*
    // Line out Audio
    logic [7:0]                line_out_audio;
 
    // for checkoff 1: pass-through the audio sample we captured from SPI!
    // also, make the value much much smaller so that we don't kill our ears :)
    assign line_out_audio = 1;
 
    logic                      spk_out;
    // TODO: instantiate a pwm module to drive spk_out based on the
    pwmnew mcr (.clk_in(clk_100mhz),
               .rst_in(sys_rst),
               .dc_in(douta),
               .sig_out(spk_out));
*/
 
    // Data Buffer SPI-UART
    // TODO: write some sequential logic to keep track of whether the
    //  current audio_sample is waiting to be sent,
    //  and to set the uart_transmit inputs appropriately.
    //  **be sure to only ever set uart_data_valid high if sw[0] is on,
    //  so we only send data on UART when we're trying to receive it!
    // logic                      audio_sample_waiting = 0;
 
    logic [7:0]                uart_data_in;
    logic                      uart_data_valid;
    logic                      uart_busy;
 
    // Checkoff 2: leave this stuff commented until you reach the second checkoff page!
    // Synchronizer
    // TODO: pass your uart_rx data through a couple buffers,
    // save yourself the pain of metastability!
    logic                      uart_rx_buf0, uart_rx_buf1;
 
    // UART Receiver
    // TODO: instantiate your uart_receive module, connected up to the buffered uart_rx signal
    // declare any signals you need to keep track of!
 
    logic [7:0] data_byte_out;
    logic new_data_out;
    logic new_data_out_buf;
 
    uart_receive
    #(   .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
        .BAUD_RATE(115_200)
    )my_uart_receive
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .rx_wire_in(uart_rx_buf1),
      .new_data_out(new_data_out),
      .data_byte_out(dinb)
     );

 
    // UART Transmitter to FTDI2232
    // TODO: instantiate the UART transmitter you just wrote, using the input signals from above.
 
    logic trig_trans = 0;
    logic inc_trans = 0;

    uart_transmit
    #(   .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
        .BAUD_RATE(115_200)
    )my_uart_transmit
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_byte_in(douta),
      .trigger_in(btn[2]),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
    );
 

 
    // 8+8+4 = 20 max (can technically do a tighter bound but so be it)
    logic [20:0] total_count;
    localparam BRAM_1_SIZE = 500_00; // MUST CHANGE
    localparam BRAM_2_SIZE = 500_00; // MUST CHANGE
 
 
    // BRAM Memory
    // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!
 
    parameter BRAM_WIDTH = 32;
    parameter BRAM_DEPTH = 250_00; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
 
    // only using port a for reads: we only use dout
    logic [BRAM_WIDTH-1:0]     douta;
    logic [ADDR_WIDTH-1:0]     addra;
 
    // only using port b for writes: we only use din
    logic [BRAM_WIDTH-1:0]     dinb;
    logic [ADDR_WIDTH-1:0]     addrb = 0;


    logic [8:0] prev_chunk = 0;
    logic [16:0] full_chunk = 0;
    logic has_prev_chunk = 0;
    logic full_chunk_valid = 0;

    always_ff @(posedge clk_100mhz)begin
      uart_rx_buf0 <= uart_rxd;
      uart_rx_buf1 <= uart_rx_buf0;
      new_data_out_buf <= new_data_out;
      if (new_data_out) begin
          if (!has_prev_chunk) begin
             prev_chunk <= dinb;
             has_prev_chunk <= 1;
             full_chunk_valid <= 0;
          end else begin
             full_chunk <= {dinb, prev_chunk};
             has_prev_chunk <= 0;
             full_chunk_valid <= 1;
          end
      end else begin
         full_chunk_valid <= 0;
      end
    end
 
 
    xilinx_true_dual_port_read_first_2_clock_ram
      #(.RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH)) audio_bram
        (
         // PORT A
         .addra({sw[3], sw[2], sw[1], sw[0]}), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(douta),
         // PORT B
         .addrb(addrb),
         .dinb(dinb), // full_chunk),
         .clkb(clk_100mhz),
         .web(1), // addrb < BRAM_1_SIZE), // write ONLY IF WITHIN THE SIZE
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
         );


   // BRAM Memory
   // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

   parameter PT_BRAM_WIDTH = 1; // 1;
   parameter PT_BRAM_DEPTH = 500_00; // 784; // 40_000 samples = 5 seconds of samples at 8kHz sample
   parameter PT_ADDR_WIDTH = $clog2(PT_BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [PT_BRAM_WIDTH-1:0]     douta_pt;
   logic [PT_ADDR_WIDTH-1:0]     addra_pt;

   // only using port b for writes: we only use din
   logic [PT_BRAM_WIDTH-1:0]     dinb_pt;
   logic [PT_ADDR_WIDTH-1:0]     addrb_pt;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(PT_BRAM_WIDTH),
       .RAM_DEPTH(PT_BRAM_DEPTH)) pt_bram
       (
        // PORT A
        .addra(total_count < BRAM_1_SIZE + BRAM_2_SIZE ? total_count - BRAM_1_SIZE : BRAM_2_SIZE),
        .dina(0), // we only use port A for reads!
        .clka(clk_100mhz),
        .wea(1'b0), // read only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(douta_pt),
        // PORT B
        .addrb(addrb - BRAM_1_SIZE),
        .dinb(dinb_pt),
        .clkb(clk_100mhz),
        .web(addrb < BRAM_1_SIZE + BRAM_2_SIZE), // write always
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb() // we only use port B for writes!
        );

//    parameter SK_BRAM_WIDTH = 4; //1;
//    parameter SK_BRAM_DEPTH = 196_000; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
//    parameter SK_ADDR_WIDTH = $clog2(SK_BRAM_DEPTH);
// 
//    // only using port a for reads: we only use dout
//    logic [SK_BRAM_WIDTH-1:0]     douta_sk;
//    logic [SK_ADDR_WIDTH-1:0]     addra_sk;
// 
//    // only using port b for writes: we only use din
//    logic [SK_BRAM_WIDTH-1:0]     dinb_sk;
//    logic [SK_ADDR_WIDTH-1:0]     addrb_sk;
// 
//    xilinx_true_dual_port_read_first_2_clock_ram
//      #(.RAM_WIDTH(SK_BRAM_WIDTH),
//        .RAM_DEPTH(SK_BRAM_DEPTH)) sk_bram
//        (
//         // PORT A
//         .addra(addra_sk),
//         .dina(0), // we only use port A for reads!
//         .clka(clk_100mhz),
//         .wea(1'b0), // read only
//         .ena(1'b1),
//         .rsta(sys_rst),
//         .regcea(1'b1),
//         .douta(douta_sk),
//         // PORT B
//         .addrb(addrb_sk),
//         .dinb(dinb_sk),
//         .clkb(clk_100mhz),
//         .web(1'b1), // write always
//         .enb(1'b1),
//         .rstb(sys_rst),
//         .regceb(1'b1),
//         .doutb() // we only use port B for writes!
//         );



 
    // Memory addressing
    // TODO: instantiate an event counter that increments once every 8000th of a second
    // for addressing the (port A) data we want to send out to LINE OUT!
    evt_counter #(.MAX_COUNT(BRAM_1_SIZE + BRAM_2_SIZE)) port_a_counter(
         .clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .evt_in(btn[1]),
         .count_out(total_count));
 
 
 
    // TODO: instantiate another event counter that increments with each new UART data byte
    // for addressing the (port B) place to send our UART_RX data!
    evt_counter #(.MAX_COUNT(BRAM_1_SIZE + BRAM_2_SIZE)) port_b_counter(
         .clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .evt_in(new_data_out_buf), // full_chunk_valid),
         .count_out(addrb));
 
    // reminder TODO: go up to your PWM module, wire up the speaker to play the data from port A dout.

endmodule // top_level

`default_nettype wire
