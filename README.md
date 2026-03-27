# rv32f_fpu

This floating point unit is written in **SystemVerilog** and conforms to IEEE 754-2008 standards. It has been developed into a complete **RISC-V RV32F FPU subsystem**, featuring integrated instruction decoding, a dedicated floating-point register file (FPRF), and a control/status register (FCSR) for accrued exceptions and dynamic rounding.

Supported operations are **compare**, **min-max**, **conversions**, **addition**, **subtraction**, **multiplication**, **fused multiply add**, **square root** and **division** in 32-bit single precision. Except **square root** and **division** all operations are pipelined.

### Pseudo Extended Precision Architecture
This floating-point unit (FPU) internally converts the standard 32-bit single-precision format into a 33-bit pseudo-extended precision format. The primary advantage of this implementation is reduced hardware resource utilization, as it avoids introducing complex subnormal number extension logic throughout the pipeline. As a result, all floating-point numbers (including subnormals) are treated as normalized numbers within the datapath.

|        | sign | exponent | mantissa |
|:------:|:----:|:--------:|:--------:|
| single | 1    | 8        | 23       |
| pseudo | 1    | 9        | 23       |

## PROJECT STRUCTURE

The repository is organized as follows to separate synthesizable RTL, verification environments, and utility scripts.The core architecture is decoupled into a control/state wrapper (fpu_subsystem) and a pure arithmetic datapath (fpu_top).

```text
rv32f_fpu/
├── README.md               # Project documentation
├── LICENSE                 # Open-source license
├── Makefile                # Master Makefile for simulation and building
├── rtl/                    # Synthesizable SystemVerilog core design files
│   ├── lzc/                # Leading Zero Count (LZC) directory
│   │   ├── lzc_4.sv        # 4-bit Leading Zero Counter
│   │   ├── lzc_8.sv        # 8-bit Leading Zero Counter
│   │   ├── lzc_16.sv       # 16-bit Leading Zero Counter
│   │   └── lzc_32.sv       # 32-bit Leading Zero Counter (for FPU mantissa alignment)
│   ├── fcsr.sv             # Floating-Point Control and Status Register (Accrued flags & FRM)
│   ├── fprf.sv             # 32x32-bit Floating-Point Register File (f0-f31)
│   ├── fpu_class.sv        # Floating-point classification & 33-bit pseudo extended precision converter
│   ├── fpu_cmp.sv          # Comparison operations unit (fcmp)
│   ├── fpu_cvt.sv          # Data type conversion unit (fcvt: float <-> int/uint)
│   ├── fpu_decoder.sv      # RV32F instruction decoder (Translates 32-bit opcodes to datapath signals)
│   ├── fpu_div_sqrt.sv     # Division and square root iterative unit (fdiv, fsqrt)
│   ├── fpu_fma.sv          # Fused multiply-add unit (also handles fadd, fsub, and fmul)
│   ├── fpu_mac.sv          # Multiply-accumulate unit for internal FPU operations
│   ├── fpu_max.sv          # Min/Max operations unit (fmin, fmax)
│   ├── fpu_rnd.sv          # Rounding logic and execution module
│   ├── fpu_sgnj.sv         # Sign injection unit (fsgnj, fsgnjn, fsgnjx)
│   ├── fpu_subsystem.sv    # Top-level FPU subsystem (Integrates Decoder, FPRF, FCSR, and Datapath)
│   ├── fpu_top.sv          # FPU arithmetic datapath top module
│   └── fpu_wire.sv         # Common definitions: FPU structs, interfaces, wires, parameters
├── tb/                     # Testbench and verification environment
│   ├── tb_fpu_subsystem.sv # Top-level subsystem simulation testbench (Updated)
│   └── test_vectors/       # Auto-generated IEEE 754 standard test vectors
├── scripts/                # Automation and utility scripts
│   ├── generate_tests.py   # Script to generate test cases and expected results
│   └── sim.do              # EDA tool simulation scripts (e.g., ModelSim TCL)
└── docs/                   # Additional documentation and diagrams
    ├── architecture.md     # Microarchitecture and algorithm details
    └── fpu_pipeline.svg    # FPU datapath and pipeline architecture diagram