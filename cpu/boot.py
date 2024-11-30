import numpy as np

q = 64
p = 4
delta = q / p
n = 4

s = [0, 1, 1, 0]
m = 1
A = [-25, 12, -3, 7]
E = 1

"""
Modulus Switching
"""

def mod_switching():
    b = A[0] * s[0] + A[1] * s[1] + A[2] * s[2] + A[3] * s[3] + delta * m + E

    w = 32

    scale_factor = w / q

    print("delta", delta % w)
    print("b", b, "b % w", (b * w / q) % w)

    enc_info = np.array([*A, b])

    # addresses annoying rounding bug (-12.5 => -13 not -12 like in original numpy round)
    custom_round = lambda result: np.where(result > 0, np.ceil(result), np.floor(result))

    print(custom_round(enc_info * (w / q)) % w)
    print(np.round(delta * scale_factor))

    def new_decrypt(enc_info, s):
        enc_val = enc_info[-1] - (enc_info[0] * s[0] + enc_info[1] * s[1] + enc_info[2] * s[2] + enc_info[3] * s[3])
        return custom_round(enc_val / w) % w

"""
Sample Extraction
"""

def sample_extraction():

    N = 2
    k = 2

    res_ct = [[1, 4, 6], [3, 5, 7]]
    b = 0
    h = 1

    res_ct.append([0]*k*N)

    for i in range(k):
        for j in range(h+1): 
            res_ct[N][i+j] = res_ct[i][h-j]
    for i in range(k):
        for j in range(h+1, N): 
            res_ct[N][i+j] = res_ct[i][h-j + N]
    b = b

"""
Blind Rotation
"""

def blind_rotation():
    arr = np.array([1, 4, 6, 14, 6])
    bits = [0, 1, 1, 0, 1]

    for b, j in enumerate(bits):
        if b == 1:
            arr = np.roll(arr, -j)

    print(arr)


# """
# GATE BOOTSTRAPPING
# """
# 
# q = 64
# 
# for u1 in (0, 1):
#     for u2 in (0, 1):
# 
# 
#         enc_u1 = q / 8 if u1 else -q / 8
#         enc_u2 = q / 8 if u2 else -q / 8
# 
#         comb = enc_u1 + enc_u2 - q / 8
# 
#         enc_res = -q/8 if comb < 0  else q/8
# 
#         res = comb == q/8
# 
#         print(u1, u2, res)
