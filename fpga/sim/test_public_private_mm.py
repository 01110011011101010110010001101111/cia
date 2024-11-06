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

'''
module private_public_mm(input wire clk_in,
                    input wire rst_in,
                    input wire A_valid,
                    input wire s_valid,
                    input wire [9:0] A_idx,
                    input wire [9:0] s_idx,
                    input wire [23:0] pk_A,
                    input wire [3:0] sk_s,
                    output wire A_ready,
                    output wire s_ready,
                    input wire B_ready,
                    output wire [9:0] idx_B,
                    output wire [47:0] out_B,
                    output wire B_valid
    );
'''

k = 1000
N = 784
q = 64 #64
p = 16

s = [np.random.randint(0, 2, N) for _ in range(k)]
A = [np.random.randint(0, q, N) for _ in range(k)]

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


def make_num(list, bits):
    number = 0
    for i, val in enumerate(reversed(list)):
        number += (val << i*bits)
    return number

def bit_slice(number, start, end):
    shifted = number >> start
    mask = (1 << (end - start + 1)) - 1
    return shifted & mask


@cocotb.test()
async def test_small(dut, N=N, k=k):
    """Cocotb test, checks if inputs are as expected, will output be as expected"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,3, rising=False)
    dut.rst_in.value = 1
    await ClockCycles(dut.clk_in,5, rising=False)

    output = [[0]*N for _ in range(k)]
    
    for h in range(k):
        print(h)
        for i in range(0, N, 4):
            # await RisingEdge(dut.A_ready)
            await ClockCycles(dut.clk_in, 1, rising = False)
            dut.A_valid.value = 1
            dut.pk_A.value = int(make_num(A[h][i:i+4], 6))
            dut.A_idx.value = i
            await ClockCycles(dut.clk_in, 1, rising = False)
            dut.A_valid.value = 0

            for j in range(0, N, 4):
                dut.s_valid.value = 1
                # print("sk_s", int(make_num(s[h][i:i+4], 1)))
                # breakpoint()
                dut.sk_s.value = int(make_num(s[h][j:j+4], 1))
                
                dut.s_idx.value = j

                await ClockCycles(dut.clk_in, 1, rising = False)
                dut.s_valid.value = 0

                await ClockCycles(dut.clk_in, 1, rising = False)

                index_B = dut.idx_B.value
                value_B = dut.B_out.value

                # print(value_B, index_B)
                # breakpoint()

                for l in range(8):
                    if (index_B+l < len(output[h])):
                        output[h][index_B+l] += bit_slice(value_B, l*6, l*6+5)

        assert (output[h][i] == polynomial_mult(A[h], s[h])[i] for i in range(N)), f"Expected {polynomial_mult(A[h], s[h])} but got {output[h]}"





def is_runner():
    """public private mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "public_private_mm.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {"DEPTH": N}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="public_private_mm",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="public_private_mm",
        test_module="test_public_private_mm",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()