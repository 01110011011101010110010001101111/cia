module parity_checker 
    #(parameter WIDTH = 8)
    (  input wire[(WIDTH-1):0] data_in,
        output logic parity_out);
  always_comb begin
    logic answer;
    answer = 1'b1;

    for (int i = 0; i < WIDTH; i += 1) begin
        answer = (answer ^ data_in[i]);
    end

    parity_out = answer;

  end
endmodule
