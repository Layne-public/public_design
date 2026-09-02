//------------------------------------------------------------------------------
  //
  //  Filename       : dff_sync.v
  //  Status         : draft
  //  Created        : 2025-06-04
  //  Description    : simple dff_sync, this module is designed for easy
  //  constrain in Design Compiler.
  //                 
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module dff_sync (
  input        clk  ,    
  input        rstn,  
  input        D    ,     
  output reg   Q      
);


//*** MAIN BODY ****************************************************************

always @(posedge clk or negedge rstn) begin
  if (!rstn) begin
    Q <= 1'b0;
  end else begin
    Q <= D   ;
  end
end

endmodule
