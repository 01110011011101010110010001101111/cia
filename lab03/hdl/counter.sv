module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );

    // your code here
    //always_ff @(posedge rst_in) begin
    //    count_out <= 0;
    //end
  
    always_ff @(posedge clk_in or posedge rst_in)begin
        count_out <= rst_in ? 0 : count_out+1 == period_in ? 0 : count_out+1;
    end
    
  
endmodule

