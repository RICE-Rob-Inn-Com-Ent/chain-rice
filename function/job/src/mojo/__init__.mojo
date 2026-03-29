# Kernels Mojo (kompilacja z `function/`: `mojo package job/src/mojo -o job/src/mojo/build/sage.mojopkg`).

from .simd import broadcast_f32x8, dot_f32x8, dot_i32x8, fma_f32x8
from .matrix import det_2x2_f32, inverse_2x2_f32, lu_decompose_2x2_f32, matmul_2x2_f32, transpose_2x2_f32
from .embed import cosine_f32x8, l2_norm_f32x8
from .tokenize import bpe_pad_to_multiple, vocab_lookup_bounded
from .fft import dft4_real_f32, hann_window_4, ifft4_real_energy_placeholder
from .ode import euler_scalar_exp_step, rk4_scalar_exp_step
from .monte import lcg_u64, u01_from_u64
from .polars import mean_f32x8, rolling_sum_f32x8
from .conv import conv1d_same_f32x8_k3
