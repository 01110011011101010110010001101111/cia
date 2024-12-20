module lsfr_rand
 #(parameter BITMASK = 32'b1110110110111000100000110100000)
  (
            input wire clk_in,
            input wire rst_in,
            input wire data_valid_in,
            input wire data_in,
            output logic [31:0] data_out);

    always_ff @(posedge clk_in)begin
        if (rst_in) begin
            data_out <= ~(31'b0);
        end else begin
            if (data_valid_in) begin
                integer i;
                for (i = 0; i < 32; i = i + 1) begin
                    if (i == 0) begin
                        data_out[i] <= data_in ^ data_out[31];
                    end else if (BITMASK[i]) begin
                        data_out[i] <= data_out[i - 1] ^ data_in ^ data_out[31];
                    end else begin
                        data_out[i] <= data_out[i - 1];
                    end
                end
            end
            // if (data_valid_in) begin
            //     data_out[0] <= data_in ^ data_out[31];
            //     data_out[1] <= data_out[0] ^ data_in ^ data_out[31];
            //     data_out[2] <= data_out[1] ^ data_in ^ data_out[31];
            //     data_out[3] <= data_out[2];
            //     data_out[4] <= data_out[3] ^ data_in ^ data_out[31];
            //     data_out[5] <= data_out[4] ^ data_in ^ data_out[31];
            //     data_out[6] <= data_out[5];
            //     data_out[7] <= data_out[6] ^ data_in ^ data_out[31];
            //     data_out[8] <= data_out[7] ^ data_in ^ data_out[31];
            //     data_out[9] <= data_out[8];
            //     data_out[10] <= data_out[9] ^ data_in ^ data_out[31];
            //     data_out[11] <= data_out[10] ^ data_in ^ data_out[31];
            //     data_out[12] <= data_out[11] ^ data_in ^ data_out[31];
            //     data_out[13] <= data_out[12];
            //     data_out[14] <= data_out[13];
            //     data_out[15] <= data_out[14];
            //     data_out[16] <= data_out[15] ^ data_in ^ data_out[31];
            //     data_out[17] <= data_out[16];
            //     data_out[18] <= data_out[17];
            //     data_out[19] <= data_out[18];
            //     data_out[20] <= data_out[19];
            //     data_out[21] <= data_out[20];
            //     data_out[22] <= data_out[21] ^ data_in ^ data_out[31];
            //     data_out[23] <= data_out[22] ^ data_in ^ data_out[31];
            //     data_out[24] <= data_out[23];
            //     data_out[25] <= data_out[24];
            //     data_out[26] <= data_out[25]  ^ data_in ^ data_out[31];
            //     data_out[27] <= data_out[26];
            //     data_out[28] <= data_out[27];
            //     data_out[29] <= data_out[28];
            //     data_out[30] <= data_out[29];
            //     data_out[31] <= data_out[30];
            // end

        end
    end
endmodule
