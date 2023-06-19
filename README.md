# EE477-final-project: Conway's Game of Life Hardware Accelerator

The purpose of this project was to create a hardware accelerator for Conway's Game of Life, and optimize it as much as possible, finding good balances between power consumption, performance, and area utilization. This project covered every step of the ASIC design flow, and was deeply involved when it came to timing analysis and floorplanning in order to optimize the accelerator.

Projects use components from Dr. Michael Taylor's Bespoke Silicon Group. This team generated a standard template library called basejump_stl, which was used in this project. You can find their repository [here](https://github.com/bespoke-silicon-group/basejump_stl)

Designs were written in SystemVerilog, then synthesized and floorplanned using the Cadence EDA tools. This design was checked in simulation at the RTL level, post synthesis, and post place and route. The design also passed DRC and LVS, as well as static timing analysis and formal verification. 

Report can be found [here](https://docs.google.com/document/d/17W-s6c6BdCE6fK88pmf07i1NLb4HjFrEHTrOVoaScIw/edit?usp=sharing).

### Final Specs: 
- Power consumption: 36.22 mW
- Power consumption (including IO): 54.83 mW
- Core clock: 118.96 MHz
- IO clock: 148.65 MHz
- Area: 0.2434 sq mm


