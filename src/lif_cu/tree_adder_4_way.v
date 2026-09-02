//------------------------------------------------------------------------------
  //
  //  Filename       : tree_adder_4_way.v
  //  Status         : draft
  //  Created        : 2025-06-05
  //  Description    : simple 4-way adder, can be config as approxmate format, be careful!
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module tree_adder_4_way(
  // input
  a         ,
  b         ,
  c         ,
  d         ,
  // output
  sum
);

//*** PARAMETER ****************************************************************

  // global
  parameter    INP_WIDTH                =  'd6              ;
  parameter    OUT_WIDTH                =  'd8              ;
  parameter    TREE_ADDER_OPT           =  'd0              ;// 0: precise; 1: use approximate first stage
  // local
  localparam HI_WIDTH = 3;  // high bits to use full adder
  localparam LO_WIDTH = INP_WIDTH - HI_WIDTH;

//*** INPUT/OUTPUT *************************************************************
  // input
  input  signed   [INP_WIDTH -1 :0]   a       ;
  input  signed   [INP_WIDTH -1 :0]   b       ;
  input  signed   [INP_WIDTH -1 :0]   c       ;
  input  signed   [INP_WIDTH -1 :0]   d       ;
  //output
  output signed   [OUT_WIDTH -1 :0]   sum     ;

//*** WIRE/REG *****************************************************************

  wire signed   [INP_WIDTH    :0]   psum0       ;
  wire signed   [INP_WIDTH    :0]   psum1       ;
  
//*** MAIN BODY ****************************************************************
  generate
    if (TREE_ADDER_OPT == 0) begin : precise_tree
      assign psum0 = a + b;
      assign psum1 = c + d;
    end else begin : approx_tree
      // Split inputs
      wire signed [HI_WIDTH-1:0] a_hi = a[INP_WIDTH-1 -: HI_WIDTH];
      wire        [LO_WIDTH-1:0] a_lo = a[LO_WIDTH-1:0];

      wire signed [HI_WIDTH-1:0] b_hi = b[INP_WIDTH-1 -: HI_WIDTH];
      wire        [LO_WIDTH-1:0] b_lo = b[LO_WIDTH-1:0];

      wire signed [HI_WIDTH:0]   ab_hi_sum = a_hi + b_hi;
      wire        [LO_WIDTH-1:0] ab_lo_or  = a_lo | b_lo;

      wire signed [HI_WIDTH-1:0] c_hi = c[INP_WIDTH-1 -: HI_WIDTH];
      wire        [LO_WIDTH-1:0] c_lo = c[LO_WIDTH-1:0];

      wire signed [HI_WIDTH-1:0] d_hi = d[INP_WIDTH-1 -: HI_WIDTH];
      wire        [LO_WIDTH-1:0] d_lo = d[LO_WIDTH-1:0];

      wire signed [HI_WIDTH:0]   cd_hi_sum = c_hi + d_hi;
      wire        [LO_WIDTH-1:0] cd_lo_or  = c_lo | d_lo;

      // Stitch together approximate psums (extend and concatenate)
      //assign psum0 = {ab_hi_sum, ab_lo_or}; // width = HI_WIDTH+1 + LO_WIDTH = INP_WIDTH + 1
      //assign psum1 = {cd_hi_sum, cd_lo_or};
      wire        [LO_WIDTH-1:0] fi_lo_sum = ab_lo_or | cd_lo_or ;
      assign psum0 = {ab_hi_sum, fi_lo_sum        }; // width = HI_WIDTH+1 + LO_WIDTH = INP_WIDTH + 1
      assign psum1 = {cd_hi_sum, {LO_WIDTH{1'b0}} };

    end
  endgenerate

  // Second stage: always use full precision adder
  assign sum = psum0 + psum1;

endmodule
