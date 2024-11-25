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

   logic transmit;

   logic [1:0] state;
   assign state = {sw[2], sw[1]};

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
    parameter PT_BRAM_DEPTH = 1 + 50; // 784; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter PT_ADDR_WIDTH = $clog2(PT_BRAM_DEPTH);

    parameter SK_BRAM_WIDTH = 2; //1;
    parameter SK_BRAM_DEPTH = 1 + 25_000; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
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
    logic [BRAM_WIDTH-1:0]     douta_A;
    logic [ADDR_WIDTH-1:0]     addra_A;
 
    // only using port b for writes: we only use din
    logic [BRAM_WIDTH-1:0]     dinb_A;
    logic [ADDR_WIDTH-1:0]     addrb_A;
    logic [ADDR_WIDTH-1:0]     addrb;
 
    xilinx_true_dual_port_read_first_2_clock_ram
      #(.RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(A.mem))) audio_bram
        (
         // PORT A
         .addra(addra_A),// sw), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(douta_A),
         // PORT B
         .addrb(addrb_A),
         .dinb(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(new_data_out_buf && addrb_A < BRAM_DEPTH), // write always
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() // we only use port B for writes!
         );


   // ENC LOGIC

  logic [16:0] A_addr_enc;
  logic [16:0] s_addr_enc;
  logic [12:0] b_addr_enc_0;
  logic [12:0] b_addr_enc;
  logic [9:0] e_addr_enc;
  logic e_zero_enc;
  logic addr_valid_enc;

  logic [9:0] s_idx_out_enc;
  logic [9:0] a_idx_out_enc;
  logic [9:0] k_idx_out_enc;

  logic done_enc;
  logic [4:0] done_enc_buffer;
  logic done_enc_out;
 
   enc_addr_looper
    #(.DEPTH(100), .K(500)) enc_addr_looper
    (.clk_in(clk_100mhz),
     .rst_in(sys_rst),
     .begin_enc(sw[0]),
     .inner_N_out(s_idx_out_enc),
     .outer_N_out(a_idx_out_enc),
     .k_out(k_idx_out_enc),
      .A_addr(A_addr_enc),
      .s_addr(s_addr_enc),
      .b_addr(b_addr_enc_0),
      .e_addr(e_addr_enc),
      .e_zero(e_zero_enc),
      .addr_valid(addr_valid_enc),
      .done(done_enc)
    );

    logic [9:0] idx_B_enc;
    logic [47:0] B_out_enc;
    logic B_valid_ps_mult_enc;
    logic [9:0] h_out;

    // TODO DO THIS
    logic e_zero_buff_enc;
    logic e_zero_enc_out;

    logic a_valid_buffer_enc;
    logic a_valid_enc;
    logic real_b_valid_enc;

    logic e_valid_buffer_enc;
    logic e_valid_enc;

    logic [9:0] a_idx_buffer_enc;
    logic [9:0] a_idx_enc;

    logic [9:0] s_idx_buffer_enc;
    logic [9:0] s_idx_enc;

    logic [9:0] h_idx_buffer_enc;
    logic [9:0] h_idx_enc;

    logic[9:0] idx_poly_out_enc;

    logic [9:0] h_out_ps_mult_enc;

    public_private_mm
    #(.DEPTH(100))
    my_pub_sec_mm (.clk_in(clk_100mhz),
                    .rst_in(sys_rst),
                    .A_valid(a_valid_enc),
                    .s_valid(a_valid_enc),
                    .A_idx(a_idx_enc << 1),
                    .s_idx(s_idx_enc << 1),
                    .pk_A(douta_A),
                    .sk_s(douta_sk),
                    .idx_B(idx_poly_out_enc),
                    .B_out(B_out_enc),
                    .B_valid(B_valid_ps_mult_enc),
                    .h_in(h_idx_enc),
                    .h_out(h_out_ps_mult_enc)
              );

    // TODO: fake message buffer

    always_ff @(posedge clk_100mhz) begin
      if(sys_rst) begin
        a_valid_buffer_enc <= 0;
        a_valid_enc <= 0;
      end else begin
        a_valid_buffer_enc <= addr_valid_enc;
        a_valid_enc <= a_valid_buffer_enc;
        real_b_valid_enc <= a_valid_enc;

        a_idx_buffer_enc <= a_idx_out_enc;
        a_idx_enc <= a_idx_buffer_enc;

        s_idx_buffer_enc <= s_idx_out_enc;
        s_idx_enc <= s_idx_buffer_enc;

        h_idx_buffer_enc <= k_idx_out_enc;
        h_idx_enc <= h_idx_buffer_enc;

        b_addr_enc <= b_addr_enc_0;

        e_valid_buffer_enc <= addr_valid_enc;
        e_valid_enc <= e_valid_buffer_enc;

        e_zero_buff_enc <= e_zero_enc;
        e_zero_enc_out <= e_zero_buff_enc;

        e_lsfr_simulator[15:0] <= (e_zero_enc_out==1)?0:douta_pt[0]<<10;
        e_lsfr_simulator[31:16] <= (e_zero_enc_out==1)?0:douta_pt[1]<<10;

        done_enc_buffer[0] <= done_enc;
        for (int i_count = 1; i_count < 4; i_count++) begin
          done_enc_buffer[i_count] <= done_enc_buffer[i_count-1];
        end
        done_enc_out <= done_enc_buffer[4];
      end
    end

    logic[31:0] e_lsfr_simulator;

    logic sum_enc_valid;
    logic [9:0] sum_idx_enc;
    logic [9:0] b_adder_h_out_enc;

    b_adder
    #(.DEPTH(100), .ADD(1))
    my_b_adder (.clk_in(clk_100mhz),
     .rst_in(sys_rst),
     .poly_valid(B_valid_ps_mult_enc),
     .poly_in(B_out_enc),
     .poly_idx(idx_poly_out_enc),
     .e_valid(real_b_valid_enc),
     .e_in(e_lsfr_simulator),
     .b_idx(idx_poly_out_enc),
     .b_valid(real_b_valid_enc),
     .b_in(douta_b),
     .sum_valid(sum_enc_valid),
     .sum(dinb_b),
     .sum_idx(sum_idx_enc),
     .h_in(h_out_ps_mult_enc),
      .h_out(b_adder_h_out_enc)
              );

    always_comb begin
      case (state)
            2'b00: begin
                transmit = 1;
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;

                addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
            end
            2'b01: begin
              if (transmit) begin
                transmit = 1;
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
                addrb_b = sum_idx_enc >> 1;
              end else begin
                transmit = done_enc_out;
                addra_A = A_addr_enc;
                addra_pt = e_addr_enc;
                addra_sk = s_addr_enc;
                addra_b = b_addr_enc;
                write_b_valid = sum_enc_valid;
                addrb_b = sum_idx_enc>>1;
                // addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
              end
            end
            2'b10: begin
                
            end
            2'b11: begin
                
            end
            default: begin
            end
        endcase
    end

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
        .INIT_FILE(`FPATH(pt.mem))) pt_bram
        (
         // PORT A
         .addra(addra_pt), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
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
        .addra(addra_sk),
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
   logic write_b_valid;

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(B_BRAM_WIDTH),
       .RAM_DEPTH(B_BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(b.mem))) b_bram
       (
        // PORT A
        .addra(addra_b),
        .dina(0), // we only use port A for reads!
        .clka(clk_100mhz),
        .wea(1'b0), // read only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(douta_b),
         // PORT B
         .addrb(addrb_b),
         .dinb(dinb_b), //(data_byte_out_buf),
         .clkb(clk_100mhz),
         .web(write_b_valid),//(new_data_out_buf && addrb >= BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH && addrb < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH + B_BRAM_DEPTH), // write always
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
    evt_counter #(.MAX_COUNT(BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH + B_BRAM_DEPTH)) port_b_counter(
    // evt_counter #(.MAX_COUNT(BRAM_DEPTH)) port_b_counter(
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
        done_enc_buffer <= 0;
        done_enc_out <= 0;
     end else if (transmit) begin
     
     uart_rx_buf0 <= uart_rxd;
     uart_rx_buf1 <= uart_rx_buf0;
     new_data_out_buf <= four_new_data_out;
     data_byte_out_buf <= data_four_byte_out;

     if (sw[0]) begin
        if (!uart_busy) begin
            case (idx)
                2'b00: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7:0] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b01;
                end
                2'b01: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+8:8] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b10;
                end
                2'b10: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+16:16] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
                    idx <= 2'b11;
                end
                2'b11: begin
                    transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+24:24] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b;
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
