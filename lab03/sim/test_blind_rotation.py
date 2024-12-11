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
async def test_blind_rotation(dut):
    """Cocotb test, checks if inputs are as expected, will output be as expected"""
    dut._log.info("Starting...")

    # EVEN CYCLE

    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    dut.valid_data_in.value = 0
    await ClockCycles(dut.clk_in, 3, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5, rising=False)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5, rising=False)
    dut.rotation_amount.value = 2
    dut.addr.value = 5
    dut.data_in.value = 0

    dut.valid_data_in.value = 1

    await RisingEdge(dut.valid_data_out)

    dut.valid_data_in.value = 0

    assert dut.new_addr.value == 4
    assert dut.data_out.value == 0

    await ClockCycles(dut.clk_in, 5, rising=False)
    
    dut.addr.value = 4
    dut.data_in.value = 3
    dut.valid_data_in.value = 1

    await RisingEdge(dut.valid_data_out)
    # await ClockCycles(dut.clk_in, 5, rising=False)
    dut.valid_data_in.value = 0

    assert dut.new_addr.value == 3
    assert dut.data_out.value == 3
 
    # ODD CYCLE

    dut.rst_in.value = 0
    dut.valid_data_in.value = 0
    await ClockCycles(dut.clk_in, 3, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 5, rising=False)
    dut.rst_in.value = 0

    dut.rotation_amount.value = 1
    dut.addr.value = 5
    dut.data_in.value = 0

    dut.valid_data_in.value = 1

    await ClockCycles(dut.clk_in, 1, rising=False)

    dut.valid_data_in.value = 0

    await ClockCycles(dut.clk_in, 5, rising=False)
    
    dut.addr.value = 4
    dut.data_in.value = 3
    dut.valid_data_in.value = 1

    await RisingEdge(dut.valid_data_out)
    # await ClockCycles(dut.clk_in, 5, rising=False)
    dut.valid_data_in.value = 0

    # assert dut.new_addr.value == 3
    # assert dut.data_out.value == 3
    print(dut.new_addr.value)
    assert dut.new_addr.value == 4
    assert dut.data_out.value == 1
    await ClockCycles(dut.clk_in, 5, rising=False)



    #   input wire   [BITMASK_SIZE-1:0]   rotation_amount,
    #   input wire   [$clog2(BRAM_MAX_SIZE)-1:0]  addr,
    #   output logic [DATA_SIZE-1:0]      data_in,
    #   input wire                        valid_data_in,
    #   output logic                      valid_data_out,
    #   output logic [$clog2(BRAM_MAX_SIZE)-1:0]  new_addr,
    #   output logic [DATA_SIZE-1:0]    data_out




def is_runner():
    """blind rotation tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "blind_rotation.sv"]
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="blind_rotation",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="blind_rotation",
        test_module="test_blind_rotation",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()
