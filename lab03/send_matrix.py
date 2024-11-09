import serial
import sys
import numpy as np  # You can use NumPy for matrix handling

# set according to your system!
# CHANGE ME
SERIAL_PORTNAME = "/dev/cu.usbserial-88742923009C1"
BAUD = 115200

# Function to send a matrix over serial
def send_matrix(matrix):
    # Ensure the matrix is a NumPy array for easier handling
    if not isinstance(matrix, np.ndarray):
        matrix = np.array(matrix)

    # Check that the matrix is 2D and has the correct data type
    assert matrix.ndim == 2, "Matrix must be 2D"
    assert matrix.dtype == np.uint8, "Matrix must be of type uint8"

    ser = serial.Serial(SERIAL_PORTNAME, BAUD)

    print("Sending matrix!")
    for row in matrix:
        for sample in row:
            ser.write(sample.tobytes())  # Send each sample as bytes
            # ser.write(sample.to_bytes(1,'little'))
    print("Matrix sent.")

if __name__ == "__main__":
    # if len(sys.argv) < 2:
    #     print("Usage: python3 send_matrix.py <matrix>")
    #     exit()

    # Example of how to pass a matrix from command line
    # You can modify this part to accept a matrix in a different way
    # For now, let's assume the matrix is hardcoded for demonstration
    matrix = np.array([[0, 128, 255], [64, 192, 32]], dtype=np.uint8)  # Example matrix
    send_matrix(matrix)

