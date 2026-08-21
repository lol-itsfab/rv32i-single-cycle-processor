# RV32I Single-Cycle RISC-V Processor

A single-cycle implementation of the RV32I base integer instruction set, written in SystemVerilog, targeting the Terasic DE10-Standard (Intel Cyclone V SoC). Built module-by-module from scratch, with a self-checking testbench for every component and a full-core integration test covering all six RV32I instruction formats.

## Status: Functionally complete and verified (simulation)

Every module below has its own dedicated testbench, and the fully assembled core has been verified end-to-end against a hand-assembled test program exercising every instruction format.

## Architecture

Classic single-cycle datapath: every instruction fetches, decodes, executes, accesses memory, and writes back within one clock cycle.

## Modules

| File | Description | Tests |
|---|---|---|
| `types_pkg.sv` | Shared enums/structs: opcodes, funct3/funct7 groupings, ALU op selectors, the `ctrl_t` control-signal bundle | — |
| `alu.sv` | Combinational ALU (add, sub, bitwise, shifts, set-less-than signed/unsigned, LUI pass-through) | 19/19 ✅ |
| `regfile.sv` | 32×32 register file, `x0` hardwired to zero, 2 combinational read ports, 1 synchronous write port | 6/6 ✅ |
| `imm_gen.sv` | Decodes and sign-extends I/S/B/U/J-type immediates per the RISC-V spec | 6/6 ✅ |
| `control_unit.sv` | Decodes opcode into the full `ctrl_t` control signal bundle | 9/9 ✅ |
| `alu_control.sv` | Combines the control hint, funct3/funct7, and lui/auipc flags into the exact ALU operation | 20/20 ✅ |
| `data_mem.sv` | Byte-addressable 1KB data memory; byte/halfword/word loads (signed + unsigned) and stores | 9/9 ✅ |
| `rv32i_core_singlecycle.sv` | Top-level datapath wiring all of the above together, plus PC logic, instruction memory, and branch/jump/writeback muxes | See below |

## Verification

Each module has an independent, self-checking SystemVerilog testbench (`testbenches/*_tb.sv`) using a `check()`/`check_*()` task pattern: apply inputs, wait for the logic to settle, compare against a hand-derived expected value, and report a pass/fail count.

The full core is verified in `core_smoke_tb.sv` via a hardcoded instruction sequence exercising:
- **R-type** — `ADD`
- **I-type** — `ADDI`, `LW`, `JALR`
- **S-type** — `SW`
- **B-type** — all 6 branch conditions: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` (both taken and not-taken paths)
- **U-type** — `LUI`, `AUIPC`
- **J-type** — `JAL`

Register values after execution are checked directly against hand-calculated expected results (with several encodings additionally cross-verified with a small Python script during development to catch bit-ordering mistakes before they reached simulation).

Individual ALU operations beyond `ADD` (e.g., `SUB`, `XOR`, shifts, `SLT`/`SLTU`) are verified in isolation via `alu_tb.sv` and `alu_control_tb.sv`, rather than individually run as instructions through the full core.

## Running the tests

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`/`vvp`).

Per-module tests, e.g.:
```bash
iverilog -g2012 -o sim_alu rtl/types_pkg.sv rtl/alu.sv testbenches/alu_tb.sv
vvp sim_alu
```

Full-core smoke test:
```bash
iverilog -g2012 -o sim_core rtl/types_pkg.sv rtl/alu.sv rtl/regfile.sv rtl/imm_gen.sv rtl/control_unit.sv rtl/alu_control.sv rtl/data_mem.sv rtl/rv32i_core_singlecycle.sv testbenches/core_smoke_tb.sv
vvp sim_core
```

## Known limitations / scope notes

- `ECALL`, `EBREAK`, and `FENCE` are out of scope (not implemented).
- `regfile.sv` has no reset logic — registers hold `x` (unknown) until first written. This doesn't affect correctness of any RISC-V program (none assume pre-zeroed registers), but would need addressing for a production design.
- Instruction memory is currently hardcoded via an `initial` block for testing, rather than loaded from an assembled program file (`$readmemh`).
- No exception handling, illegal-instruction detection, or memory-alignment checking.
- Not yet synthesized or run on physical hardware (DE10-Standard) — verification so far is simulation-only (Icarus Verilog).

## Reference

Instruction encodings verified against the [RISC-V Instruction Set Reference Card](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf).

## Project structure
```
rtl/            SystemVerilog source (modules + shared types package)
testbenches/    Self-checking testbench per module, plus the full-core smoke test
```
