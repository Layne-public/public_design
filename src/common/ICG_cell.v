//------------------------------------------------------------------------------
  //
  //  Filename       : ICG_cell.v
  //  Status         : draft
  //  Created        : 2025-07-11
  //  Description    : Common ICG cell 
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module ICG_cell (
  // input
  clk	      ,       
  en          ,
  // output        
  clk_gated
);
//*** INPUT/OUTPUT *************************************************************
  //input
  input  wire   clk      ;
  input  wire   en       ;
  //output 
  output wire   clk_gated; 

//*** MAIN BODY ****************************************************************
  `ifdef UMC40
    LAGCEM4UM u_icg (
      .CK  (clk      ),
      .E   (en       ),
      .GCK (clk_gated)
    );
  `else
    reg           latch_en ;
    always @ (clk or en) begin
      if (!clk)
        latch_en <= en     ;   // latch inference
    end
    assign clk_gated = clk & latch_en;
  `endif
endmodule
