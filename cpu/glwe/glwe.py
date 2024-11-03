import numpy as np

# hyperparam selection
k = 1000
N = 784
q = 64
p = 4
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

m = np.random.randint(0, p, N)
s = [np.random.randint(0, 1, N) for _ in range(k)]
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

def enc():
    # E = [1, 0, 1, -1] # \in q
    delta = q / p
    E = np.random.randint(-delta/2, delta/2, N)
    delta_m = np.array(m) * delta

    B = (np.array(polynomial_mult(A[0], s[0], N, q)) +
        np.array(polynomial_mult(A[1], s[1], N, q)) + 
        np.array(delta_m) + np.array(E)) % q

    # print(B)
    return B

def dec(B):
    B_res = np.array(B)
    for idx in range(len(A)):
        B_res = B_res - np.array(polynomial_mult(A[idx], s[idx], N, q))
    # can check bottom bits and add one if needed
    return np.round(B_res / (q / p)) % p

print("enc:", np.array(m) % p)
print("dec:", dec(enc()))