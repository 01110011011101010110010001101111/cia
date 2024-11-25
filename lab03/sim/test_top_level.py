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

with open('/Users/ruth/6.2050/fpga-project/Asm.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]

def polynomial_mult(s0, s1, size=N, base=q):
    result = [0] * (size)

    # Multiply the coefficients
    for i in range(len(s0)):
        for j in range(len(s1)):
            if i + j < size:
                result[i + j] += s0[i] * s1[j]

    for i in range(len(result)):
        result[i] = result[i] % base

    return result

def reverse_bits(n, bit_length=32):
    reversed_num = 0
    for _ in range(bit_length):
        reversed_num = (reversed_num << 1) | (n & 1)
        n >>= 1
    return reversed_num

def make_num(list, bits):
    number = 0
    #for i, val in enumerate(reversed(list)):
        #number += (val << i*bits)
    for i, val in enumerate(list):
        number += (val << i*bits)
    return number

def bit_slice(number, start, end):
    shifted = number >> start
    mask = (1 << (end - start + 1)) - 1
    return shifted & mask

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
    await ClockCycles(dut.clk_100mhz, 4, rising=False)
    for h in range(1):
        for i in range(0, 100 , 2):
            for j in range(0, 100, 2):
                something = [int(x) for x in (polynomial_mult(A[h][i:i+2], s[h][j:j+2]))]

                value_B = dut.B_out_enc.value
                index_B = dut.idx_poly_out_enc.value

                print(value_B)

                for l in range(4):
                        print("Correct number: ", something[l])
                        print(bit_slice(value_B, l*16, l*16+15))

                        assert bit_slice(value_B, l*16, l*16+15) == something[l], "bro you screwed up"
                        # if (index_B+l < len(output[h])):
                            # output[h][index_B+l] += bit_slice(value_B, l*16, l*16+15)
                            # output[h][index_B+l] %= q

                # breakpoint()
                await ClockCycles(dut.clk_100mhz, 1, rising=False)
                # check that output of public_private is correct DONE
                # TODO: check that output of b_adder is correct
                # test it on the FPGA :)

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