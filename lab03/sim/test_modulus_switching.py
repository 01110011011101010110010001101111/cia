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

@cocotb.test()
async def test_modulus_switching(dut):
    """Cocotb test, checks if inputs are as expected, will output be as expected"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    dut.valid_data_in = 0
    await ClockCycles(dut.clk_in, 3, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5, rising=False)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5, rising=False)

    # passing in 16 16
    dut.b_val.value = 0xFF
    dut.valid_data_in = 1
    await RisingEdge(dut.valid_data_out)
    dut.valid_data_in = 0
    assert dut.data_out.value == 0xF
    # should be 0xF

    await ClockCycles(dut.clk_in, 5, rising=False)


def is_runner():
    """blind rotation tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "modulus_switching.sv"]
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="modulus_switching",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="modulus_switching",
        test_module="test_modulus_switching",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()
