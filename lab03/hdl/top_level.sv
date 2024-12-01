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
   assign led[0] = sw[0];

   assign led[1] = transmit;
   assign led[2] = nn_done;
   assign led[3] = done_nn_out;
   assign led[15:4] = 0;

   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];

   logic transmit;

   logic [1:0] state_tl;

   always_ff @(posedge clk_100mhz) begin
    state_tl[0] <= sw[1];
    state_tl[1] <= sw[2];
   end
   // assign state = 2'b01;
 
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
    parameter PT_BRAM_DEPTH = 1 + 100; // 784; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter PT_ADDR_WIDTH = $clog2(PT_BRAM_DEPTH);

    parameter SK_BRAM_WIDTH = 2; //1;
    parameter SK_BRAM_DEPTH = 1 + 250; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter SK_ADDR_WIDTH = $clog2(SK_BRAM_DEPTH);

    parameter B_BRAM_WIDTH = 32; //1;
    parameter B_BRAM_DEPTH = 1 + 2_510; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter B_ADDR_WIDTH = $clog2(B_BRAM_DEPTH);

    parameter NN_BRAM_WIDTH = 3; //1;
    parameter NN_BRAM_DEPTH = 1000; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter NN_ADDR_WIDTH = $clog2(NN_BRAM_DEPTH);

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
  // logic [4:0] done_enc_buffer;
  logic done_enc_out;
 
   enc_addr_looper
   #(.DEPTH(100), .K(500)) enc_addr_looper
   //#(.DEPTH(10), .K(5)) enc_addr_looper
   (.clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .begin_enc(sw[0]),
    .inner_k_out(a_idx_out_enc),
    .N_out(k_idx_out_enc),
     .A_addr(A_addr_enc),
     .s_addr(s_addr_enc),
     .b_addr(b_addr_enc_0),
     .e_addr(e_addr_enc),
     .e_zero(e_zero_enc),
     .addr_valid(addr_valid_enc),
     .done(done_enc)
   );

    logic [9:0] idx_B_enc;
    logic [31:0] B_out_enc;
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

        e_lsfr_simulator[15:0] <= (e_zero_enc_out==1)?0:douta_pt[0]<<6; // TODO: Maybe should be 6
        // e_lsfr_simulator[31:16] <= (e_zero_enc_out==1)?0:douta_pt[1]<<10;

        /* done_enc_buffer[0] <= done_enc;
        for (int i_count = 1; i_count <= 4; i_count++) begin
          done_enc_buffer[i_count] <= done_enc_buffer[i_count-1];
        end
        done_enc_out <= done_enc_buffer[4];*/
      end
    end

    pipeline #(
      .BITS(1),
      .STAGES(5)
    ) done_enc_pipeline (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .data_in(done_enc),
        .data_out(done_enc_out)
    );

    pipeline #(
      .BITS(1),
      .STAGES(5)
    ) done_dec_pipeline (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .data_in(done_dec),
        .data_out(done_dec_out)
    );

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
     // .b_idx(idx_poly_out_enc),
     .b_valid(real_b_valid_enc),
     .b_in(douta_b),
     .sum_valid(sum_enc_valid),
     .sum(b_adder_out_enc),
     .sum_idx(sum_idx_enc),
     .h_in(h_out_ps_mult_enc),
      .h_out(b_adder_h_out_enc)
              );

    always_ff @(posedge clk_100mhz)begin
     if (sys_rst) begin
        transmit <= 0;
     end else begin
        case(state_tl)
          2'b00: begin
            transmit <= 1;
          end
          2'b01: begin
            transmit <= done_enc_out;
          end
          2'b10: begin
            transmit <= done_dec_out;
          end
          2'b11: begin
            transmit <= done_nn_out;
          end
          default: begin
          end
        endcase
      end
    end

  // END ENC LOGIC

  // BEGIN DEC LOGIC

  logic [16:0] A_addr_dec;
 logic [16:0] s_addr_dec;
 logic [12:0] b_addr_dec_0;
 logic [12:0] b_addr_dec;
 logic [9:0] e_addr_dec;
 logic e_zero_dec;
 logic addr_valid_dec;


 logic [9:0] s_idx_out_dec;
 logic [9:0] a_idx_out_dec;
 logic [9:0] k_idx_out_dec;


 logic done_dec;
 // logic [4:0] done_dec_buffer;
 logic done_dec_out;
  enc_addr_looper
   #(.DEPTH(10), .K(500)) dec_addr_looper
   //#(.DEPTH(10), .K(5)) dec_addr_looper
   (.clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .begin_enc(sw[0]),
    .inner_k_out(a_idx_out_dec),
    .N_out(k_idx_out_dec),
     .A_addr(A_addr_dec),
     .s_addr(s_addr_dec),
     .b_addr(b_addr_dec_0),
     .e_addr(e_addr_dec),
     .e_zero(e_zero_dec),
     .addr_valid(addr_valid_dec),
     .done(done_dec)
   );


   logic [9:0] idx_B_dec;
   logic [31:0] B_out_dec;
   logic B_valid_ps_mult_dec;


   logic e_zero_buff_dec;
   logic e_zero_dec_out;


   logic a_valid_buffer_dec;
   logic a_valid_dec;
   logic real_b_valid_dec;


   logic e_valid_buffer_dec;
   logic e_valid_dec;


   logic [9:0] a_idx_buffer_dec;
   logic [9:0] a_idx_dec;

   logic [9:0] a_idx_dec_b0;
   logic [9:0] a_idx_dec_b1;


   logic [9:0] s_idx_buffer_dec;
   logic [9:0] s_idx_dec;


   logic [9:0] h_idx_buffer_dec;
   logic [9:0] h_idx_dec;


   logic[9:0] idx_poly_out_dec;


   logic [9:0] h_out_ps_mult_dec;


   public_private_mm
   #(.DEPTH(10))
   dec_pub_sec_mm (.clk_in(clk_100mhz),
                   .rst_in(sys_rst),
                   .A_valid(a_valid_dec),
                   .s_valid(a_valid_dec),
                   .A_idx(a_idx_dec << 1),
                   .pk_A(douta_A),
                   .sk_s(douta_sk),
                   .idx_B(idx_poly_out_dec),
                   .B_out(B_out_dec),
                   .B_valid(B_valid_ps_mult_dec),
                   .h_in(h_idx_dec),
                   .h_out(h_out_ps_mult_dec)
             );

   always_ff @(posedge clk_100mhz) begin
     if(sys_rst) begin
       a_valid_buffer_dec <= 0;
       a_valid_dec <= 0;
     end else begin
       a_valid_buffer_dec <= addr_valid_dec;
       a_valid_dec <= a_valid_buffer_dec;
       real_b_valid_dec <= a_valid_dec;


       a_idx_buffer_dec <= a_idx_out_dec;
       a_idx_dec <= a_idx_buffer_dec;
       a_idx_dec_b0 <= s_idx_dec;
       a_idx_dec_b1 <= a_idx_dec_b0;// TODO: rename to s


       s_idx_buffer_dec <= s_idx_out_dec;
       s_idx_dec <= s_idx_buffer_dec;


       h_idx_buffer_dec <= k_idx_out_dec;
       h_idx_dec <= h_idx_buffer_dec;


       b_addr_dec <= b_addr_dec_0;
     end
   end


   logic sum_dec_valid;
   logic [9:0] sum_idx_dec;
   logic [9:0] b_adder_h_out_dec;

   logic[31:0] b_adder_out_enc;
   logic[31:0] b_adder_out_dec;


   b_adder
   #(.DEPTH(10), .ADD(0))
   dec_b_sub (.clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .poly_valid(B_valid_ps_mult_dec),
    .poly_in(B_out_dec),
    .poly_idx(idx_poly_out_dec),
    .e_valid(1'b1),
    .e_in(1'b0),
    // .b_idx(idx_poly_out_dec),
    .b_valid(real_b_valid_dec),
    .b_in(douta_b),
    .sum_valid(sum_dec_valid),
    .sum(b_adder_out_dec),
    .sum_idx(sum_idx_dec),
    .h_in(h_out_ps_mult_dec),
     .h_out(b_adder_h_out_dec)
             );
  // END DEC LOGIC

  // BEGIN NN LOGIC

  logic [9:0] nn_n_out;
  logic [7:0] nn_k_out;
  logic [5:0] nn_w_out;

  logic [16:0] nn_A_addr;
  logic [16:0] nn_nn_addr;
  logic [12:0] nn_b_addr;

  logic nn_addr_valid;
  logic nn_done;

  nn_addr_looper
    #(.DEPTH(100), .K(502), .NN_OUT(10), .BOOTSTRAP(10)) nn_loop
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .begin_nn(sw[0]),
      .outer_N_out(nn_n_out),
      .outer_k_out(nn_k_out),
      .nn_out(nn_w_out),
      .A_addr(nn_A_addr),
      .nn_addr(nn_nn_addr),
      .b_addr(nn_b_addr),
      .addr_valid(nn_addr_valid),
      .done(nn_done)
    );

  logic nn_valid_buff;
  logic nn_valid_in_adder;

  logic [9:0] nn_n_out_buffer;
  logic [7:0] nn_k_out_buffer;
  logic [5:0] nn_w_out_buffer;

  logic [9:0]nn_n_out_in_adder;
  logic [7:0]nn_k_out_in_adder;
  logic [5:0] nn_w_out_in_adder;

  logic [31:0] nn_sum_out;
  logic [9:0] nn_sum_idx_k;
  logic [9:0] nn_sum_idx_N;
  logic [9:0] nn_sum_idx_w;
  logic nn_store_valid;

  nn_adder
    #(.K_VAL(502),
    .DEPTH(100), .OUT_NODES(10)) nn_adder
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      .data_valid(nn_valid_in_adder),
      .idx_k_in(nn_k_out_in_adder), // 0 - 502/2
      .idx_N_in(nn_n_out_in_adder), // 0 - 100
      .ct_in(douta_A), // A
      .weights_in(douta_nn),
      .weights_idx(nn_w_out_in_adder), // 0-10
      .mem_in(douta_b),

      .sum_out(nn_sum_out),
      .sum_idx_k(nn_sum_idx_k),
      .sum_idx_N(nn_sum_idx_N),
      .sum_idx_w(nn_sum_idx_w),
      .sum_valid(nn_store_valid)
    );

  always_ff @(posedge clk_100mhz) begin
     if(sys_rst) begin
       nn_valid_buff <= 0;
       nn_valid_in_adder <= 0;
     end else begin
       nn_valid_buff <= nn_addr_valid;
       nn_valid_in_adder <= nn_valid_buff;

       nn_n_out_buffer <= nn_n_out;
       nn_n_out_in_adder <= nn_n_out_buffer;

       nn_k_out_buffer <= nn_k_out;
       nn_k_out_in_adder <= nn_k_out_buffer;

       nn_w_out_buffer <= nn_w_out;
       nn_w_out_in_adder <= nn_w_out_buffer;
     end
   end

   logic done_nn_out;

   pipeline #(
      .BITS(1),
      .STAGES(5)
   ) done_nn_pipeline (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .data_in(nn_done),
        .data_out(done_nn_out)
    );

  // END NN LOGIC

    logic[31:0] b_out_dec_rounded;
    assign b_out_dec_rounded[15:10] = 0;
    assign b_out_dec_rounded[31:26] = 0;
    assign b_out_dec_rounded[9:0] = b_adder_out_dec[15:6]+b_adder_out_dec[5];
    assign b_out_dec_rounded[25:16] = b_adder_out_dec[31:22]+b_adder_out_dec[21];

    always_comb begin
      case (state_tl)
            2'b00: begin
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;

                addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
            end
            2'b01: begin
              if (transmit) begin
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
                // addrb_b = sum_idx_enc >> 1;
              end else begin
                addra_A = A_addr_enc;
                addra_pt = e_addr_enc;
                addra_sk = s_addr_enc;
                // addra_b = b_addr_enc;
                write_b_valid = sum_enc_valid;
                addrb_b = b_adder_h_out_enc;//sum_idx_enc>>1;
                dinb_b = b_adder_out_enc;
                // addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
              end
            end
            2'b10: begin
                if (transmit) begin
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
                // addrb_b = sum_idx_enc >> 1;
              end else begin
                addra_A = A_addr_dec;
                addra_pt = e_addr_dec;
                addra_sk = s_addr_dec;
                addra_b = b_addr_dec;
                write_b_valid = sum_dec_valid;
                addrb_b = b_adder_h_out_enc; //sum_idx_dec>>1;
                dinb_b = (sum_idx_dec == 498)?b_out_dec_rounded:b_adder_out_dec; // NEED NEW MODULE TO DO ROUNDING - maybe s = 0 and b = 499
                // addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
              end
            end
            2'b11: begin
              if (transmit) begin
                addra_A = total_count;
                addra_pt = total_count - BRAM_DEPTH;
                addra_sk = (total_count - BRAM_DEPTH - PT_BRAM_DEPTH);
                addra_b = total_count - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
                // addrb_b = sum_idx_enc >> 1;
              end else begin
                addra_A = nn_A_addr;
                // addra_pt = e_addr_enc;
                // addra_sk = s_addr_enc;
                addra_b = nn_b_addr;
                addra_nn = nn_nn_addr;
                write_b_valid = nn_store_valid;
                addrb_b = nn_sum_idx_k + nn_sum_idx_w*251;
                dinb_b = nn_sum_out;
                // addrb_b = addrb - BRAM_DEPTH - PT_BRAM_DEPTH - SK_BRAM_DEPTH;
              end
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



 
  // only using port a for reads: we only use dout
   logic [NN_BRAM_WIDTH-1:0]     douta_nn;
   logic [NN_ADDR_WIDTH-1:0]     addra_nn;

  // we never write to port b

   xilinx_true_dual_port_read_first_2_clock_ram
     #(.RAM_WIDTH(NN_BRAM_WIDTH),
       .RAM_DEPTH(NN_BRAM_DEPTH),
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
        .INIT_FILE(`FPATH(nn.mem))) nn_bram
        (
         // PORT A
         .addra(addra_nn), // total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
         .dina(0), // we only use port A for reads!
         .clka(clk_100mhz),
         .wea(1'b0), // read only
         .ena(1'b1),
         .rsta(sys_rst),
         .regcea(1'b1),
         .douta(douta_nn),
         // PORT B
         .addrb(1'b0),
         .dinb(1'b0),
         .clkb(clk_100mhz),
         .web(1'b0), // never write
         .enb(1'b1),
         .rstb(sys_rst),
         .regceb(1'b1),
         .doutb() 
         );
 
 
 
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
     end else begin
     
     uart_rx_buf0 <= uart_rxd;
     uart_rx_buf1 <= uart_rx_buf0;
     new_data_out_buf <= four_new_data_out;
     data_byte_out_buf <= data_four_byte_out;

      if (sw[0] && transmit) begin
          if (!uart_busy) begin
              case (idx)
                  2'b00: begin
                      transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7:0] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b[7:0];
                      idx <= 2'b01;
                  end
                  2'b01: begin
                      transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+8:8] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b[7+8:8];
                      idx <= 2'b10;
                  end
                  2'b10: begin
                      transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+16:16] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b[7+16:16];
                      idx <= 2'b11;
                  end
                  2'b11: begin
                      transmit_byte <= total_count < BRAM_DEPTH ? douta_A[7+24:24] : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH) ? douta_pt : (total_count < BRAM_DEPTH + PT_BRAM_DEPTH + SK_BRAM_DEPTH) ? douta_sk : douta_b[7+24:24];
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
