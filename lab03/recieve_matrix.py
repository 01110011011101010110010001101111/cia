import serial 
import pickle
import numpy as np
from time import sleep

# 61A8 => 25_000 in hex
# 29501

SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009C1"
BAUD_RATE = 100_000 

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

print("Recording 6 seconds of audio:")
ypoints = []
prev_val = -1

with open('Asm.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]

# # four 0s at the start
# assert int.from_bytes(ser.read(),'little') == 0 
# assert int.from_bytes(ser.read(),'little') == 0 
# assert int.from_bytes(ser.read(),'little') == 0 
# assert int.from_bytes(ser.read(),'little') == 0 

idx = 0
while True:
    print(idx, int.from_bytes(ser.read(),'little'))
    idx += 1
    if idx > 150:
        break
"""
idx = 0
for row in A:
    for val in row:
        # byte_inp = int.from_bytes(ser.read(),'little')
        # print(byte_inp)
        # # assert byte_inp == idx % 256
        # idx += 1

        byte1 = val % 256
        byte2 = (val >> 8) % 256
        byte1_inp = int.from_bytes(ser.read(),'little')
        # # while byte1_inp == 0:
        # # for _ in range(3):
        # #     byte1_inp = int.from_bytes(ser.read(),'little')
        # # sleep(0.002)
        print(idx, byte1, byte1_inp)
        idx += 1
        assert byte1 == byte1_inp
        byte2_inp = int.from_bytes(ser.read(),'little')
        # # sleep(0.002)
        print(idx, byte2, byte2_inp)
        idx += 1
        assert byte2 == byte2_inp

# for val in m:
#     byte_m = int.from_bytes(ser.read(),'little')
#     print(val, byte_m)
#     assert byte_m == val
# 
# for row in s:
#     for val in row:
#         byte1 = val
#         print(byte1, byte1_inp)
#         byte1_inp = int.from_bytes(ser.read(),'little')
#         # assert byte1 == byte1_inp


# for i in range(500):
#     assert int.from_bytes(ser.read(),'little') == 0


# for i in range(((1 + 25)*4)): # + ((1 + 50)*4)):
#     val = int.from_bytes(ser.read(),'little')
#     print(i, val)

    # if (i > 10 and prev_val == 0 and val == 0):
    #     break
    # prev_val = val

 
# SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009C1"
# BAUD_RATE = 115200 
# 
# ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
# print("Serial port initialized")
# 
# with open('/Users/ruth/6.2050/fpga-project/Asm.pkl', 'rb') as f:
#     loaded_data = pickle.load(f)
# 
# A = loaded_data["A"]
# s = loaded_data["s"]
# m = loaded_data["m"]
# 
# def make_num(list, bits):
#     number = 0
#     #for i, val in enumerate(reversed(list)):
#         #number += (val << i*bits)
#     for i, val in enumerate(list):
#         number += (val << i*bits)
#     return number
# 
# def bit_slice(number, start, end):
#     shifted = number >> start
#     mask = (1 << (end - start + 1)) - 1
#     return shifted & mask
# 
# print("Recording 100000 values:")
# ypoints = []
# for i in range(500):
#     for j in range(200):
#         print(f"====================== {i}, {j}")
#         # print(A[i][j])
#         print(make_num(A[i][j//2:j//2+2], 16))
#         ans = bit_slice(make_num(A[i][j//2:j//2+2], 16), j%2*8, j%2*8+7)
#         print(ans)
#         # print(A[i][j//2])
#         bytes = ser.read()
#         val = int.from_bytes(bytes,'little')
# 
#         print(val)
# 
#         assert val == ans, f"{i}, {j} has error!"
#         
# for i in range(251*4):
#     bytes = ser.read()
#     val = int.from_bytes(bytes,'little')
#     print(val)
# 
# for i in range(50*4):
#     print(f"====================== {i}")
#         # print(A[i][j])
#         # print(make_num(A[i][j//2:j//2+2], 16))
#         # ans = bit_slice(make_num(A[i][j//2:j//2+2], 16), j%2*8, j%2*8+7)
#         # print(ans)
#         # print(A[i][j//2])
#     bytes = ser.read()
#     val = int.from_bytes(bytes,'little')
#     print(val)
# 
# for i in range((1)*4):
#     bytes = ser.read()
#     val = int.from_bytes(bytes,'little')
#     # print(val)
# 
# for i in range(500):
#     for j in range(200):
#         print(f"====================== {i}, {j}")
#         s_info = make_num(s[i][2*(j//4):2*(j//4)+2], 1)
#         print(s_info)
#         bytes = ser.read()
#         val = int.from_bytes(bytes,'little')
#         print(val)
# 
#         assert s_info == val, f"s error at {i}, {j}"
# 
# 
#         # assert val == ans, f"{i}, {j} has error!"

# with wave.open('output.wav','wb') as wf:
#     wf.setframerate(8000)
#     wf.setnchannels(1)
#     wf.setsampwidth(1)
#     samples = bytearray(ypoints)
#     wf.writeframes(samples)
#     print("Recording saved to output.wav")



# import serial
# 
# # Set to proper serial port name and baud rate
# SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009C1"
# BAUD_RATE = 115200
# 
# ser = serial.Serial(SERIAL_PORT_NAME, BAUD_RATE)
# print("Serial port initialized")
# 
# # Initialize an empty list to store the matrix
# matrix = []
# 
# # Read data until a specific termination condition is met (e.g., a specific number of rows)
# # Here, we will read until we receive a certain number of rows
# num_rows = 5  # Change this to the expected number of rows in your matrix
# print(f"Reading {num_rows} rows of matrix data:")
# 
# # print("DATA", ser.read())
# val = int.from_bytes(ser.read(),'little')
# print(val)
# 
# 
# 
# # for _ in range(num_rows):
# #     # Read a line from the serial port
# #     line = ser.readline().decode('utf-8').strip()  # Read a line and decode it
# #     # Split the line into values and convert them to floats or integers
# #     row = list(map(float, line.split(',')))  # Change float to int if needed
# #     matrix.append(row)
# #     print(f"Row {_ + 1}: {row}")
# # 
# # Optionally, print the entire matrix
# print("Matrix read from UART:")
# for row in matrix:
#     print(row)
# 
# # Close the serial port
# ser.close()
# 
"""
