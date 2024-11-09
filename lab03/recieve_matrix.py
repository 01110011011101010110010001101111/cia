import serial

# Set to proper serial port name and baud rate
SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009C1"
BAUD_RATE = 9600

ser = serial.Serial(SERIAL_PORT_NAME, BAUD_RATE)
print("Serial port initialized")

# Initialize an empty list to store the matrix
matrix = []

# Read data until a specific termination condition is met (e.g., a specific number of rows)
# Here, we will read until we receive a certain number of rows
num_rows = 5  # Change this to the expected number of rows in your matrix
print(f"Reading {num_rows} rows of matrix data:")

print("DATA", ser.readline())

# for _ in range(num_rows):
#     # Read a line from the serial port
#     line = ser.readline().decode('utf-8').strip()  # Read a line and decode it
#     # Split the line into values and convert them to floats or integers
#     row = list(map(float, line.split(',')))  # Change float to int if needed
#     matrix.append(row)
#     print(f"Row {_ + 1}: {row}")
# 
# Optionally, print the entire matrix
print("Matrix read from UART:")
for row in matrix:
    print(row)

# Close the serial port
ser.close()

