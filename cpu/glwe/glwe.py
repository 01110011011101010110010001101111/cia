import numpy as np

# hyperparam selection
k = 5
N = 4
q = 64
p = 16
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

m = np.random.randint(0, p/3, N)
s = [np.random.randint(0, 2, N) for _ in range(k)]
A = [np.random.randint(0, q, N) for _ in range(k)]

# breakpoint()

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
    return (c * ct)

print("inp:", np.array(m) % p)
print("eq: 2x + 1")
print("pt computation:", (2 * (np.array(m) % p)) % p)
print("ct computation:", dec(mul_constant(enc(), 2)))

print("pt computation:", ((np.array(m) % p) + 1) % p)
print("ct computation:", dec(add_constant(enc(), 1)))

print(dec(enc()))
