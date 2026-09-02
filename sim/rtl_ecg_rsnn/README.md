# ECG-RSNN RTL checks

This directory contains three self-checking simulations:

- `tb_it_aer_addr_gen.v`: checks all four inline-transition flags, including
  chained `+BinW` traversal and `-n*BinW+1` return.
- `tb_spike_window_buffer.v`: checks the dual-lead-equivalent 20-word
  pre-trigger and 40-word post-trigger circular window and the unchanged
  10-cycle time-to-space read order.
- `tb_digital_top_smoke.v`: runs the complete `digital_top` through reset,
  clocks, dual-lead input activity, and an R-peak/start pulse.

The runner also compiles and elaborates `digital_top` with portable behavioral
clock-gate and SRAM models. From PowerShell:

```powershell
cd sim\rtl_ecg_rsnn
.\run_xsim.ps1 -VivadoBin D:\xilinx\Vivado\2019.1\bin
```

The public configuration uses behavioral memories by default. A private
foundry build may define `UMC40` only when the licensed macro models are
available.
