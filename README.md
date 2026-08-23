# RV32I Single-Cycle RISC-V Processor
 
A single-cycle implementation of the RV32I base integer instruction set, written in SystemVerilog, targeting the Terasic DE10-Standard (Intel Cyclone V SoC). Built module-by-module from scratch, with a self-checking testbench for every component, a full-core integration test covering all six RV32I instruction formats, and a working demo running on physical hardware.
 
## Status: Functionally complete, verified in simulation, and running on hardware
 
Every module below has its own dedicated testbench, the fully assembled core has been verified end-to-end in simulation, and the design has been synthesized and programmed onto a real DE10-Standard board.
 
## Architecture
 
Classic single-cycle datapath: every instruction fetches, decodes, executes, accesses memory, and writes back within one clock cycle.
 
## Modules
 
| File | Description | Tests |
|---|---|---|
| `types_pkg.sv` | Shared enums/structs: opcodes, funct3/funct7 groupings, ALU op selectors, the `ctrl_t` control-signal bundle | — |
| `alu.sv` | Combinational ALU (add, sub, bitwise, shifts, set-less-than signed/unsigned, LUI pass-through) | 19/19 ✅ |
| `regfile.sv` | 32×32 register file, `x0` hardwired to zero, 2 combinational read ports + 1 debug read port, 1 synchronous write port | 9/9 ✅ |
| `imm_gen.sv` | Decodes and sign-extends I/S/B/U/J-type immediates per the RISC-V spec | 6/6 ✅ |
| `control_unit.sv` | Decodes opcode into the full `ctrl_t` control signal bundle | 9/9 ✅ |
| `alu_control.sv` | Combines the control hint, funct3/funct7, and lui/auipc flags into the exact ALU operation | 20/20 ✅ |
| `data_mem.sv` | Byte-addressable data memory; byte/halfword/word loads (signed + unsigned) and stores | 9/9 ✅ |
| `rv32i_core_singlecycle.sv` | Top-level datapath wiring all of the above together, plus PC logic, instruction memory, and branch/jump/writeback muxes | ✅ (full-core test, see Verification) |
| `de10_top.sv` | Board-level wrapper connecting the core to physical DE10-Standard I/O (clock, reset button, switches, LEDs) | — (hardware, not simulated) |
 
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
 
## Hardware verification

[Demo video](https://youtube.com/shorts/pp-8MDj1dyg) — switches select a register, LEDs display its value in binary, confirmed against values predicted in simulation.

The design has been synthesized with Quartus Prime and programmed onto a Terasic DE10-Standard board. `de10_top.sv` wraps the core with:
- `CLOCK_50` → `clk`
- `KEY[0]` (active-low pushbutton) → `rst_n`
- `SW[4:0]` → a debug register-select input (added specifically for this demo — see `regfile.sv`'s dedicated debug read port)
- The lower 10 bits of the selected register's value → `LEDR[9:0]`
Flipping the switches selects any of the 32 registers, and the LEDs display that register's value in binary after the hardcoded test program runs — confirmed against every value predicted and verified in simulation (e.g., `x1=5`, `x3=15`, `x18=18`).
 
Full compilation passes timing analysis with positive slack across all process/voltage/temperature corners (worst-case setup slack +1.815ns, worst-case hold slack +0.706ns) against the board's real 50MHz clock.
 
Constraint files (`de10_rv32i.qpf`, `de10_rv32i.qsf`, `sdc/de10_rv32i.sdc`) are included for reference; pin assignments were sourced from the DE10-Standard User Manual.
 
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
- Instruction memory is hardcoded via an `initial` block for testing, rather than loaded from an assembled program file (`$readmemh`). The program includes a `JAL x0,0` infinite loop at the end so execution parks safely rather than fetching uninitialized memory once the hardcoded program finishes.
- `data_mem.sv`'s data memory is sized at 16 bytes rather than a more realistic size. This is a synthesis workaround, not a simulation limitation: the read logic accesses up to 4 dynamically-computed addresses simultaneously (for word loads), which prevents Quartus from inferring efficient block RAM and instead synthesizes the array as general logic. At the original 1024-byte size, this caused ~25,000 ALMs of resource usage and severe routing congestion during place-and-route; shrinking to 16 bytes (sufficient for this demo's single load/store test) reduced that to ~1,400 ALMs. A production version would restructure this as word-addressed memory with post-read byte/halfword selection to properly infer block RAM at any size.
- No exception handling, illegal-instruction detection, or memory-alignment checking.
- LED display truncates register values above 1023 (10 LEDs = 10 bits) — e.g. `x12=4096` displays only its lower 10 bits on hardware, which happen to all be zero in that case.
## Reference
 
Instruction encodings verified against the [RISC-V Instruction Set Reference Card](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf). DE10-Standard pin assignments (`CLOCK_50`, `KEY[0]`, `SW[4:0]`, `LEDR[9:0]`) sourced from and verified against the [Terasic DE10-Standard User Manual](https://www.marutsu.co.jp/contents/shop/marutsu/datasheet/terasic_DE10-Standard.pdf) (Tables 3-5 through 3-8).
 
## Project structure
```
de10_rv32i.qpf     Quartus project file
de10_rv32i.qsf     Quartus pin assignments and settings
sdc/                Timing constraints (50MHz clock)
rtl/                SystemVerilog source (modules + shared types package)
testbenches/        Self-checking testbench per module, plus the full-core smoke test
```
