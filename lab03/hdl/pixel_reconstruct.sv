`timescale 1ns / 1ps
`default_nettype none

module pixel_reconstruct
	#(
	 parameter HCOUNT_WIDTH = 11,
	 parameter VCOUNT_WIDTH = 10
	 )
	(
	 input wire clk_in,
	 input wire rst_in,
	 input wire camera_pclk_in,
	 input wire camera_hs_in,
	 input wire camera_vs_in,
	 input wire [7:0] camera_data_in,
	 output logic pixel_valid_out,
	 output logic [HCOUNT_WIDTH-1:0] pixel_hcount_out,
	 output logic [VCOUNT_WIDTH-1:0] pixel_vcount_out,
	 output logic [15:0] pixel_data_out
	 );

	 // your code here! and here's a handful of logics that you may find helpful to utilize.
	 
	 // previous value of PCLK
	 logic pclk_prev;

	 // can be assigned combinationally:
	 //  true when pclk transitions from 0 to 1
	 logic camera_sample_valid;
	 // assign camera_sample_valid = pclk_prev == 0 && camera_pclk_in == 1; // TODO: fix this assign
     always_comb begin
        camera_sample_valid = (pclk_prev == 0 && camera_pclk_in == 1);
        // pclk_prev = camera_pclk_in;
     end
	 
	 // previous value of camera data, from last valid sample!
	 // should NOT update on every cycle of clk_in, only
	 // when samples are valid.
	 logic last_sampled_hs;
	 logic [7:0] last_sampled_data;
     logic h_start = 0;
     logic v_start = 0;
     // TODO: last_sampled_hs

	 // flag indicating whether the last byte has been transmitted or not.
	 logic half_pixel_ready = 0;

	 always_ff@(posedge clk_in) begin
        pclk_prev <= camera_pclk_in;

        if (rst_in) begin
            pixel_hcount_out <= 0;
            pixel_vcount_out <= 0;
            pixel_valid_out <= 0;
            last_sampled_hs <= 0;
            half_pixel_ready <= 0;
            h_start <= 0;
            v_start <= 0;
            // pclk_prev <= 0;
            // camera_sample_valid <= 0;
        end else begin
            // camera_sample_valid <= pclk_prev == 0 && camera_pclk_in == 1;

            if (camera_sample_valid) begin
                last_sampled_hs <= camera_hs_in;
                if (camera_hs_in && camera_vs_in) begin
                    // normal stuff
                    if (!half_pixel_ready) begin
                        // first assignment yay
                        last_sampled_data <= camera_data_in;
                        half_pixel_ready <= 1;
                        pixel_valid_out <= 0;
                    end else begin
                        // export the pixel
                        pixel_valid_out <= 1;
                        pixel_data_out <= {last_sampled_data, camera_data_in};
                        // increase the hcount
                        // TODO: maybe wrap?
                        if (last_sampled_hs) begin
                            if (h_start) begin
                                pixel_hcount_out <= pixel_hcount_out + 1;
                            end else begin
                                h_start <= 1;
                            end
                        end
                        half_pixel_ready <= 0;
                    end

                    if (!last_sampled_hs) begin
                        // last was a 0...
                        // rising edge of hs
                        pixel_hcount_out <= 0;
                        h_start <= 0;
                        if (v_start) begin
                            pixel_vcount_out <= pixel_vcount_out + 1;
                        end else begin
                            v_start <= 1;
                        end
                    end
                end else if (!camera_vs_in) begin
                    // reset
                    pixel_hcount_out <= 0;
                    pixel_vcount_out <= 0;
                    last_sampled_hs <= 0;
                    v_start <= 0;
                    h_start <= 0;
                    pixel_valid_out <= 0;
                    half_pixel_ready <= 0;
                end else if (!camera_hs_in) begin
                    // nothing important, just make sure okay
                    pixel_valid_out <= 0;
                    half_pixel_ready <= 0;
                end
            end else begin
                pixel_valid_out <= 0;
            end
            // else if (!camera_hs_in && camera_vs_in) begin
            //         last_sampled_hs <= 0;
            //         pixel_valid_out <= 0;
            //         // hcount is effectively paused
            //         pixel_hcount_out <= 0;
            //         pixel_vcount_out <= pixel_vcount_out + 1;
            //     end else if (camera_hs_in && !camera_vs_in) begin
            //         last_sampled_hs <= 0;
            //         pixel_valid_out <= 0;
            //         // ??
            //         pixel_vcount_out <= 0;
            //     end else if (!camera_hs_in && !camera_vs_in) begin
            //         last_sampled_hs <= 0;
            //         pixel_valid_out <= 0;
            //         // nothing??
            //         pixel_hcount_out <= 0;
            //         pixel_vcount_out <= 0;
            //     end
            //                        
            // end
             
        end
	 end

