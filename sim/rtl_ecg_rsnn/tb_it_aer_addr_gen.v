`timescale 1ns/1ps

module tb_it_aer_addr_gen;
  reg        clk;
  reg        rstn;
  reg        start_i;
  reg  [7:0] start_addr_i;
  reg        step_i;
  reg  [1:0] flag_i;
  reg        bin_depth_i;
  wire [7:0] addr_o;
  wire       end_o;

  it_aer_addr_gen #(.ADDR_WIDTH(8)) dut (
    .clk(clk), .rstn(rstn),
    .start_i(start_i), .start_addr_i(start_addr_i),
    .step_i(step_i), .flag_i(flag_i), .bin_depth_i(bin_depth_i),
    .addr_o(addr_o), .end_o(end_o)
  );

  always #5 clk = ~clk;

  task start_at;
    input [7:0] value;
    begin
      @(negedge clk); start_addr_i = value; start_i = 1'b1;
      @(negedge clk); start_i = 1'b0;
      #1;
      if (addr_o !== value) begin
        $display("FAIL: start address expected %0d got %0d", value, addr_o);
        $finish;
      end
    end
  endtask

  task step_and_check;
    input [1:0] transition;
    input [7:0] expected;
    input       expected_end;
    begin
      @(negedge clk); flag_i = transition; step_i = 1'b1;
      #1;
      if (end_o !== expected_end) begin
        $display("FAIL: flag %b end expected %0d got %0d",
                 transition, expected_end, end_o);
        $finish;
      end
      @(negedge clk); step_i = 1'b0;
      #1;
      if (addr_o !== expected) begin
        $display("FAIL: flag %b address expected %0d got %0d",
                 transition, expected, addr_o);
        $finish;
      end
    end
  endtask

  initial begin
    clk = 1'b0;
    rstn = 1'b0;
    start_i = 1'b0;
    start_addr_i = 8'd0;
    step_i = 1'b0;
    flag_i = 2'b00;
    bin_depth_i = 1'b1; // BinW = 4
    repeat (3) @(negedge clk);
    rstn = 1'b1;

    start_at(8'd1);
    step_and_check(2'b11, 8'd2, 1'b0); // +1

    start_at(8'd1);
    step_and_check(2'b10, 8'd5, 1'b0); // +4
    step_and_check(2'b10, 8'd9, 1'b0); // +4 again
    step_and_check(2'b01, 8'd2, 1'b0); // -2*4+1
    step_and_check(2'b00, 8'd2, 1'b1); // hold/end

    bin_depth_i = 1'b0; // BinW = 2
    start_at(8'd10);
    step_and_check(2'b10, 8'd12, 1'b0);
    step_and_check(2'b01, 8'd11, 1'b0);

    $display("PASS: inline-transition AER decoder and chained return");
    $finish;
  end
endmodule
