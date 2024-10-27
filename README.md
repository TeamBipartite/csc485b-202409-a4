# CSC485b Fall 2024 A2
Johnathan Warawa & Emily Martins


# Build
A makefile is provided in  the top-level directory which handles building the application. 
The default target is `sm_75` (eg, Compute Capability 7.5 graphics cards such as the Turing T4). 
```bash
$ make
```

To specify the `arch` string for your target, use the `TARGET` variable when
calling `make`. For example, for a Compute Capability 8.6 graphics card such as the RTX 3060, use:
```bash
$ make TARGET=sm_86
```

The following options may also be specified using environment variables:
    - `USE_OPENBLAS=yes`: By default, the OpenBLAS library is called to
      perform a CPU matrix multiplication to serve as a baseline to check for
      correctness. If you do not have OpenBLAS on your system, set this variable
      to `no` to use a naive provided n^3 CPU implementation.
    - `OPENBLAS_NUM_THREADS=$(nproc)`: If `USE_OPENBLAS=yes`, this option can be
      specified to reduce the number of threads used by OpenBLAS. 
    - `USE_WARP_PRIMITIVES=yes`: Set to `no` to use an unoptimized solution
      which does not exploit warp primitives.

# Run

A single executable, `a2` is producted. Simply run this file.
