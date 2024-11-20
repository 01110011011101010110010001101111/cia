module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/paromitadatta/Documents/6/6205/lab03/sim/sim_build/uart_receive.fst");
    $dumpvars(0, uart_receive);
end
endmodule
