`timescale 1ns/1ps

module tb_digital_top_smoke;
  reg clk;
  reg rst_n;
  reg jtag_pin_TCK;
  reg jtag_pin_TMS;
  reg jtag_pin_TDI;
  wire jtag_pin_TDO;
  reg AN_VAL_PAD;
  reg AN_SD_PAD;
  reg AN_DATA0_PAD;
  reg AN_DATA1_PAD;
  reg AN_RSTN_PAD;
  reg TEST_MODE_PAD;
  reg COR_START_PAD;
  wire RUST_VAL_PAD;
  wire [2:0] RUST_DAT_PAD;
  reg AN_CLK;
  reg AN_DAT0;
  reg AN_DAT1;
  wire BUF_FUL;

  integer sample_idx;

  digital_top dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .jtag_pin_TCK   (jtag_pin_TCK),
    .jtag_pin_TMS   (jtag_pin_TMS),
    .jtag_pin_TDI   (jtag_pin_TDI),
    .jtag_pin_TDO   (jtag_pin_TDO),
    .AN_VAL_PAD     (AN_VAL_PAD),
    .AN_SD_PAD      (AN_SD_PAD),
    .AN_DATA0_PAD   (AN_DATA0_PAD),
    .AN_DATA1_PAD   (AN_DATA1_PAD),
    .AN_RSTN_PAD    (AN_RSTN_PAD),
    .TEST_MODE_PAD  (TEST_MODE_PAD),
    .COR_START_PAD  (COR_START_PAD),
    .RUST_VAL_PAD   (RUST_VAL_PAD),
    .RUST_DAT_PAD   (RUST_DAT_PAD),
    .AN_CLK         (AN_CLK),
    .AN_DAT0        (AN_DAT0),
    .AN_DAT1        (AN_DAT1),
    .BUF_FUL        (BUF_FUL)
  );

  always #5 clk = ~clk;
  always #4 AN_CLK = ~AN_CLK;
  always #10 jtag_pin_TCK = ~jtag_pin_TCK;

  initial begin
    clk           = 1'b0;
    rst_n         = 1'b0;
    jtag_pin_TCK  = 1'b0;
    jtag_pin_TMS  = 1'b1;
    jtag_pin_TDI  = 1'b0;
    AN_VAL_PAD    = 1'b0;
    AN_SD_PAD     = 1'b1;
    AN_DATA0_PAD  = 1'b0;
    AN_DATA1_PAD  = 1'b0;
    AN_RSTN_PAD   = 1'b0;
    TEST_MODE_PAD = 1'b0;
    COR_START_PAD = 1'b0;
    AN_CLK        = 1'b0;
    AN_DAT0       = 1'b0;
    AN_DAT1       = 1'b0;

    #80;
    rst_n       = 1'b1;
    AN_RSTN_PAD = 1'b1;
    AN_VAL_PAD  = 1'b1;

    fork
      begin
        #120;
        COR_START_PAD = 1'b1;
        #20;
        COR_START_PAD = 1'b0;
      end
      begin
        for (sample_idx = 0; sample_idx < 160; sample_idx = sample_idx + 1) begin
          @(negedge AN_CLK);
          AN_DATA0_PAD = sample_idx[0];
          AN_DATA1_PAD = sample_idx[1];
          AN_DAT0      = sample_idx[0];
          AN_DAT1      = sample_idx[1];
        end
      end
    join

    #100;
    if (dut.rst_n_sync !== 1'b1 || dut.AN_RSTN_SYNC !== 1'b1)
      $fatal(1, "Top-level synchronized resets did not release");

    $display("PASS: digital_top clock/reset/input smoke simulation");
    $finish;
  end
endmodule
