module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 50
      )
      (input wire   clk_in, //system clock (100 MHz)
       input wire   rst_in, //reset in signal
       input wire   [DATA_WIDTH-1:0] data_in, //data to send
       input wire   trigger_in, //start a transaction
       output logic [DATA_WIDTH-1:0] data_out, //data received!
       output logic data_valid_out, //high when output data is present.
 
       output logic chip_data_out, //(COPI)
       input wire   chip_data_in, //(CIPO)
       output logic chip_clk_out, //(DCLK)
       output logic chip_sel_out // (CS)
      );

    
  logic [$clog2(DATA_CLK_PERIOD)-1:0] counter = 0;
  logic [DATA_WIDTH-1:0] count_transactions = 0;
  logic [DATA_WIDTH-1:0] stored_value = 0;
  logic [DATA_WIDTH-1:0] index = 0;
  logic value_outting = 0;
  // logic [DATA_WIDTH+1:0] max_data_size = DATA_WIDTH ** 2;
  logic can_count = 0;
  logic store_data_in;
  logic could_trigger = 0;
  // logic is_data_width = 0;
  logic [DATA_WIDTH-1:0] internal_data_in; //data to send
    
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        // Reset roughly everything
        data_out <= 0;
        data_valid_out <= 0;
        chip_data_out <= 0;
        chip_clk_out <= 0;
        chip_sel_out <= 1;
        count_transactions <= 0;
        counter <= 0;
        could_trigger <= 0;
        can_count <= 0;
        index <= 0;
        stored_value <= 0;
        // internal_data_in <= 0;
    // If we've hit a CLK PERIOD
    end else if (counter+1 == (DATA_CLK_PERIOD/2)) begin
        
        // It's low and we set it to rise (0->1)
        if (chip_clk_out == 0) begin
            // Set it to rise
            chip_clk_out <= 1;
            // Reset the counter
            counter <= 0;
            // stored_value <= (stored_value) | (chip_data_in << count_transactions);
            // Update the stored_value
            stored_value[DATA_WIDTH - 1 - count_transactions] <= chip_data_in; // store_data_in;
            // FOR DEBUGGING: update the index
            index <= DATA_WIDTH - 1 - count_transactions;
            // chip_data_out <= data_in[count_transactions]; //DATA_WIDTH - 1 - count_transactions]; // data_in[(count_transactions+1) % DATA_WIDTH];
            // value_outting <= data_in[count_transactions]; // data_in[DATA_WIDTH - 1 - count_transactions];

        // It's high and we'll set it to drop (1 -> 0)
        end else if (chip_clk_out == 1) begin
            // Set it to drop
            chip_clk_out <= 0;
            // FOR DEBUGGIN: update the index
            index <= DATA_WIDTH - 1 - count_transactions;
            // Reset the counter
            counter <= 0;
            // Set the output
            chip_data_out <= internal_data_in[DATA_WIDTH - 2 - count_transactions]; // data_in[(count_transactions+1) % DATA_WIDTH];
            // value_outting <= internal_data_in[count_transactions]; // data_in[DATA_WIDTH - 1 - count_transactions];
            // Store input (currently not used)
            store_data_in <= chip_data_in;

            // If we've gotten enough to be a full transaction...
            if ((count_transactions+1) == DATA_WIDTH) begin
                // Set chip_sel_out to 1
                chip_sel_out <= 1;
                // We're done counting
                can_count <= 0;
                // Reset number of transactions
                count_transactions <= 0;
                // Move the stored value to data_out
                data_out <= stored_value;
                // Indicate it's valid
                data_valid_out <= 1;
            // Otherwise, increment count_transactions
            end else begin
                count_transactions <= (count_transactions + 1) % (DATA_WIDTH);
                data_valid_out <= 0;
                chip_sel_out <= 0;
            end

        end
    end else begin
        data_valid_out <= 0;
        // Indicate the need to trigger after trigger_in goes back to 0
        if (trigger_in == 1) begin
            could_trigger <= 1;
            chip_sel_out <= 1;
            // Save data_in internally
            internal_data_in <= data_in;

        // Actually start the clock
        end else if (could_trigger) begin
            can_count <= 1; // State for incrementing the clock
            chip_data_out <= internal_data_in[DATA_WIDTH-1]; // set the out to 0
            // store_data_in <= chip_data_in; // store the data (currently not used)
            could_trigger <= 0; // reset the could_trigger
            chip_sel_out <= 0; // reset chip_set_out
        end

        // Increment the clock
        if (can_count) begin
            // counter <= counter == DATA_CLK_PERIOD ? DATA_CLK_PERIOD : counter + 1;
            counter <= (counter + 1) % (DATA_CLK_PERIOD/2);
        end
    end
  end
    

  //your code here
endmodule

