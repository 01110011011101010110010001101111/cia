import cocotb
import os
import random
import sys
from math import log
import logging
from cocotb.clock import Clock #useful for sequential logic
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from pathlib import Path
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

@cocotb.test()
async def test_parity_checker(dut):
    """Cocotb test for parity_checker module"""

    # Define test cases: (data_in, expected_parity_out)
    test_cases = [
        (0b00000001, 0), 
        (0b00000000, 1), 
        (0b00000000, 1), 
        (0b00000001, 0), 
        (0b00000100, 0), 
        (0b00001000, 0), 
        (0b00010000, 0), 
        (0b00100000, 0), 
        (0b01000000, 0), 
        (0b10000000, 0),
        (0b00000000, 1),  # 0 ones -> even parity
        (0b00000001, 0),  # 1 one -> odd parity
        (0b00000011, 1),  # 2 ones -> even parity
        (0b00000111, 0),  # 3 ones -> odd parity
        (0b00001111, 1),  # 4 ones -> even parity
        (0b11111111, 1),  # 8 ones -> odd parity
        (0b10101010, 1),  # 4 ones -> even parity
        (0b01010101, 1),  # 4 ones -> even parity
        (0b11000011, 1),  # 4 ones -> even parity
        (0b11110000, 1),  # 4 ones -> even parity
    ]

    for data_in, expected_parity in test_cases:
        dut.data_in <= data_in

        await Timer(10, units="ns")

        assert dut.parity_out == expected_parity, f"Input: {data_in:08b}, Expected parity_out: {expected_parity}, but got: {dut.parity_out}"

        await Timer(10, units="ns")

# @cocotb.test()
# async def test_a(dut):
#     """cocotb test for parity_checker testing"""
#     dut.data_in <= 0 
#     assert dut.parity_out == 1
# 
#     dut.data_in <= 91 
#     assert dut.parity_out == 0
# 
#     dut.data_in <= 198
#     assert dut.parity_out == 1

def parity_checker_runner():
    """Simulate the adder using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "parity_checker.sv"]
    build_test_args = ["-Wall"]
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="parity_checker",
        always=True,
        build_args=build_test_args,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="parity_checker",
        test_module="test_parity_checker",
        test_args=run_test_args,
    )

if __name__ == "__main__":
    parity_checker_runner()
