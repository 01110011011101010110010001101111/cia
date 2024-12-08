# TODO : FOR SOME REASON, ONLY SENDING EVERY OTHER GUY

import serial
import sys
import numpy as np
from time import sleep
import pickle

# set according to your system!
# CHANGE ME
SERIAL_PORTNAME = "/dev/cu.usbserial-8874292300481"
BAUD = 100_000 # 115_200

with open('/Users/ruth/6.2050/fpga-project/enc_Asm.pkl', 'rb') as f:
    loaded_data = pickle.load(f)

A = loaded_data["A"]
s = loaded_data["s"]
m = loaded_data["m"]

def make_num(list, bits):
    number = 0
    #for i, val in enumerate(reversed(list)):
        #number += (val << i*bits)
    for i, val in enumerate(list):
        number += (val << i*bits)
    return number

# Function to send a matrix over serial
def send_matrix():
    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    for i in range(100):
        for j in range(500):
            for k in range(2):
                byte1 = (A[i][j] >> k*8) % 256
                # print(byte1)
                ser.write(int(byte1).to_bytes(1,'little'))
                sleep(0.001)

    for idx in range(4*(250 + 1)):
        byte1 = 0
        ser.write(int(byte1).to_bytes(1,'little'))
        sleep(0.001)

    for idx in range((100 + 1)):
        byte1 = m[idx] if idx < 100 else 0
        ser.write(int(byte1).to_bytes(1,'little'))
        sleep(0.001)

        # THESE GUYS DO NOT MATTER
        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)
        # print(byte1)

    for idx in range((250 + 1)):
        byte1 = make_num(s[2*idx:2*idx+2], 1) if idx < 250 else 0
        print(byte1)
        ser.write(int(byte1).to_bytes(1,'little'))
        sleep(0.001)

        # THESE GUYS DO NOT MATTER
        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)
        # print(byte1)

    for idx in range(4*(2_510)):
        byte1 = idx % 256
        ser.write(int(0).to_bytes(1,'little'))
        sleep(0.001)
        # print(byte1)




if __name__ == "__main__":
    send_matrix()

