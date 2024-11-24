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
   logic [7:0] q = 64;
   logic [7:0] p = 16;

   // Checkoff 1: Microphone->SPI->UART->Computer

    // 8kHz trigger using a week 1 counter!

    // Data Buffer SPI-UART
    // TODO: write some sequential logic to keep track of whether the
    //  current audio_sample is waiting to be sent,
    //  and to set the uart_transmit inputs appropriately.
    //  **be sure to only ever set uart_data_valid high if sw[0] is on,
    //  so we only send data on UART when we're trying to receive it!
    // logic                      audio_sample_waiting = 0;
 
    logic [7:0]                uart_data_in;
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
    logic [31:0] data_byte_out_buf;
    logic new_data_out;
    logic new_data_out_3;
    logic new_data_out_buf;
 
    uart_receive
    #(   .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
         //.BAUD_RATE(10_000_000)
        .BAUD_RATE(115_200)
    )my_uart_receive
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .rx_wire_in(uart_rx_buf1),
      .new_data_out(new_data_out),
      .data_byte_out(data_byte_out)
     );

     logic four_new_data_out;
     logic [31:0] data_four_byte_out;

    compress_4 compress_four
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .valid_data_in(new_data_out),
      .data_in(data_byte_out),
      .valid_data_out(four_new_data_out),
      .data_out(data_four_byte_out)
     );

    pipeline #(
      .BITS(1),
      .STAGES(4)
    )new_data_out_pipeline (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .data_in(four_new_data_out),
        .data_out(new_data_out_3)
    );

    // UART Transmitter to FTDI2232
    // TODO: instantiate the UART transmitter you just wrote, using the input signals from above.

    logic [7:0] transmit_byte;
    logic uart_data_valid;
 
    uart_transmit
    #(  .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
        .BAUD_RATE(115_200)
        //.BAUD_RATE(10_000_000)
    )my_uart_transmit
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_byte_in(transmit_byte), // douta_pt),
      .trigger_in(uart_data_valid),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
    );
 
   // logic [8:0] prev_chunk = 0;
   // logic [16:0] full_chunk = 0;
   // logic has_prev_chunk = 0;
   // logic full_chunk_valid = 0;

    parameter BRAM_WIDTH = 32;
    parameter BRAM_DEPTH = 1 + 25_250;
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
 
    parameter PT_BRAM_WIDTH = 2; // 1;
    parameter PT_BRAM_DEPTH = 1 + 25_000; // 784; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter PT_ADDR_WIDTH = $clog2(PT_BRAM_DEPTH);

    parameter SK_BRAM_WIDTH = 2; //1;
    parameter SK_BRAM_DEPTH = 1 + 50; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter SK_ADDR_WIDTH = $clog2(SK_BRAM_DEPTH);

    parameter B_BRAM_WIDTH = 32; //1;
    parameter B_BRAM_DEPTH = 1 + 2_500; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter B_ADDR_WIDTH = $clog2(B_BRAM_DEPTH);

    parameter COUNT_SIZE = $clog2(BRAM_DEPTH + PT_BRAM_DEPTH + PT_BRAM_DEPTH + B_BRAM_DEPTH);


    // 8+8+4 = 20 max (can technically do a tighter bound but so be it)
    logic [COUNT_SIZE:0] total_count;
    // localparam BRAM_1_SIZE = 40; // MUST CHANGE
    // localparam BRAM_2_SIZE = 40; // MUST CHANGE
 
 
    // BRAM Memory
    // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!
 

    // only using port a for reads: we only use dout
    logic [BRAM_WIDTH-1:0]     douta;
    logic [ADDR_WIDTH-1:0]     addra;
 
    // only using port b for writes: we only use din
    logic [BRAM_WIDTH-1:0]     dinb;
    logic [ADDR_WIDTH-1:0]     addrb;
 
    xilinx_true_dual_port_read_first_2_clock_ram
      #(.RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(A.mem))) audio_bram
        (
         // PORT A
         .addra(total_count),// sw), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(douta),
         // PORT B
         .addrb(addrb),
         .dinb(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(new_data_out_buf && addrb < BRAM_DEPTH), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
         );


   // BRAM Memory
   // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

   // only using port a for reads: we only use dout
   logic [PT_BRAM_WIDTH-1:0]     douta_pt;
   logic [PT_ADDR_WIDTH-1:0]     addra_pt;

   // only using port b for writes: we only use din
   logic [PT_BRAM_WIDTH-1:0]     dinb_pt;
   logic [PT_ADDR_WIDTH-1:0]     addrb_pt;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(PT_BRAM_WIDTH),
       .RAM_DEPTH(PT_BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(m.mem))) pt_bram
        (
         // PORT A
         .addra(total_count >= BRAM_DEPTH?total_count - BRAM_DEPTH:0), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(douta_pt),
         // PORT B
         .addrb(addrb - BRAM_DEPTH),
         .dinb(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(new_data_out_buf && addrb >= BRAM_DEPTH && addrb < BRAM_DEPTH + PT_BRAM_DEPTH), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
         );



   // only using port a for reads: we only use dout
   logic [SK_BRAM_WIDTH-1:0]     douta_sk;
   logic [SK_ADDR_WIDTH-1:0]     addra_sk;

   // only using port b for writes: we only use din
   logic [SK_BRAM_WIDTH-1:0]     dinb_sk;
   logic [SK_ADDR_WIDTH-1:0]     addrb_sk;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(SK_BRAM_WIDTH),
       .RAM_DEPTH(SK_BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(s.mem))) sk_bram
       (
        // PORT A
        .addra((total_count - BRAM_DEPTH - PT_BRAM_DEPTH)),
        .dina(0), // we only use port A for reads!
        .clka(clk_100mhz),
        .wea(1'b0), // read only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(douta_sk),
         // PORT B
         .addrb(addrb - BRAM_DEPTH - PT_BRAM_DEPTH),
         .dinb(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(new_data_out_buf && addrb >= BRAM_DEPTH + PT_BRAM_DEPTH && addrb < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
        );


   // only using port a for reads: we only use dout
   logic [B_BRAM_WIDTH-1:0]     douta_b;
   logic [B_ADDR_WIDTH-1:0]     addra_b;

   // only using port b for writes: we only use din
   logic [B_BRAM_WIDTH-1:0]     dinb_b;
   logic [B_ADDR_WIDTH-1:0]     addrb_b;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(B_BRAM_WIDTH),
       .RAM_DEPTH(B_BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(b.mem))) b_bram
       (
        // PORT A
        .addra((total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH)),
        .dina(0), // we only use port A for reads!
        .clka(clk_100mhz),
        .wea(1'b0), // read only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(douta_b),
         // PORT B
         .addrb(addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH),
         .dinb(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(new_data_out_buf && addrb >= BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH && addrb < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH + B_BRAM_DEPTH), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
        );



 
    // // Memory addressing
    // // TODO: instantiate an event counter that increments once every 8000th of a second
    // // for addressing the (port A) data we want to send out to LINE OUT!
    // evt_counter #(.MAX_COUNT(BRAM_1_SIZE)) port_a_counter(
    //      .clk_in(clk_100mhz),
    //      .rst_in(sys_rst),
    //      .evt_in(new_data_out_buf),
    //      .count_out(total_count));
 
 
 
    // TODO: instantiate another event counter that increments with each new UART data byte
    // for addressing the (port B) place to send our UART_RX data!
    // evt_counter #(.MAX_COUNT(BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH + B_BRAM_DEPTH)) port_b_counter(
    evt_counter #(.MAX_COUNT(BRAM_DEPTH)) port_b_counter(
         .clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .evt_in(four_new_data_out),
         .count_out(addrb));
 
    // reminder TODO: go up to your PWM module, wire up the speaker to play the data from port A dout.

   logic [1:0] idx;
   logic uart_transmit_buff;

   always_ff @(posedge clk_100mhz)begin
     if (sys_rst) begin
        idx <= 0;
        total_count <= 0;
     end else begin
     
     uart_rx_buf0 <= uart_rxd;
     uart_rx_buf1 <= uart_rx_buf0;
     new_data_out_buf <= four_new_data_out;
     data_byte_out_buf <= data_four_byte_out;

     if (sw[0]) begin
        if (!uart_busy) begin
            case (idx)
                2'b00: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta[7:0] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b01;
                end
                2'b01: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta[7+8:8] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b10;
                end
                2'b10: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta[7+16:16] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b11;
                end
                2'b11: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta[7+24:24] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b00;
                    total_count <= total_count + 1;
                end
            endcase
            uart_data_valid <= 1;//uart_transmit_buff;
            // uart_transmit_buff <= 1;
        end
     end else begin
        uart_data_valid <= 0;
        total_count <= 0;
        idx <= 0;
        uart_transmit_buff <= 0;
     end

      // if (new_data_out) begin
      //     if (!has_prev_chunk) begin
      //        prev_chunk <= dinb;
      //        has_prev_chunk <= 1;
      //        full_chunk_valid <= 0;
      //     end else begin
      //        full_chunk <= {dinb, prev_chunk};
      //        has_prev_chunk <= 0;
      //        full_chunk_valid <= 1;
      //     end
      // end else begin
      //    full_chunk_valid <= 0;
      // end

     // combining our a few bytes
     end
   end
 

endmodule // top_level

`default_nettype wire
