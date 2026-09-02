//------------------------------------------------------------------------------
//  Filename       : leading_one_detector.v
//  Description    : Portable priority encoder returning an MSB-first zero count
//------------------------------------------------------------------------------

`include "defines.vh"

module leading_one_detector #(
  parameter WIDTH = 64,
  parameter INDEX_WIDTH = `FUNC_LOG2(WIDTH)
) (
  input  wire [WIDTH-1:0]       data_i,
  output reg  [INDEX_WIDTH:0]   leading_zero_count_o
);

  integer bit_index;
  reg found;

  always @(*) begin
    // All ones is the no-active-bit sentinel used by lsm_ctl.
    leading_zero_count_o = {(INDEX_WIDTH+1){1'b1}};
    found = 1'b0;
    for (bit_index = WIDTH-1; bit_index >= 0; bit_index = bit_index - 1) begin
      if (!found && data_i[bit_index]) begin
        leading_zero_count_o = WIDTH-1-bit_index;
        found = 1'b1;
      end
    end
  end

endmodule
