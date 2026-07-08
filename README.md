# AXI4lite
````markdown
# AXI4-Lite Slave Interface

A simple **AXI4-Lite Slave Interface** designed in **SystemVerilog** following the AMBA AXI4-Lite protocol. It supports 32-bit single read and write transactions using the VALID/READY handshake mechanism.

## Features

- AXI4-Lite compliant slave
- 32-bit read and write operations
- Register-mapped interface
- VALID/READY handshaking
- Parameterized address width
- Synthesizable RTL
- Functional testbench included

## Project Structure

```
rtl/        → RTL Design
tb/         → Testbench
sim/        → Simulation Files
README.md
```

## Verified Scenarios

- Reset operation
- Write transaction
- Read transaction
- Register access
- VALID/READY handshake

## Tools Used

- SystemVerilog
- QuestaSim / ModelSim

## Future Work

- UVM Verification
- Functional Coverage
- SystemVerilog Assertions (SVA)

---

**Author:** Mradul Gupta  
**Domain:** RTL Design | Design Verification | SystemVerilog | UVM
````
