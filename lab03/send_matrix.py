# TODO : FOR SOME REASON, ONLY SENDING EVERY OTHER GUY

import serial
import sys
import numpy as np
from time import sleep
import pickle

# set according to your system!
# CHANGE ME
SERIAL_PORTNAME = "/dev/cu.usbserial-88742923009C1"
BAUD = 100_000 # 115_200

with open('Asm.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]

# Function to send a matrix over serial
def send_matrix():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    idx = 0
    for row in A:
        for val in row:
            byte1 = idx % 256 # val >> 8
            idx += 1
            ser.write(int(byte1).to_bytes(1,'little'))
            sleep(0.001)
            byte2 = idx % 256 # val % 256
            idx += 1
            ser.write(int(byte2).to_bytes(1,'little'))
            sleep(0.001)
            # if idx >= 1:
            #     break
    print(idx)
    # for _ in range(int(0.375*idx)):
    #     for _ in range(4):
    #         ser.write(0)
    #         sleep(0.001)

if __name__ == "__main__":
    send_matrix()