endmodule

`default_nettype wire


// `timescale 1ns / 1ps
// `default_nettype none
// 
// module pixel_reconstructor
//   #(
//     parameter HCOUNT_WIDTH = 1280,
//     parameter VCOUNT_WIDTH = 720 
//     )
//    (
//     input wire camera_pclk_in,
//     input wire camera_hs_in,
//     input wire camera_vs_in,
//     input wire [7:0] camera_data_in,
//     output logic pixel_valid_out,
//     output logic [HCOUNT_WIDTH-1:0] pixel_hcount_out,
//     output logic [VCOUNT_WIDTH-1:0] pixel_vcount_out,
//     output logic [15:0] pixel_data_out
//     );
//    
//       // TODO: module to transmit on UART
//       logic [7:0] _prev; 
//       logic _prev_valid = 0; 
//       // logic [7:0] low; 
//       // logic valid_low = 0; 
//       // logic was_valid = 0;
//       // pixel_hcount_out = 0;
//       // pixel_vcount_out = 0;
// 
//       always_ff @(posedge camera_pclk_in) begin
//         
//         // TODO: make into a switch statement?
// 
//         if (camera_hs_in && camera_vs_in) begin
//             // normal stuff
//             if (!_prev_valid) begin
//                 // first assignment yay
//                 _prev <= camera_data_in;
//                 _prev_valid <= 1;
//                 pixel_valid_out <= 0;
//             end else begin
//                 // export the pixel
//                 pixel_valid_out <= 1;
//                 pixel_data_out <= {_prev, camera_data_in};
//                 // increase the hcount
//                 // TODO: maybe wrap?
//                 pixel_hcount_out <= pixel_hcount_out + 1;
//                 _prev_valid <= 0;
//             end
//         end else if (!camera_hs_in && camera_vs_in) begin
//             _prev_valid <= 0;
//             pixel_valid_out <= 0;
//             // hcount is effectively paused
//             pixel_hcount_out <= 0;
//             pixel_vcount_out <= pixel_vcount_out + 1;
//         end else if (camera_hs_in && !camera_vs_in) begin
//             _prev_valid <= 0;
//             pixel_valid_out <= 0;
//             // ??
//             pixel_vcount_out <= 0;
//         end else if (!camera_hs_in && !camera_vs_in) begin
//             _prev_valid <= 0;
//             pixel_valid_out <= 0;
//             // nothing??
//             pixel_hcount_out <= 0;
//             pixel_vcount_out <= 0;
//         end
// 
// 
//         // CAN READ
//         // if (camera_hs_in && camera_vs_in) begin
//         //     // can read the data!!
//         //     // update the appropriate data
//         //     if (!valid_high) begin
//         //         high <= camera_data_in;
//         //         valid_high <= 1;
//         //         was_valid <= 0;
//         //     end else if (!valid_low && !was_valid) begin
//         //         pixel_valid_out <= 1;
//         //         pixel_hcount_out <= pixel_hcount_out + 1 == HCOUNT_WIDTH ? 0 : pixel_hcount_out + 1;
//         //         pixel_data_out <= {high, camera_data_in};
//         //         valid_high <= 0;
//         //         was_valid <= 1;
//         //     end
//         // end else begin
//         //     // ignore the data, blanking period...
//         //     pixel_valid_out <= 0;
//         // end
// 
//         // if (~camera_vs_in) begin
//         //     // full frame is complete, ready to send next frame
//         //     pixel_vcount_out <= 0;
//         //     pixel_hcount_out <= 0;
//         // end else if (~camera_hs_in) begin
//         //     // row is complete, ready to send next row
//         //     pixel_vcount_out <= pixel_vcount_out + 1 == VCOUNT_WIDTH ? 0 : pixel_vcount_out + 1;
//         // end
// 
//       end
// endmodule
// 
// `default_nettype wire
