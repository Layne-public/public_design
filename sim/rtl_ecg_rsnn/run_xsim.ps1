param(
  [string]$VivadoBin = "D:\xilinx\Vivado\2019.1\bin"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$buildRoot = Join-Path $PSScriptRoot "build"
$xvlog = Join-Path $VivadoBin "xvlog.bat"
$xelab = Join-Path $VivadoBin "xelab.bat"
$xsim = Join-Path $VivadoBin "xsim.bat"

foreach ($tool in @($xvlog, $xelab, $xsim)) {
  if (-not (Test-Path -LiteralPath $tool)) {
    throw "Vivado Simulator tool not found: $tool"
  }
}

function Invoke-XsimTest {
  param(
    [string]$Name,
    [string]$Top,
    [string[]]$Sources
  )

  $testBuild = Join-Path $buildRoot $Name
  New-Item -ItemType Directory -Force -Path $testBuild | Out-Null
  Push-Location $testBuild
  try {
    & $xvlog -i (Join-Path $projectRoot "inc") @Sources
    if ($LASTEXITCODE -ne 0) { throw "${Name}: xvlog failed" }
    & $xelab $Top -s "${Name}_snapshot"
    if ($LASTEXITCODE -ne 0) { throw "${Name}: xelab failed" }
    & $xsim "${Name}_snapshot" -runall
    if ($LASTEXITCODE -ne 0) { throw "${Name}: xsim failed" }
  }
  finally {
    Pop-Location
  }
}

Invoke-XsimTest -Name "aer" -Top "tb_it_aer_addr_gen" -Sources @(
  (Join-Path $projectRoot "src\lsm_ctl\it_aer_addr_gen.v"),
  (Join-Path $PSScriptRoot "tb_it_aer_addr_gen.v")
)

Invoke-XsimTest -Name "window" -Top "tb_spike_window_buffer" -Sources @(
  (Join-Path $projectRoot "src\common\dff_sync.v"),
  (Join-Path $projectRoot "src\common\sync_stage2.v"),
  (Join-Path $projectRoot "src\common\pulse_async.v"),
  (Join-Path $projectRoot "src\asyn_inp_buf\asyn_inp_buf.v"),
  (Join-Path $PSScriptRoot "tb_spike_window_buffer.v")
)

$topSources = @(
  "src\common\clamp.v",
  "src\common\dff_sync.v",
  "src\common\ICG_cell.v",
  "src\common\pulse_async.v",
  "src\common\rstn_sync.v",
  "src\common\sram_sp_behave.v",
  "src\common\sync_stage2.v",
  "src\asyn_inp_buf\asyn_inp_buf.v",
  "src\neuron_storage\leading_one_detector.v",
  "src\neuron_storage\neuron_storage.v",
  "src\neuron_storage\result_storage.v",
  "src\lif_cu\LIF_CU.v",
  "src\lif_cu\mem_accumulator.v",
  "src\lif_cu\tree_adder_4_way.v",
  "src\lsm_ctl\it_aer_addr_gen.v",
  "src\lsm_ctl\lsm_ctl.v",
  "src\lsm_core\lsm_core.v",
  "src\jtag\full_handshake_rx.v",
  "src\jtag\full_handshake_tx.v",
  "src\jtag\jtag_dm.v",
  "src\jtag\jtag_driver.v",
  "src\jtag\jtag.v",
  "src\sys_regs\ram_intf.v",
  "src\sys_regs\sys_regs.v",
  "src\digtal_top\digital_top.v"
) | ForEach-Object { Join-Path $projectRoot $_ }

$topBuild = Join-Path $buildRoot "digital_top"
New-Item -ItemType Directory -Force -Path $topBuild | Out-Null
Push-Location $topBuild
try {
  & $xvlog -i (Join-Path $projectRoot "inc") @topSources
  if ($LASTEXITCODE -ne 0) { throw "digital_top: xvlog failed" }
  & $xelab digital_top -s ecg_rsnn_digital_top
  if ($LASTEXITCODE -ne 0) { throw "digital_top: xelab failed" }
  & $xvlog -i (Join-Path $projectRoot "inc") (Join-Path $PSScriptRoot "tb_digital_top_smoke.v")
  if ($LASTEXITCODE -ne 0) { throw "digital_top smoke: xvlog failed" }
  & $xelab tb_digital_top_smoke -s ecg_rsnn_digital_top_smoke
  if ($LASTEXITCODE -ne 0) { throw "digital_top smoke: xelab failed" }
  & $xsim ecg_rsnn_digital_top_smoke -runall
  if ($LASTEXITCODE -ne 0) { throw "digital_top smoke: xsim failed" }
}
finally {
  Pop-Location
}

Write-Host "PASS: directed AER/window tests, digital_top elaboration, and top smoke simulation completed"
