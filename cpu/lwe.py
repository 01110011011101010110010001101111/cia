from typing import List
import random  # for generating random `r`
from constants import *

class LWE:
    def __init__(self, A, m, n, q, B=1):
        """
        Instantiate an instance of A

        A: public key of size m x n base q
        """
        self.A = A
        self.m = m
        self.n = n
        assert(len(A) == m and len(A[0]) == n)
        self.q = q
        self.B = B
        # check B m << q / 4
        SCALAR = 10
        assert(B * n < SCALAR * q / 4)

    def vector_matrix_multiply(self, vec, matrix):
        """
        vector matrix multiplication (manual)
        vec @ matrix mod q
        """
        # final result
        solution = []

        # multiply with A
        for row in range(m):
            subans = 0
            for col in range(n):
                subans = (subans + matrix[row][col] * vec[col]) % self.q
            solution.append(subans)
        return solution
        

    # generates noise e \in [-B, B]
    def generate_e(self, B = None):
        """
        Generates noise (e) for LWE
        will generate a vector where each element is in [-B, B] where B << q
        """
        if B is None:
            B = self.B
        e = []
        for _ in range(self.m):
            e.append(random.randint(-B, B))
        return e

    # def enc(self, b: List[int], s: List[int]) -> List[int]:
    def enc(self, b, s) -> List[int]:
        """
        encode bit b
        """
        return (
            self.vector_matrix_multiply(s, self.A) + 
            self.generate_e() + 
            [(bi * q // 2) % q for bi in range(self.m)]
        )
        
    def subtract_lists(self, list1, list2):
        ans = []
        for val1, val2 in zip(list1, list2):
            ans.append(abs(val1 - val2))
        return ans

    def mask_list(self, list1, fn):
        return [fn(ele) for ele in list1]

    def dec(self, ct, s):
        return self.mask_list(self.subtract_lists(ct, self.vector_matrix_multiply(s, self.A)), lambda x: (x > self.q / 4))

if __name__ == "__main__":
    # setup
    lwe = LWE(A, m, n, q)

    pt = [random.randint(0, 1) for _ in range(m)] # TODO
    s = [random.randint(0, q-1) for _ in range(n)]
    assert pt == lwe.dec(lwe.enc(pt, s))
