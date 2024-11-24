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

@cocotb.test()
async def test_top_level(dut):
    """
    Test top level
    """

    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_100mhz, 10, units="ns").start())

    dut.btn[0].value = 1
    dut.sw[0].value = 0
    dut.sw[1].value = 1
    dut.sw[2].value = 0
    await ClockCycles(dut.clk_100mhz, 5, rising=False)
    dut.btn[0].value = 0
    await ClockCycles(dut.clk_100mhz, 1, rising=False)

    dut.sw[0].value = 1
    for j in range(10):
        await ClockCycles(dut.clk_100mhz, 200, rising=False)
        # print(dut.douta.value)

    dut.sw[0].value = 0
    await Timer(10, units="ns")  # Small delay to observe the result

def is_runner():
    """public private mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "top_level.sv"]
    sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_2_clock_ram.v"]

    hdl_path = proj_path / "hdl"
    sources += list(hdl_path.rglob("*.sv"))

    sources = list(set(sources))

    print(sources)

    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top_level",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="top_level",
        test_module="test_top_level",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()