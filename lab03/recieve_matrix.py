import serial 

SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009C1"
BAUD_RATE = 115200 

ser = serial.Serial(SERIAL_PORT_NAME,BAUD_RATE)
print("Serial port initialized")

print("Recording 6 seconds of audio:")
ypoints = []
for i in range(6):
    val = int.from_bytes(ser.read(),'little')
    
    print(val)

    # if ((i+1)%8000==0):
    #     print(f"{(i+1)/8000} seconds complete")
    # ypoints.append(val)

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
