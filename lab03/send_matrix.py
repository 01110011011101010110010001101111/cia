# TODO : FOR SOME REASON, ONLY SENDING EVERY OTHER GUY

import serial
import sys
import numpy as np  # You can use NumPy for matrix handling
from time import sleep
import pickle

# set according to your system!
# CHANGE ME
SERIAL_PORTNAME = "/dev/cu.usbserial-88742923009C1"
BAUD = 115_200

with open('Asm.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]

# Function to send a matrix over serial
def send_matrix():
    # # Ensure the matrix is a NumPy array for easier handling
    # if not isinstance(matrix, np.ndarray):
    #     matrix = np.array(matrix)
    # 
    # # Check that the matrix is 2D and has the correct data type
    # assert matrix.ndim == 2, "Matrix must be 2D"
    # assert matrix.dtype == np.uint8, "Matrix must be of type uint8"

    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    idx = 0
    for row in A:
        for val in row:
            # # ser.write(int(idx % 256).to_bytes(1,'little'))
            # # print(idx % 256)
            # # idx += 1
            byte1 = val % 256
            byte2 = (val >> 8) % 256
            print(idx, byte1)
            idx += 1
            ser.write(int(byte1).to_bytes(1,'little'))
            sleep(0.001)
            print(idx, byte2)
            idx += 1
            ser.write(int(byte2).to_bytes(1,'little'))
            sleep(0.001)

    # # # for i in range(500):
    # # #     ser.write(int(0).to_bytes(1,'little')) 
    # # #     sleep(0.001)

    # for val in m:
    #     print(val)
    #     ser.write(int(val).to_bytes(1,'little')) 
    #     sleep(0.001)

    # for row in s:
    #     for val in row:
    #         print(val)
    #         ser.write(int(val).to_bytes(1,'little'))
    #         sleep(0.001)


    # print("Sending matrix!")
    # for idx, sample in enumerate(range((1 + 30)*4)):
    #     # ser.write(sample.tobytes())  # Send each sample as bytes
    #     ser.write(int(sample % 256).to_bytes(1,'little'))
    #     sleep(0.1)
    #     print(idx, sample % 256)
    # print("Matrix sent.")
    # # 101003

    # print("Sending matrix!")
    # for sample in range((1 + 50)*4):
    #     # ser.write(sample.tobytes())  # Send each sample as bytes
    #     ser.write(int(1).to_bytes(1,'little'))
    # print("Matrix sent.")



if __name__ == "__main__":
    # if len(sys.argv) < 2:
    #     print("Usage: python3 send_matrix.py <matrix>")
    #     exit()

    # Example of how to pass a matrix from command line
    # You can modify this part to accept a matrix in a different way
    # For now, let's assume the matrix is hardcoded for demonstration
    # matrix = np.array([[1, 128, 255], [64, 192, 32]], dtype=np.uint8)  # Example matrix
    send_matrix()

