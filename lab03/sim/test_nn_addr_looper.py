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
import pickle

k = 500
N = 100
q = 2**16

@cocotb.test()
async def test_loop(dut):
    """
    Test top level b_adder
    """

    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())

    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in, 5, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in, 1, rising=False)

    dut.rst_in.value = 0
    dut.begin_nn.value = 1
    await ClockCycles(dut.clk_in, 5, rising=False)
    for h in range(5000):
        await ClockCycles(dut.clk_in, 1, rising=False)

def is_runner():
    """public private mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "nn_addr_looper.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v"]

    hdl_path = proj_path / "hdl"
    sources += list(hdl_path.rglob("*.sv"))

    sources = list(set(sources))

    print(sources)

    build_test_args = ["-Wall"]
    parameters = {"DEPTH":16, "K":32}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="nn_addr_looper",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="nn_addr_looper",
        test_module="test_nn_addr_looper",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()