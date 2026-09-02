`timescale 1ns/1ps

module tb_spike_window_buffer;
  reg         AN_CLK;
  reg         AN_DAT;
  reg         AN_VAL;
  reg         AN_RSTN;
  wire        BUF_FUL;
  reg         clk;
  reg         rstn;
  reg         window_trigger_an_i;
  reg         lsm_start_ctl_i;
  reg         lsm_step_ovr_i;
  reg         lsm_done_ctl_i;
  wire [31:0] dat_o;
  wire        dat_val_o;

  integer source_index;
  integer trigger_index;
  integer time_step;
  integer neuron_index;
  integer expected_index;
  reg     expected_bit;

  function sample_pattern;
    input integer index;
    begin
      sample_pattern = ((index % 7) == 0)
                     ^ ((index % 11) == 3)
                     ^ ((index % 17) == 5);
    end
  endfunction

  asyn_inp_buf #(
    .BUF_DEPTH   (512),
    .OUT_DEPTH   (32),
    .PRE_WORD_NUM(10)
  ) dut (
    .AN_CLK(AN_CLK), .AN_DAT(AN_DAT), .AN_VAL(AN_VAL),
    .AN_RSTN(AN_RSTN), .BUF_FUL(BUF_FUL),
    .clk(clk), .rstn(rstn), .window_trigger_an_i(window_trigger_an_i),
    .lsm_start_ctl_i(lsm_start_ctl_i),
    .lsm_step_ovr_i(lsm_step_ovr_i),
    .lsm_done_ctl_i(lsm_done_ctl_i),
    .dat_grp_len_cfg_i(8'd10),
    .dat_grp_num_cfg_i(8'd30),
    .dat_grp_ful_cfg_i(9'd299),
    .dat_o(dat_o), .dat_val_o(dat_val_o)
  );

  always #5 clk = ~clk;
  always #7 AN_CLK = ~AN_CLK;

  // Present one deterministic bit before every analog sampling edge.
  always @(negedge AN_CLK) begin
    if (AN_RSTN && AN_VAL)
      AN_DAT = sample_pattern(source_index);
  end

  always @(posedge AN_CLK or negedge AN_RSTN) begin
    if (!AN_RSTN)
      source_index <= 0;
    else if (AN_VAL)
      source_index <= source_index + 1;
  end

  always @(posedge AN_CLK) begin
    if (AN_RSTN && window_trigger_an_i)
      trigger_index = source_index;
  end

  task pulse_step;
    begin
      @(negedge clk); lsm_step_ovr_i = 1'b1;
      @(negedge clk); lsm_step_ovr_i = 1'b0;
    end
  endtask

  initial begin
    AN_CLK = 1'b0;
    AN_DAT = 1'b0;
    AN_VAL = 1'b0;
    AN_RSTN = 1'b0;
    clk = 1'b0;
    rstn = 1'b0;
    window_trigger_an_i = 1'b0;
    lsm_start_ctl_i = 1'b0;
    lsm_step_ovr_i = 1'b0;
    lsm_done_ctl_i = 1'b0;
    trigger_index = -1;

    repeat (5) @(negedge clk);
    rstn = 1'b1;
    AN_RSTN = 1'b1;
    AN_VAL = 1'b1;

    wait (source_index >= 150);
    @(negedge AN_CLK);
    window_trigger_an_i = 1'b1;
    @(negedge clk);
    lsm_start_ctl_i = 1'b1;
    @(negedge AN_CLK);
    window_trigger_an_i = 1'b0;

    // The first bank becomes readable after 100 pre-trigger and 200
    // trigger/post-trigger samples have been assembled.
    wait (dut.BUF_0_FUL === 1'b1);
    if (trigger_index < 100) begin
      $display("FAIL: trigger was not observed after valid pre-history");
      $finish;
    end

    for (time_step = 0; time_step < 10; time_step = time_step + 1) begin
      wait (dat_val_o === 1'b1);
      #1;
      for (neuron_index = 0; neuron_index < 30; neuron_index = neuron_index + 1) begin
        expected_index = trigger_index - 100 + neuron_index*10 + time_step;
        expected_bit = sample_pattern(expected_index);
        if (dat_o[neuron_index] !== expected_bit) begin
          $display("FAIL: T2S t=%0d neuron=%0d source=%0d expected=%0d got=%0d",
                   time_step, neuron_index, expected_index,
                   expected_bit, dat_o[neuron_index]);
          $finish;
        end
      end
      if (time_step != 9)
        pulse_step();
    end

    @(negedge clk); lsm_done_ctl_i = 1'b1;
    @(negedge clk); lsm_done_ctl_i = 1'b0;
    lsm_start_ctl_i = 1'b0;
    repeat (8) @(negedge clk);

    $display("PASS: 20-word dual-lead-equivalent pre-trigger and 40-word post-trigger window");
    $finish;
  end

  initial begin
    #200000;
    $display("FAIL: spike-window test timeout");
    $finish;
  end
endmodule
