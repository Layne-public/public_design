//------------------------------------------------------------------------------
  //
  //  Filename       : clamp.v
  //  Status         : draft
  //  Created        : 2025-06-06
  //  Description    : accumulator for membrane potential
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module clamp(
  // input
  raw_dat_i    ,
  // output
  clp_dat_o
);

//*** PARAMETER ****************************************************************

  // global
  parameter    INP_WIDTH                =  'd10              ;
  parameter    OUT_WIDTH                =  'd9               ;
  // drived
  localparam MAX_VAL = $signed({1'b0, {OUT_WIDTH-1{1'b1}}});
  localparam MIN_VAL = $signed({1'b1, {OUT_WIDTH-1{1'b0}}});

  localparam integer WIDTH_DIFF = (INP_WIDTH > OUT_WIDTH) ? (INP_WIDTH - OUT_WIDTH) : 0;

//*** INPUT/OUTPUT *************************************************************
  // input
  input      signed   [INP_WIDTH -1 :0]   raw_dat_i         ;
  //output
  output reg signed   [OUT_WIDTH -1 :0]   clp_dat_o         ;

//*** WIRE/REG *****************************************************************

  
//*** MAIN BODY ****************************************************************

  generate
    // ========== Case 1: extend ==========
    if (INP_WIDTH <= OUT_WIDTH) begin : ext_case
      always @(*) begin
        clp_dat_o = {{(OUT_WIDTH - INP_WIDTH){raw_dat_i[INP_WIDTH-1]}}, raw_dat_i}; // 符号扩展
      end
    end

    // ========== Case 2: clamp ==========
    else begin : trunc_case

      wire [WIDTH_DIFF:0] high_bits = raw_dat_i[INP_WIDTH-1 : OUT_WIDTH-1];
      wire trunc_en = (&high_bits | ~|high_bits);

      always @(*) begin
        if (trunc_en)
          clp_dat_o = raw_dat_i[OUT_WIDTH-1:0]           ;      
        else
          clp_dat_o = raw_dat_i[INP_WIDTH-1  ] ? MIN_VAL 
                                               : MAX_VAL ;
      end
    end
  endgenerate

endmodule
