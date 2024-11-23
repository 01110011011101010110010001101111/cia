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

s = [np.random.randint(0, 2, N) for _ in range(k)]
A = [np.random.randint(0, q, N) for _ in range(k)]
A[0][0] = 0
A[0][1] = 0
b = [0 for _ in range(N)]
e = [np.random.randint(0, 4) for _ in range(N)]

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

'''
module b_adder 
    #(parameter DEPTH=784, parameter ADD = 1)
    (input wire clk_in,
                    input wire rst_in,
                    input wire poly_valid,
                    input wire [41:0] poly_in,
                    input wire [9:0] poly_idx,
                    output logic poly_ready,
                    input wire e_valid,
                    input wire [23:0] e_in,
                    input wire [9:0] e_idx,
                    output logic e_ready,
                    input wire b_valid,
                    input wire b_in[23:0],
                    output logic b_ready,
                    input wire sum_ready,
                    output logic sum_valid,
                    output logic sum[23:0],
                    output logic sum_idx[9:0]
              );
'''

@cocotb.test()
async def test_small(dut, N=N, k=k):
    b_exp = [e[i] for i in range(N)]

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
    
    for h in range(k):
        # print(h)
        for i in range(0, N, 2):
            # await RisingEdge(dut.A_ready)
            # await ClockCycles(dut.clk_in, 1, rising = False)
            '''dut.poly_valid.value = 1
            dut.B_ready.value = 1
            dut.pk_A.value = int(make_num(A[h][i:i+4], 6))
            dut.A_idx.value = i'''
            # await ClockCycles(dut.clk_in, 1, rising = False)
            # breakpoint()
            # dut.A_valid.value = 0

            for j in range(0, N, 2):
                dut.poly_valid.value = 1

                # breakpoint()
                dut.poly_in.value = int(make_num(polynomial_mult(A[h][i:i+2], s[h][j:j+2], size=3), 18))
                dut.poly_idx.value = i+j

                if (i + j + 2 <= N):
                    dut.e_valid.value = 1
                    dut.e_idx.value = i+j
                    if h == 0 and i == 0:
                        # breakpoint()
                        print("j is ", j, " e is ", e[j:j+2])
                        dut.e_in.value = int(make_num(e[j:j+2], 18))
                    else:
                        dut.e_in.value = 0

                    dut.b_valid.value = 1
                    dut.b_in.value = int(make_num(b[j+i: j+i+2], 18))
                else:
                    pass

                # breakpoint()
                await ClockCycles(dut.clk_in, 1, rising = False)

                dut.b_valid.value = 0
                dut.e_valid.value = 0
                dut.poly_valid.value = 0

                if dut.sum_valid.value:
                    index_sum = dut.sum_idx.value
                    value_sum = dut.sum.value
                    print("===================")
                    print("A", A[h][i:i+2], "S ", s[h][j:j+2])
                    print(polynomial_mult(A[h][i:i+2], s[h][j:j+2], size=3))
                    # print(index_sum)

                    for l in range(2):
                        #print("Correct number: ", something[l])
                        '''print("===================")
                        
                        print("poly ", dut.poly_in.value)
                        print("e ", dut.e_in.value)
                        print("b ", dut.b_in.value)'''
                        if (index_sum+l < len(b)):
                            print("index sum ", index_sum)
                            print(i+j+l)
                            print(index_sum, l, bit_slice(value_sum, l*18, l*18+17))
                            b[index_sum+l] = bit_slice(value_sum, l*18, l*18+17)
                            b[index_sum+l] %= q
                else:
                    index_sum = dut.sum_idx.value
                    value_sum = 0

                print("===================")

                # breakpoint()
                await ClockCycles(dut.clk_in, 1, rising = False)

                # something = [int(x) for x in (polynomial_mult(A[h][i:i+2], s[h][j:j+2]))

            print("I is ", i, " H is ", h)
            print(polynomial_mult(A[h][i:i+2], s[h]))
            # MAKE THIS EXP BETTER INCLUDE LATER B_exp
            b_exp = [b_exp[r] for r in range(i)]+[(polynomial_mult(A[h][i:i+2], s[h])[r-i] + b_exp[r])%q for r in range(i, len(b_exp))]
            assert (np.array_equal(b, b_exp)), f"Expected {[int(x) for x in (b_exp)]} but got {b}" 

        print(h)
        # breakpoint()
        print("All A: ", A[h])
        print("all s: ", s[h])
        print("all e: ", e)
        print(polynomial_mult(A[h], s[h]))
       # breakpoint(q
        # b_exp = [(polynomial_mult(A[h], s[h])[i] + b_exp[i])%q for i in range(len(b_exp))]
        # assert (np.array_equal(b, b_exp)), f"Expected {[int(x) for x in (b_exp)]} but got {b}"    




def is_runner():
    """public private mult tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "b_adder.sv"]
    # sources += [proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v"]
    build_test_args = ["-Wall"]
    parameters = {"DEPTH": N}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="b_adder",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="b_adder",
        test_module="test_b_adder",
        test_args=run_test_args,
        waves = True
    )

if __name__ == "__main__":
    is_runner()