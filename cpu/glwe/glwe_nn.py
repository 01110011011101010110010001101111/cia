# Quantization code from Song Han's TinyML class
import torch

import matplotlib.pyplot as plt

import numpy as np

from PIL import Image

def get_quantized_range(bitwidth):
    quantized_max = (1 << (bitwidth - 1)) - 1
    quantized_min = -(1 << (bitwidth - 1))
    return quantized_min, quantized_max

def get_quantization_scale_and_zero_point(fp_tensor, bitwidth):
    """
    get quantization scale for single tensor
    :param fp_tensor: [torch.(cuda.)Tensor] floating tensor to be quantized
    :param bitwidth: [int] quantization bit width
    :return:
        [float] scale
        [int] zero_point
    """
    quantized_min, quantized_max = get_quantized_range(bitwidth)
    fp_max = fp_tensor.max()
    fp_min = fp_tensor.min()

    # scale
    scale = (fp_max - fp_min) / (quantized_max - quantized_min)
    # zero_point
    zero_point = ((quantized_min - fp_min / scale))

    # clip the zero_point to fall in [quantized_min, quantized_max]
    if zero_point < quantized_min:
        zero_point = quantized_min
    elif zero_point > quantized_max:
        zero_point = quantized_max
    else: # convert from float to int using round()
        zero_point = round(zero_point)
    return scale, int(zero_point)

def linear_quantize(fp_tensor, bitwidth, scale, zero_point, dtype=np.int8) -> np.array:
    """
    linear quantization for single fp_tensor
      from
        r = fp_tensor = (quantized_tensor - zero_point) * scale
      we have,
        q = quantized_tensor = int(round(fp_tensor / scale)) + zero_point
    :param tensor: [np.array] floating tensor to be quantized
    :param bitwidth: [int] quantization bit width
    :param scale: [float] scaling factor
    :param zero_point: [int] the desired centroid of tensor values
    :return:
        [np.array] quantized tensor whose values are integers
    """
    # assert(fp_tensor is np.array)
    assert(isinstance(scale, float))
    assert(isinstance(zero_point, int))

    # scale the fp_tensor
    scaled_tensor = fp_tensor/scale
    # round the floating value to integer value
    rounded_tensor = (np.round(scaled_tensor)) #.to(torch.int8)

    # print(rounded_tensor.dtype)

    # shift the rounded_tensor to make zero_point 0
    shifted_tensor = rounded_tensor + zero_point

    # clamp the shifted_tensor to lie in bitwidth-bit range
    quantized_min, quantized_max = get_quantized_range(bitwidth)
    quantized_tensor = shifted_tensor.clip(quantized_min, quantized_max)
    quantized_tensor = quantized_tensor.astype(np.int8)
    return quantized_tensor

def linear_quantize_feature(fp_tensor, bitwidth):
    """
    linear quantization for feature tensor
    :param fp_tensor: [torch.(cuda.)Tensor] floating feature to be quantized
    :param bitwidth: [int] quantization bit width
    :return:
        [torch.(cuda.)Tensor] quantized tensor
        [float] scale tensor
        [int] zero point
    """
    scale, zero_point = get_quantization_scale_and_zero_point(fp_tensor, bitwidth)
    quantized_tensor = linear_quantize(fp_tensor, bitwidth, scale, zero_point)
    return quantized_tensor, scale, zero_point

checkpoint = torch.load("./NN/MNIST_3.pt")
# checkpoint = torch.load("./NN/MNIST_12_layers.pt")

weights_biases = {}

for name, param in checkpoint.items():
    weights_biases[name] = param.cpu().numpy()  # Convert to numpy array and store

int8_quant = {}

for key in weights_biases:
    print(key)
    int8_quant[key] = linear_quantize_feature(weights_biases[key], 8)[0]