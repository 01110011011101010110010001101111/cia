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

    # idx = 0
    # for row in A:
    #     for val in row:
    #         byte1 = idx % 256 # val >> 8
    #         idx += 1
    #         ser.write(int(byte1).to_bytes(1,'little'))
    #         sleep(0.001)
    #         byte2 = idx % 256 # val % 256
    #         idx += 1
    #         ser.write(int(byte2).to_bytes(1,'little'))
    #         sleep(0.001)

    for idx in range(4*(25_250 + 1)):
        byte1 = idx % 256
        ser.write(int(byte1).to_bytes(1,'little'))
        sleep(0.001)

    for idx in range((100 + 1)):
        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        # THESE GUYS DO NOT MATTER
        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(13).to_bytes(1,'little'))
        sleep(0.001)
        print(byte1)

    for idx in range((250 + 1)):
        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        # THESE GUYS DO NOT MATTER
        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(1).to_bytes(1,'little'))
        sleep(0.001)

        byte1 = idx % 256
        ser.write(int(13).to_bytes(1,'little'))
        sleep(0.001)
        print(byte1)

    for idx in range(4*(2_510)):
        byte1 = idx % 256
        ser.write(int(byte1).to_bytes(1,'little'))
        sleep(0.001)
        print(byte1)




if __name__ == "__main__":
    send_matrix()

