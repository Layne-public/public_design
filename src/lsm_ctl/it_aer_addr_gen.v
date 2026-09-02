//------------------------------------------------------------------------------
//  Filename       : it_aer_addr_gen.v
//  Description    : LUT-free inline-transition AER address generator
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module it_aer_addr_gen #(
  parameter ADDR_WIDTH = 8
) (
  input  wire                  clk,
  input  wire                  rstn,
  input  wire                  start_i,
  input  wire [ADDR_WIDTH-1:0] start_addr_i,
  input  wire                  step_i,
  input  wire [1:0]            flag_i,
  input  wire                  bin_depth_i,
  output reg  [ADDR_WIDTH-1:0] addr_o,
  output wire                  end_o
);

  // BinW is 2 or 4 entries for the two supported hardware configurations.
  wire [ADDR_WIDTH-1:0] bin_width;
  assign bin_width = {{(ADDR_WIDTH-1){1'b0}}, 1'b1}
                   << ({1'b0, bin_depth_i} + 2'd1);

  // Number of consecutive +BinW transitions since the current row started.
  // Keeping this state beside addr_o implements the two-register P/R scheme.
  reg  [ADDR_WIDTH-1:0] bin_return_count;
  wire [ADDR_WIDTH-1:0] return_offset;
  assign return_offset = bin_return_count
                       << ({1'b0, bin_depth_i} + 2'd1);

  assign end_o = step_i && (flag_i == 2'b00);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      addr_o           <= {ADDR_WIDTH{1'b0}};
      bin_return_count <= {ADDR_WIDTH{1'b0}};
    end
    else if (start_i) begin
      addr_o           <= start_addr_i;
      bin_return_count <= {ADDR_WIDTH{1'b0}};
    end
    else if (step_i) begin
      case (flag_i)
        2'b11: begin                 // same bin, next row: +1
          addr_o           <= addr_o + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
          bin_return_count <= {ADDR_WIDTH{1'b0}};
        end
        2'b10: begin                 // same row, next bin: +BinW
          addr_o           <= addr_o + bin_width;
          bin_return_count <= bin_return_count
                            + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
        end
        2'b01: begin                 // return after n bins: -n*BinW+1
          addr_o           <= addr_o - return_offset
                            + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
          bin_return_count <= {ADDR_WIDTH{1'b0}};
        end
        default: begin               // 00: end of the active-spike chain
          addr_o           <= addr_o;
          bin_return_count <= {ADDR_WIDTH{1'b0}};
        end
      endcase
    end
  end

endmodule
