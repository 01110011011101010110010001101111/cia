import serial 
import pickle
import numpy as np

N = 10
p = 2**10
q = 2**16

SERIAL_PORT_NAME = "/dev/cu.usbserial-8874292300481"
BAUD_RATE = 115200 

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

with open('/Users/ruth/6.2050/fpga-project/Asmb.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]
b = loaded_data["b"]

# helper
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

def enc():
    # E = [1, 0, 1, -1] # \in q
    delta = q / p
    # print(delta, LAMBDA, delta/LAMBDA)
    E = np.random.randint(0, 1, N)
    delta_m = np.array(m) * delta

    B = np.array(delta_m) + np.array(E)

    # breakpoint()
    for idx in range(len(A)):
        B += np.array(polynomial_mult(A[idx], s[idx], N, q))
        B %= q

    # B %= q
    # print(B)
    return B

def dec(B):
    B_res = np.array(B)
    for idx in range(len(A)):
        B_res = B_res - np.array(polynomial_mult(A[idx], s[idx], N, q))
    # can check bottom bits and add one if needed
    #return np.round(B_res / (q / p))  % p
    return B_res

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

print("Recording 100000 values:")
ypoints = []
for i in range(500):
    # breakpoint()
    for j in range(20):
        print(f"====================== {i}, {j}")
        # print(A[i][j])
        print(make_num(A[i][j//2:j//2+2], 16))
        ans = bit_slice(make_num(A[i][j//2:j//2+2], 16), j%2*8, j%2*8+7)
        print(ans)
        # print(A[i][j//2])
        bytes = ser.read()
        val = int.from_bytes(bytes,'little')
        print(val)

        # assert val == ans, f"{i}, {j} has error!"
        
for i in range((25251-2500)*4):
    bytes = ser.read()
    val = int.from_bytes(bytes,'little')
    # print(val)

for i in range(5*4):
    print(f"====================== {i}")
        # print(A[i][j])
        # print(make_num(A[i][j//2:j//2+2], 16))
        # ans = bit_slice(make_num(A[i][j//2:j//2+2], 16), j%2*8, j%2*8+7)
        # print(ans)
        # print(A[i][j//2])
    bytes = ser.read()
    val = int.from_bytes(bytes,'little')
    print(val)


for i in range((51-5)*4):
    bytes = ser.read()
    val = int.from_bytes(bytes,'little')
    # print(val)

for i in range(500):
    for j in range(20):
        print(f"====================== {i}, {j}")
        s_info = make_num(s[i][2*(j//4):2*(j//4)+2], 1)
        print(s_info)
        bytes = ser.read()
        val = int.from_bytes(bytes,'little')
        print(val)

        # assert s_info == val, f"s error at {i}, {j}"

for i in range((25001-2500)*4):
    bytes = ser.read()
    val = int.from_bytes(bytes,'little')

print("B IS HERE!!!!!!!!")

b_out = [0]*100

for i in range(5*4):
    print(f"B ====================== {i}")
        # print(A[i][j])
        # print(make_num(A[i][j//2:j//2+2], 16))
        # ans = bit_slice(make_num(A[i][j//2:j//2+2], 16), j%2*8, j%2*8+7)
        # print(ans)
        # print(A[i][j//2])
    bytes = ser.read()
    val = int.from_bytes(bytes,'little')
    print(val)

    b_out[i//2] += (val << (8*(i%2)))

breakpoint()

'''val = int.from_bytes(bytes,'little')
while(val == 0):
    val = int.from_bytes(bytes,'little')
    print("still zero", val)'''

        # assert val == ans, f"{i}, {j} has error!"

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
