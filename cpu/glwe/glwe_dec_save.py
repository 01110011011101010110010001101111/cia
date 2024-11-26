import numpy as np
import time
import pickle

# hyperparam selection
k = 500
N = 10
q = 2**16
p = 2**10
# security param for how much noise, keep small if large constant multiplication
LAMBDA = 3

# s = [
#     [0, 1, 1, 0], # x^2 + x 
#     [1, 1, 0, 1]  # x^3 + x^2 + 1
# ]
# 
# m = [-1, 0, 1, -2] # \in p

# A = [
#     [9, -24, -2, 17],
#     [21, -1, 0, -14]
# ] # \in q

m = np.random.randint(0, 2, N)
s = [np.random.randint(0, 2, N) for _ in range(k)]
A = [np.random.randint(0, q, N) for _ in range(k)]


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

def make_num(list, bits):
    number = 0
    #for i, val in enumerate(reversed(list)):
        #number += (val << i*bits)
    for i, val in enumerate(list):
        number += (val << i*bits)
    return number

def enc():
    # E = [1, 0, 1, -1] # \in q
    delta = q / p
    # print(delta, LAMBDA, delta/LAMBDA)
    E = np.random.randint(-delta/LAMBDA, delta/LAMBDA, N)
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
    return np.round(B_res / (q / p))  % p

"""
Operations on ciphertext
"""

def add_ct(ct1, ct2):
    return ct1 + ct2

def add_constant(ct, c):
    return ct + c * q/p

def mul_constant(ct, c):
    return (c * ct)%q

if(True):
    b = enc().astype(int)

    data = {'m': m, 's': s, 'A': A, 'b': b}

    with open('Asmb.pkl', 'wb') as f:
        pickle.dump(data, f)

else:
    with open('Asmb.pkl', 'rb') as f:
        loaded_data = pickle.load(f)

    A = loaded_data["A"]
    s = loaded_data["s"]
    m = loaded_data["m"]
    b = loaded_data["b"]

with open(f'/Users/ruth/6.2050/fpga-project/lab03/data/A.mem', 'w') as f:
    for x in range(k):
        for y in range(0, N, 2):
            f.write(f'{make_num(A[x][y:y+2], 16):X}\n')
        '''for y in range(N, 100, 2):
            f.write(f'{0:X}\n')'''
print('Output image saved at A.mem')

with open(f'/Users/ruth/6.2050/fpga-project/lab03/data/s.mem', 'w') as f:
    for x in range(k):
        for y in range(0, N, 2):
            f.write(f'{make_num(s[x][y:y+2], 1):X}\n')
        '''for y in range(N, 100, 2):
            f.write(f'{0:X}\n')'''
print('Output image saved at s.mem')

with open(f'/Users/ruth/6.2050/fpga-project/lab03/data/pt.mem', 'w') as f:
    for y in range(0, N, 2):
        f.write(f'{make_num(m[y:y+2], 1):X}\n')
    for y in range(N, 100, 2):
            f.write(f'{0:X}\n')
print('Output image saved at pt.mem')

with open(f'/Users/ruth/6.2050/fpga-project/lab03/data/b.mem', 'w') as f:
    for y in range(0, N, 2):
        f.write(f'{make_num(b[y:y+2], 16):X}\n')
    for y in range(N, 100, 2):
            f.write(f'{0:X}\n')
print('Output image saved at b.mem')

'''timing = []

for i in range(100):
    m = np.random.randint(0, p/10, N)
    s = [np.random.randint(0, 2, N) for _ in range(k)]
    A = [np.random.randint(0, q, N) for _ in range(k)]  
    ct = enc()
    x1 = time.perf_counter()
    dec(enc())
    x2 = time.perf_counter()
    timing.append(x2-x1)

print("Average time taken: ", sum(timing)/100)'''

print("inp:", np.array(m) % p)
print("eq: 2x + 1")
print("pt computation:", (2 * (np.array(m) % p)) % p)
print("ct computation:", dec(mul_constant(enc(), 2)))

print("pt computation:", ((np.array(m) % p) + 1) % p)
print("ct computation:", dec(add_constant(enc(), 1)))

print(dec(enc()))
