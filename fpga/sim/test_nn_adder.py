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

k = 10
N = 12
q = 2**18 #64
p = 16

nn_output = 10
nn_range = 2**2

# s = [np.random.randint(0, 2, N) for _ in range(k)]
A = np.array([np.random.randint(0, q, k+1) for _ in range(N)])
nn = np.array([np.random.randint(-nn_range, nn_range, N) for _ in range(nn_output)])

# b = [0 for _ in range(N)]
# e = [np.random.randint(0, 4) for _ in range(N)]

# fun pumpkin great appetite thanksgiving (FPGA thanksgiving)


''' def polynomial_mult(s0, s1, size=N, base=q):
    result = [0] * (size)

    # Multiply the coefficients
    for i in range(len(s0)):
        for j in range(len(s1)):
            if i + j < size:
                result[i + j] += s0[i] * s1[j]

    for i in range(len(result)):
        result[i] = result[i] % base

    return result '''

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

'''
module nn_adder
    #(parameter K_VAL=501,
    parameter DEPTH = 100, parameter OUT_NODES = 10)
    (input wire clk_in,
                    input wire rst_in,
                    input wire pk_valid,
                    input wire [9:0] idx_k_in,
                    input wire [9:0] idx_N_in,
                    input wire [35:0] ct_in,
                    output logic ct_ready,
                    input wire weights_valid,
                    input wire [2:0] weights_in,
                    input wire [5:0] weight_idx, // 0-10
                    output logic weights_ready,

                    input wire sum_ready,
                    output logic sum_valid,
                    output logic [35:0] sum_out,
                    output logic [9:0] sum_idx_k,
                    output logic [9:0] sum_idx_N,
                    output logic [5:0] sum_idx_w
              );
'''

@cocotb.test()
async def test_small(dut, N=N, k=k):
    nn_result = np.array([np.zeros(k+1) for _ in range(nn_output)]).astype(int)

    """Cocotb test, checks if inputs are as expected, will output be as expected"""
    dut._log.info("Starting...")
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,3, rising=False)
    dut.rst_in.value = 1
    dut.sum_ready.value = 1
    await ClockCycles(dut.clk_in,5, rising=False)
    dut.rst_in.value = 0
    await ClockCycles(dut.clk_in,5, rising=False)
    
    for h in range(N):
        # print(h)
        for i in range(0, k+2, 2):
            # load ct into it
            if i == k:
                dut.ct_in.value = int(make_num([A[h, i], 0], 18))
            else:
                dut.ct_in.value = int(make_num(A[h, i:i+2], 18))

            dut.idx_k_in.value = i
            dut.idx_N_in.value = h

            dut.ct_valid.value = 1

            await ClockCycles(dut.clk_in, 1, rising=False)

            dut.ct_valid.value = 0

            await ClockCycles(dut.clk_in, 1, rising=False)
            
            for j in range(nn_output):
                dut.weights_in.value = int(make_num([nn[j][h]], 3))
                dut.weights_valid.value = 1
                dut.weights_idx.value = j

                # breakpoint()
                if i == k:
                    dut.mem_in.value = int(make_num([nn_result[j, i], 0], 18))
                else:
                    dut.mem_in.value = int(make_num(nn_result[j, i:i+2], 18))

                dut.mem_valid.value = 1


                if j == 0:
                    await ClockCycles(dut.clk_in, 2, rising=False)
                else:
                    await ClockCycles(dut.clk_in, 1, rising=False)

                dut.weights_valid.value = 0
                dut.mem_valid.value = 0

                # breakpoint()

                if dut.sum_valid.value:
                    sum_out = dut.sum_out.value
                    nn_result[j][i] = bit_slice(sum_out, 0, 17)
                    # nn_result[j][i] %= q
                    if i < k:
                        nn_result[j][i+1] = bit_slice(sum_out, 18, 35)
                        # nn_result[j][i+1] %= q

        # breakpoint()
        output = np.dot(nn[:, 0:h+1], np.array(A[0:h+1, :]))%q
        print(output)
        print(nn_result)
        assert np.array_equal(output, nn_result), f"Uh oh 1 {np.where(output != nn_result)}"

    # breakpoint()
    output = np.dot(nn, A)%q
    print(output)
    print(nn_result)
    print(np.array_equal(output, nn_result))
    assert np.array_equal(output, nn_result) == True, "Uh oh"

             




def is_runner():
    """nn mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "nn_adder.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {"DEPTH": N, "K_VAL": k+1, "OUT_NODES": nn_output}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="nn_adder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="nn_adder",
        test_module="test_nn_adder",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()