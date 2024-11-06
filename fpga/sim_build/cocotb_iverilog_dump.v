module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/ruth/6.2050/fpga-project/fpga/sim_build/public_private_mm.fst");
    $dumpvars(0, public_private_mm);
end
endmodule
