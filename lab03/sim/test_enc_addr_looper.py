import cocotb
import os
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
import numpy as np
import random

N = 20
k = 15

'''
module enc_addr_looper
    #(parameter DEPTH=100, parameter K=500)
    (input wire clk_in,
                    input wire rst_in,
                    input wire begin_enc,
                    output logic [9:0] A_addr,
                    output logic [9:0] s_addr,
                    output logic [9:0] b_addr,
                    output logic [9:0] e_addr,
                    output logic e_zero,
                    output logic addr_valid
              );
'''

@cocotb.test()
async def test_small(dut, N=N, k=k):

    """Cocotb test, checks if inputs are as expected, will output be as expected"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,3, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,5, rising=False)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,5, rising=False)
    
    dut.begin_enc.value = 1
    await ClockCycles(dut.clk_in, 1, rising=False)  
    dut.begin_enc.value = 0

    await ClockCycles(dut.clk_in, 500, rising=False)  





def is_runner():
    """public private mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "enc_addr_looper.sv"]
    sources += [proj_path / "hdl" / "evt_counter.sv"]
    build_test_args = ["-Wall"]
    parameters = {"DEPTH": N, "K": k}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="enc_addr_looper",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="enc_addr_looper",
        test_module="test_enc_addr_looper",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()