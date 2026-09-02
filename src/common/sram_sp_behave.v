//------------------------------------------------------------------------------
//  Filename       : sram_sp_behave.v
//  Description    : Portable synchronous single-port SRAM behavioral model
//------------------------------------------------------------------------------

`include "defines.vh"

module sram_sp_behave #(
  parameter KNOB_RNDOUT = 0,
  parameter SIZE        = 8,
  parameter DATA_WD     = 8,
  parameter SIZE_WD     = `FUNC_LOG2(SIZE)
) (
  input  wire                  clk,
  input  wire [SIZE_WD-1:0]    adr_i,
  input  wire                  wr_val_i,
  input  wire [DATA_WD-1:0]    wr_dat_i,
  input  wire                  rd_val_i,
  output reg  [DATA_WD-1:0]    rd_dat_o
);

  reg [DATA_WD-1:0] mem_array [0:SIZE-1];

  always @(posedge clk) begin
    if (wr_val_i)
      mem_array[adr_i] <= wr_dat_i;

    if (rd_val_i)
      rd_dat_o <= mem_array[adr_i];
    else
      rd_dat_o <= {DATA_WD{1'b0}};
  end

endmodule
