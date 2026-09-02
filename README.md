# ECG-RSNN RTL

ECG-RSNN is a digital RTL design for ECG classification with a
recurrent spiking neural network (RSNN). 

This repository represents the digital architecture and its behavioral
simulation models. It does not include the analog transistor-level design,
foundry SRAM models, trained weight images, biomedical datasets, or measured
silicon data.

## Repository structure

- `inc/`: global RTL definitions and parameters.
- `src/asyn_inp_buf/`: dual-buffer input capture, R-peak windowing, and T2S readout.
- `src/common/`: clock/reset synchronizers, clock-gate model, arithmetic helper,
  and portable single-port SRAM model.
- `src/digtal_top/`: `digital_top`, the top-level digital module.
- `src/jtag/`: JTAG debug and register-access interface.
- `src/lif_cu/`: leaky-integrate-and-fire compute units and adder logic.
- `src/lsm_core/`: integration of input buffering, storage, control, and compute.
- `src/lsm_ctl/`: RSNN controller and LUT-free inline-transition AER address generator.
- `src/neuron_storage/`: neuron state, sparse weight, and result storage.
- `src/pad_wrapper/`: pad-level wrapper source.
- `src/sys_regs/`: control/status registers and RAM access bridge.
- `sim/rtl_ecg_rsnn/`: directed tests and a top-level smoke simulation.
- `doc/registerfile.xlsx`: register map and configuration-field documentation.
- `rtl.f`: ordered RTL source list for simulators that accept file lists.

## Open data

No ECG dataset or measured chip dataset is included. The testbenches generate
synthetic 1-bit input activity and check addresses, sample counts, and cycle
ordering. Values in the testbenches are digital logic values; time is expressed
in Verilog simulation units (`1 ns / 1 ps`). No analysis or plotting scripts are
required.

## Open design

The default build uses portable behavioral SRAM and clock-gate models. Do not
define `UMC40` unless the corresponding licensed foundry models are available.

The supplied simulation flow was verified with:

- Windows PowerShell
- Xilinx Vivado Simulator 2019.1 (`xvlog`, `xelab`, and `xsim`)

To compile the complete RTL source list from the repository root:

```powershell
<path-to-vivado-bin>\xvlog.bat -i inc -f rtl.f
```

Run the checks from PowerShell:

```powershell
cd sim\rtl_ecg_rsnn
.\run_xsim.ps1 -VivadoBin <path-to-vivado-bin>
```

The script runs:

- all four inline-transition AER cases, including chained bin traversal;
- the R-peak pre-trigger/post-trigger circular window and T2S read order;
- compilation and elaboration of `digital_top`;
- a clock/reset/input smoke simulation of `digital_top`.

The simulations validate RTL control behavior. They do not reproduce ECG
classification accuracy because trained weights and evaluation data are not
part of this repository.

## License

Project-owned source is released under the Apache License 2.0. See `LICENSE`.
Third-party license notices are retained in the corresponding source files.

## Archive

No DOI or archive identifier has been assigned. Add the DOI here if a release is
archived with Zenodo or another long-term repository.
