`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level
  (
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic [15:0] led, //16 green output LEDs (located right above switches)
   output logic [2:0]  rgb0, //RGB channels of RGB LED0
   output logic [2:0]  rgb1, //RGB channels of RGB LED1
   output logic        spkl, spkr, // left and right channels of line out port
   // input wire          cipo, // SPI controller-in peripheral-out
   // output logic        copi, dclk, cs, // SPI controller output signals
	 input wire 				 uart_rxd, // UART computer-FPGA
	 output logic 			 uart_txd, // UART FPGA-computer
  // New for week 6: DDR3 ports
  inout wire [15:0]  ddr3_dq,
  inout wire [1:0]   ddr3_dqs_n,
  inout wire [1:0]   ddr3_dqs_p,
  output wire [12:0] ddr3_addr,
  output wire [2:0]  ddr3_ba,
  output wire        ddr3_ras_n,
  output wire        ddr3_cas_n,
  output wire        ddr3_we_n,
  output wire        ddr3_reset_n,
  output wire        ddr3_ck_p,
  output wire        ddr3_ck_n,
  output wire        ddr3_cke,
  output wire [1:0]  ddr3_dm,
  output wire        ddr3_odt

   );


  // Clock and Reset Signals: updated for a couple new clocks!
  logic          sys_rst_camera;
  logic          sys_rst_pixel;

  logic          clk_camera;
  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_xc;


  logic          clk_migref;
  logic          sys_rst_migref;
  
  logic          clk_ui;
  logic          sys_rst_ui;
  
  logic          clk_100_passthrough;



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

//    assign spkl = 0;
//    assign spkr = 0;
//    assign copi = 0;
//    assign dclk = 0;
//    assign cs = 0;
//    assign uart_txd = 0;

    // 8kHz trigger using a week 1 counter!

    // TODO: set this parameter to the number of clock cycles between each cycle of an 8kHz trigger
    localparam CYCLES_PER_TRIGGER = 12500; // MUST CHANGE
 
    logic [31:0]        trigger_count;
    logic               spi_trigger;
 
    counter counter_8khz_trigger
      (.clk_in(clk_100mhz),
       .rst_in(sys_rst),
       .period_in(CYCLES_PER_TRIGGER),
       .count_out(trigger_count));
 
    // SPI Controller on our ADC
 
//     //built last week:
//     spi_con
//    #(   .DATA_WIDTH(ADC_DATA_WIDTH),
//         .DATA_CLK_PERIOD(ADC_DATA_CLK_PERIOD)
//     )my_spi_con
//     ( .clk_in(clk_100mhz),
//       .rst_in(sys_rst),
//       .data_in(spi_write_data),
//       .trigger_in(spi_trigger),
//       .data_out(spi_read_data),
//       .data_valid_out(spi_read_data_valid), //high when output data is present.
//       .chip_data_out(copi), //(serial dout preferably)
//       .chip_data_in(cipo), //(serial din preferably)
//       .chip_clk_out(dclk),
//       .chip_sel_out(cs)
//      );
 
 
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
 
 
 
 
    // set both output channels equal to the same PWM signal!
    assign spkl = spk_out;
    assign spkr = spk_out;
 
 
 
    // Data Buffer SPI-UART
    // TODO: write some sequential logic to keep track of whether the
    //  current audio_sample is waiting to be sent,
    //  and to set the uart_transmit inputs appropriately.
    //  **be sure to only ever set uart_data_valid high if sw[0] is on,
    //  so we only send data on UART when we're trying to receive it!
    logic                      audio_sample_waiting = 0;
 
    logic [7:0]                uart_data_in;
    logic                      uart_data_valid;
    logic                      uart_busy;
 
 
 
    // UART Transmitter to FTDI2232
    // TODO: instantiate the UART transmitter you just wrote, using the input signals from above.
 
    uart_transmit
    #(   .INPUT_CLOCK_FREQ(100_000_000), // 100 MHz
        .BAUD_RATE(115_200)
    )my_uart_transmit
    ( .clk_in(clk_100mhz),
      .rst_in(sys_rst),
      // SWITCHES FOR DEBUGGING
      .data_byte_in(sw[0] ? douta : douta_pt),
      // .data_byte_in(sw[0] ? douta : douta_pt),
      .trigger_in(new_data_out_buf),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
     );
 
 
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
 
 
   always_ff @(posedge clk_100mhz)begin
     // // CHECKOFF 1
     // // if SPI output data is there
     // audio_sample_waiting <= 1;
     // // audio_sample <= 1;
     // uart_data_in <= 0;
 
     // // if (spi_read_data_valid) begin 
     // //     // wait is high
     // //     audio_sample_waiting <= 1;
     // // end else if (!uart_busy) begin
     // //     // low when u_art_busy is low
     // //     audio_sample_waiting <= 0;
     // // end
     // // if (spi_read_data_valid) begin
     // //     // assign audio sample (for pwm)
     // //     audio_sample <= spi_read_data[9:2];
     // //     uart_data_in <= spi_read_data[9:2];
     // // end 
     // // if (sw[0] && spi_read_data_valid) begin
     // //     uart_data_valid <= 1;
     // // end else begin
     // //     uart_data_valid <= 0;
     // // end
 
     // // CHECKOFF 2
     // // pass through
     // uart_data_valid <= 1;
     uart_rx_buf0 <= uart_rxd;
     uart_rx_buf1 <= uart_rx_buf0;
     new_data_out_buf <= new_data_out;
   end
 
 
    // 8+8+4 = 20 max (can technically do a tighter bound but so be it)
    logic [20:0] total_count;
    localparam BRAM_1_SIZE = 40; // MUST CHANGE
    localparam BRAM_2_SIZE = 40; // MUST CHANGE

  // 2. The New Way: write memory to DRAM and read it out, over a couple AXI-Stream data pipelines.
  // NEW DRAM STUFF STARTS HERE
  logic [10:0] camera_hcount;
  logic [9:0]  camera_vcount;
  logic [15:0] camera_pixel;
  logic        camera_valid;



  logic [127:0] camera_chunk;
  logic [127:0] camera_axis_tdata;
  logic         camera_axis_tlast;
  logic         camera_axis_tready;
  logic         camera_axis_tvalid;

  // takes our 16-bit values and deserialize/stack them into 128-bit messages to write to DRAM
  // the data pipeline is designed such that we can fairly safely assume its always ready.
  stacker stacker_inst(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst_camera),
    .pixel_tvalid(camera_valid),
    .pixel_tready(),
    .pixel_tdata(camera_pixel),
    // TODO: define the tlast value! you can do it in one line, based on camera hcount/vcount values
    .pixel_tlast(camera_hcount == (1280-1) && camera_vcount == (720-1)), // change me
    .chunk_tvalid(camera_axis_tvalid),
    .chunk_tready(camera_axis_tready),
    .chunk_tdata(camera_axis_tdata),
    .chunk_tlast(camera_axis_tlast));
  
  logic [127:0] camera_ui_axis_tdata;
  logic         camera_ui_axis_tlast;
  logic         camera_ui_axis_tready;
  logic         camera_ui_axis_tvalid;
  logic         camera_ui_axis_prog_empty;

  // FIFO data queue of 128-bit messages, crosses clock domains to the 81.25MHz
  // UI clock of the memory interface
  ddr_fifo_wrap camera_data_fifo(
    .sender_rst(sys_rst_camera),
    .sender_clk(clk_100mhz),
    .sender_axis_tvalid(camera_axis_tvalid),
    .sender_axis_tready(camera_axis_tready),
    .sender_axis_tdata(camera_axis_tdata),
    .sender_axis_tlast(camera_axis_tlast),
    .receiver_clk(clk_100mhz),
    .receiver_axis_tvalid(camera_ui_axis_tvalid),
    .receiver_axis_tready(camera_ui_axis_tready),
    .receiver_axis_tdata(camera_ui_axis_tdata),
    .receiver_axis_tlast(camera_ui_axis_tlast),
    .receiver_axis_prog_empty(camera_ui_axis_prog_empty));

  logic [127:0] display_ui_axis_tdata;
  logic         display_ui_axis_tlast;
  logic         display_ui_axis_tready;
  logic         display_ui_axis_tvalid;
  logic         display_ui_axis_prog_full;

  // these are the signals that the MIG IP needs for us to define!
  // MIG UI --> generic outputs
  logic [26:0]  app_addr;
  logic [2:0]   app_cmd;
  logic         app_en;
  // MIG UI --> write outputs
  logic [127:0] app_wdf_data;
  logic         app_wdf_end;
  logic         app_wdf_wren;
  logic [15:0]  app_wdf_mask;
  // MIG UI --> read inputs
  logic [127:0] app_rd_data;
  logic         app_rd_data_end;
  logic         app_rd_data_valid;
  // MIG UI --> generic inputs
  logic         app_rdy;
  logic         app_wdf_rdy;
  // MIG UI --> misc
  logic         app_sr_req; 
  logic         app_ref_req;
  logic         app_zq_req; 
  logic         app_sr_active;
  logic         app_ref_ack;
  logic         app_zq_ack;
  logic         init_calib_complete;
  

  // this traffic generator handles reads and writes issued to the MIG IP,
  // which in turn handles the bus to the DDR chip.
  traffic_generator readwrite_looper(
    // Outputs
    .app_addr         (app_addr[26:0]),
    .app_cmd          (app_cmd[2:0]),
    .app_en           (app_en),
    .app_wdf_data     (app_wdf_data[127:0]),
    .app_wdf_end      (app_wdf_end),
    .app_wdf_wren     (app_wdf_wren),
    .app_wdf_mask     (app_wdf_mask[15:0]),
    .app_sr_req       (app_sr_req),
    .app_ref_req      (app_ref_req),
    .app_zq_req       (app_zq_req),
    .write_axis_ready (camera_ui_axis_tready),
    .read_axis_data   (display_ui_axis_tdata),
    .read_axis_tlast  (display_ui_axis_tlast),
    .read_axis_valid  (display_ui_axis_tvalid),
    // Inputs
    .clk_in           (clk_ui),
    .rst_in           (sys_rst_ui),
    .app_rd_data      (app_rd_data[127:0]),
    .app_rd_data_end  (app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy          (app_rdy),
    .app_wdf_rdy      (app_wdf_rdy),
    .app_sr_active    (app_sr_active),
    .app_ref_ack      (app_ref_ack),
    .app_zq_ack       (app_zq_ack),
    .init_calib_complete(init_calib_complete),
    .write_axis_data  (camera_ui_axis_tdata),
    .write_axis_tlast (camera_ui_axis_tlast),
    .write_axis_valid (camera_ui_axis_tvalid),
    .write_axis_smallpile(camera_ui_axis_prog_empty),
    .read_axis_af     (display_ui_axis_prog_full),
    .read_axis_ready  (display_ui_axis_tready) //,
    // Uncomment for part 2!
    // .zoom_view_en ( zoom_view ),
    // .zoom_view_x ( center_x_ui ),
    // .zoom_view_y( center_y_ui )
  );

  // the MIG IP!
  ddr3_mig ddr3_mig_inst 
    (
    .ddr3_dq(ddr3_dq),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_addr(ddr3_addr),
    .ddr3_ba(ddr3_ba),
    .ddr3_ras_n(ddr3_ras_n),
    .ddr3_cas_n(ddr3_cas_n),
    .ddr3_we_n(ddr3_we_n),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_dm(ddr3_dm),
    .ddr3_odt(ddr3_odt),
    .sys_clk_i(clk_migref),
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy), 
    .app_sr_req(app_sr_req),
    .app_ref_req(app_ref_req),
    .app_zq_req(app_zq_req),
    .app_sr_active(app_sr_active),
    .app_ref_ack(app_ref_ack),
    .app_zq_ack(app_zq_ack),
    .ui_clk(clk_ui), 
    .ui_clk_sync_rst(sys_rst_ui),
    .app_wdf_mask(app_wdf_mask),
    .init_calib_complete(init_calib_complete),
    // .device_temp(device_temp),
    .sys_rst(!sys_rst_migref) // active low
  );
  
  logic [127:0] display_axis_tdata;
  logic         display_axis_tlast;
  logic         display_axis_tready;
  logic         display_axis_tvalid;
  logic         display_axis_prog_empty;
  
  ddr_fifo_wrap pdfifo(
    .sender_rst(sys_rst_ui),
    .sender_clk(clk_ui),
    .sender_axis_tvalid(display_ui_axis_tvalid),
    .sender_axis_tready(display_ui_axis_tready),
    .sender_axis_tdata(display_ui_axis_tdata),
    .sender_axis_tlast(display_ui_axis_tlast),
    .sender_axis_prog_full(display_ui_axis_prog_full),
    .receiver_clk(clk_pixel),
    .receiver_axis_tvalid(display_axis_tvalid),
    .receiver_axis_tready(display_axis_tready),
    .receiver_axis_tdata(display_axis_tdata),
    .receiver_axis_tlast(display_axis_tlast),
    .receiver_axis_prog_empty(display_axis_prog_empty));

  logic frame_buff_tvalid;
  logic frame_buff_tready;
  logic [15:0] frame_buff_tdata;
  logic        frame_buff_tlast;

  unstacker unstacker_inst(
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .chunk_tvalid(display_axis_tvalid),
    .chunk_tready(display_axis_tready),
    .chunk_tdata(display_axis_tdata),
    .chunk_tlast(display_axis_tlast),
    .pixel_tvalid(frame_buff_tvalid),
    .pixel_tready(frame_buff_tready),
    .pixel_tdata(frame_buff_tdata),
    .pixel_tlast(frame_buff_tlast));




//   // 2. The New Way: write memory to DRAM and read it out, over a couple AXI-Stream data pipelines.
//   // NEW DRAM STUFF STARTS HERE
// 
// 
//   logic [127:0] camera_chunk;
//   logic [127:0] camera_axis_tdata;
//   logic         camera_axis_tlast;
//   logic         camera_axis_tready;
//   logic         camera_axis_tvalid;
// 
//   // takes our 16-bit values and deserialize/stack them into 128-bit messages to write to DRAM
//   // the data pipeline is designed such that we can fairly safely assume its always ready.
//   stacker stacker_inst(
//     .clk_in(clk_100mhz),
//     .rst_in(sys_rst),
//     // TODO: FIX
//     .pixel_tvalid(1),
//     .pixel_tready(),
//     // TODO: FIX
//     .pixel_tdata(total_count),
//     // TODO: define the tlast value! you can do it in one line, based on camera hcount/vcount values
//     .pixel_tlast(0), // change me
//     // TODO: DO ALL OF THIS!!
//     .chunk_tvalid(1),
//     .chunk_tready(1),
//     .chunk_tdata(1),
//     .chunk_tlast(1));
//   
//   logic [127:0] camera_ui_axis_tdata;
//   logic         camera_ui_axis_tlast;
//   logic         camera_ui_axis_tready;
//   logic         camera_ui_axis_tvalid;
//   logic         camera_ui_axis_prog_empty;
// 
//   // FIFO data queue of 128-bit messages, crosses clock domains to the 81.25MHz
//   // UI clock of the memory interface
//   ddr_fifo_wrap camera_data_fifo(
//     .sender_rst(sys_rst),
//     .sender_clk(clk_100mhz),
//     .sender_axis_tvalid(camera_axis_tvalid),
//     .sender_axis_tready(camera_axis_tready),
//     .sender_axis_tdata(camera_axis_tdata),
//     .sender_axis_tlast(camera_axis_tlast),
//     .receiver_clk(clk_100mhz),
//     .receiver_axis_tvalid(camera_ui_axis_tvalid),
//     .receiver_axis_tready(camera_ui_axis_tready),
//     .receiver_axis_tdata(camera_ui_axis_tdata),
//     .receiver_axis_tlast(camera_ui_axis_tlast),
//     .receiver_axis_prog_empty(camera_ui_axis_prog_empty));
// 
//   logic [127:0] display_ui_axis_tdata;
//   logic         display_ui_axis_tlast;
//   logic         display_ui_axis_tready;
//   logic         display_ui_axis_tvalid;
//   logic         display_ui_axis_prog_full;
// 
//   // these are the signals that the MIG IP needs for us to define!
//   // MIG UI --> generic outputs
//   logic [26:0]  app_addr;
//   logic [2:0]   app_cmd;
//   logic         app_en;
//   // MIG UI --> write outputs
//   logic [127:0] app_wdf_data;
//   logic         app_wdf_end;
//   logic         app_wdf_wren;
//   logic [15:0]  app_wdf_mask;
//   // MIG UI --> read inputs
//   logic [127:0] app_rd_data;
//   logic         app_rd_data_end;
//   logic         app_rd_data_valid;
//   // MIG UI --> generic inputs
//   logic         app_rdy;
//   logic         app_wdf_rdy;
//   // MIG UI --> misc
//   logic         app_sr_req; 
//   logic         app_ref_req;
//   logic         app_zq_req; 
//   logic         app_sr_active;
//   logic         app_ref_ack;
//   logic         app_zq_ack;
//   logic         init_calib_complete;
//   
// 
//   // this traffic generator handles reads and writes issued to the MIG IP,
//   // which in turn handles the bus to the DDR chip.
//   traffic_generator readwrite_looper(
//     // Outputs
//     .app_addr         (app_addr[26:0]),
//     .app_cmd          (app_cmd[2:0]),
//     .app_en           (app_en),
//     .app_wdf_data     (app_wdf_data[127:0]),
//     .app_wdf_end      (app_wdf_end),
//     .app_wdf_wren     (app_wdf_wren),
//     .app_wdf_mask     (app_wdf_mask[15:0]),
//     .app_sr_req       (app_sr_req),
//     .app_ref_req      (app_ref_req),
//     .app_zq_req       (app_zq_req),
//     .write_axis_ready (camera_ui_axis_tready),
//     .read_axis_data   (display_ui_axis_tdata),
//     .read_axis_tlast  (display_ui_axis_tlast),
//     .read_axis_valid  (display_ui_axis_tvalid),
//     // Inputs
//     .clk_in           (clk_ui),
//     .rst_in           (sys_rst_ui),
//     .app_rd_data      (app_rd_data[127:0]),
//     .app_rd_data_end  (app_rd_data_end),
//     .app_rd_data_valid(app_rd_data_valid),
//     .app_rdy          (app_rdy),
//     .app_wdf_rdy      (app_wdf_rdy),
//     .app_sr_active    (app_sr_active),
//     .app_ref_ack      (app_ref_ack),
//     .app_zq_ack       (app_zq_ack),
//     .init_calib_complete(init_calib_complete),
//     .write_axis_data  (camera_ui_axis_tdata),
//     .write_axis_tlast (camera_ui_axis_tlast),
//     .write_axis_valid (camera_ui_axis_tvalid),
//     .write_axis_smallpile(camera_ui_axis_prog_empty),
//     .read_axis_af     (display_ui_axis_prog_full),
//     .read_axis_ready  (display_ui_axis_tready) //,
//     // Uncomment for part 2!
//     // .zoom_view_en ( zoom_view ),
//     // .zoom_view_x ( center_x_ui ),
//     // .zoom_view_y( center_y_ui )
//   );
// 
//   // the MIG IP!
//   ddr3_mig ddr3_mig_inst 
//     (
//     .ddr3_dq(ddr3_dq),
//     .ddr3_dqs_n(ddr3_dqs_n),
//     .ddr3_dqs_p(ddr3_dqs_p),
//     .ddr3_addr(ddr3_addr),
//     .ddr3_ba(ddr3_ba),
//     .ddr3_ras_n(ddr3_ras_n),
//     .ddr3_cas_n(ddr3_cas_n),
//     .ddr3_we_n(ddr3_we_n),
//     .ddr3_reset_n(ddr3_reset_n),
//     .ddr3_ck_p(ddr3_ck_p),
//     .ddr3_ck_n(ddr3_ck_n),
//     .ddr3_cke(ddr3_cke),
//     .ddr3_dm(ddr3_dm),
//     .ddr3_odt(ddr3_odt),
//     .sys_clk_i(clk_migref),
//     .app_addr(app_addr),
//     .app_cmd(app_cmd),
//     .app_en(app_en),
//     .app_wdf_data(app_wdf_data),
//     .app_wdf_end(app_wdf_end),
//     .app_wdf_wren(app_wdf_wren),
//     .app_rd_data(app_rd_data),
//     .app_rd_data_end(app_rd_data_end),
//     .app_rd_data_valid(app_rd_data_valid),
//     .app_rdy(app_rdy),
//     .app_wdf_rdy(app_wdf_rdy), 
//     .app_sr_req(app_sr_req),
//     .app_ref_req(app_ref_req),
//     .app_zq_req(app_zq_req),
//     .app_sr_active(app_sr_active),
//     .app_ref_ack(app_ref_ack),
//     .app_zq_ack(app_zq_ack),
//     .ui_clk(clk_ui), 
//     .ui_clk_sync_rst(sys_rst_ui),
//     .app_wdf_mask(app_wdf_mask),
//     .init_calib_complete(init_calib_complete),
//     // .device_temp(device_temp),
//     .sys_rst(!sys_rst_migref) // active low
//   );
//   
//   logic [127:0] display_axis_tdata;
//   logic         display_axis_tlast;
//   logic         display_axis_tready;
//   logic         display_axis_tvalid;
//   logic         display_axis_prog_empty;
//   
//   ddr_fifo_wrap pdfifo(
//     .sender_rst(sys_rst_ui),
//     .sender_clk(clk_ui),
//     .sender_axis_tvalid(display_ui_axis_tvalid),
//     .sender_axis_tready(display_ui_axis_tready),
//     .sender_axis_tdata(display_ui_axis_tdata),
//     .sender_axis_tlast(display_ui_axis_tlast),
//     .sender_axis_prog_full(display_ui_axis_prog_full),
//     .receiver_clk(clk_pixel),
//     .receiver_axis_tvalid(display_axis_tvalid),
//     .receiver_axis_tready(display_axis_tready),
//     .receiver_axis_tdata(display_axis_tdata),
//     .receiver_axis_tlast(display_axis_tlast),
//     .receiver_axis_prog_empty(display_axis_prog_empty));
// 
//   logic frame_buff_tvalid;
//   logic frame_buff_tready;
//   logic [15:0] frame_buff_tdata;
//   logic        frame_buff_tlast;
// 
//   unstacker unstacker_inst(
//     .clk_in(clk_pixel),
//     .rst_in(sys_rst_pixel),
//     .chunk_tvalid(display_axis_tvalid),
//     .chunk_tready(display_axis_tready),
//     .chunk_tdata(display_axis_tdata),
//     .chunk_tlast(display_axis_tlast),
//     .pixel_tvalid(frame_buff_tvalid),
//     .pixel_tready(frame_buff_tready),
//     .pixel_tdata(frame_buff_tdata),
//     .pixel_tlast(frame_buff_tlast));


 
 
//     // BRAM Memory
//     // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!
//  
    parameter BRAM_WIDTH = 8;
    parameter BRAM_DEPTH = 40_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
    parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);
 
    // only using port a for reads: we only use dout
    logic [BRAM_WIDTH-1:0]     douta;
    logic [ADDR_WIDTH-1:0]     addra;
 
    // only using port b for writes: we only use din
    logic [BRAM_WIDTH-1:0]     dinb;
    logic [ADDR_WIDTH-1:0]     addrb;
//  
//     xilinx_true_dual_port_read_first_2_clock_ram
//       #(.RAM_WIDTH(BRAM_WIDTH),
//         .RAM_DEPTH(BRAM_DEPTH)) audio_bram
//         (
//          // PORT A
//          .addra(total_count < BRAM_1_SIZE ? total_count : BRAM_1_SIZE),
//          .dina(0), // we only use port A for reads!
//          .clka(clk_100mhz),
//          .wea(1'b0), // read only
//          .ena(1'b1),
//          .rsta(sys_rst),
//          .regcea(1'b1),
//          .douta(douta),
//          // PORT B
//          .addrb(addrb),
//          .dinb(dinb),
//          .clkb(clk_100mhz),
//          .web(1'b1), // write always
//          .enb(1'b1),
//          .rstb(sys_rst),
//          .regceb(1'b1),
//          .doutb() // we only use port B for writes!
//          );
//  
// 
//    // BRAM Memory
//    // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!
// 
   parameter PT_BRAM_WIDTH = 4; // 1;
   parameter PT_BRAM_DEPTH = 196; // 784; // 40_000 samples = 5 seconds of samples at 8kHz sample
   parameter PT_ADDR_WIDTH = $clog2(PT_BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [PT_BRAM_WIDTH-1:0]     douta_pt;
   logic [PT_ADDR_WIDTH-1:0]     addra_pt;

   // only using port b for writes: we only use din
   logic [PT_BRAM_WIDTH-1:0]     dinb_pt;
   logic [PT_ADDR_WIDTH-1:0]     addrb_pt;
// 
//    xilinx_true_dual_port_read_first_2_clock_ram
//      #(.RAM_WIDTH(PT_BRAM_WIDTH),
//        .RAM_DEPTH(PT_BRAM_DEPTH)) pt_bram
//        (
//         // PORT A
//         .addra(total_count < BRAM_1_SIZE + BRAM_2_SIZE ? total_count - BRAM_1_SIZE : BRAM_2_SIZE),
//         .dina(0), // we only use port A for reads!
//         .clka(clk_100mhz),
//         .wea(1'b0), // read only
//         .ena(1'b1),
//         .rsta(sys_rst),
//         .regcea(1'b1),
//         .douta(douta_pt),
//         // PORT B
//         .addrb(addrb_pt),
//         .dinb(dinb_pt),
//         .clkb(clk_100mhz),
//         .web(1'b1), // write always
//         .enb(1'b1),
//         .rstb(sys_rst),
//         .regceb(1'b1),
//         .doutb() // we only use port B for writes!
//         );

   parameter SK_BRAM_WIDTH = 4; //1;
   parameter SK_BRAM_DEPTH = 196_000; // 784_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
   parameter SK_ADDR_WIDTH = $clog2(SK_BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [SK_BRAM_WIDTH-1:0]     douta_sk;
   logic [SK_ADDR_WIDTH-1:0]     addra_sk;

   // only using port b for writes: we only use din
   logic [SK_BRAM_WIDTH-1:0]     dinb_sk;
   logic [SK_ADDR_WIDTH-1:0]     addrb_sk;
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
         .evt_in(new_data_out_buf),
         .count_out(total_count));
 
 
 
    // TODO: instantiate another event counter that increments with each new UART data byte
    // for addressing the (port B) place to send our UART_RX data!
    evt_counter #(.MAX_COUNT(BRAM_DEPTH)) port_b_counter(
         .clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .evt_in(new_data_out),
         .count_out(addrb));
 
    // reminder TODO: go up to your PWM module, wire up the speaker to play the data from port A dout.

endmodule // top_level

`default_nettype wire
