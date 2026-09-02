//------------------------------------------------------------------------------
  //
  //  Filename       : sync_stage2.v
  //  Status         : draft
  //  Created        : 2025-06-04
  //  Description    : simple sync_stage2
  //                 
//------------------------------------------------------------------------------
`timescale 1ns/1ps
module sync_stage2 (
  input        clk_dst  ,    
  input        rst_dst_n,  
  input        data_i   ,     
  output       data_o      
);

//*** WIRE/REG *****************************************************************
wire data_sync1;

//*** MAIN BODY ****************************************************************

//--- Two-stage synchronizer ---
//always @(posedge clk_dst or negedge rst_dst_n) begin
//  if (!rst_dst_n) begin
//    data_sync1 <= 1'b0;
//    data_o     <= 1'b0;
//  end else begin
//    data_sync1 <= data_i    ;   
//    data_o     <= data_sync1;
//  end
//end

  dff_sync u_sync_dff1 (
    .clk  (clk_dst),
    .rstn (rst_dst_n),
    .D    (data_i),
    .Q    (data_sync1)
  );

  dff_sync u_sync_dff2 (
    .clk  (clk_dst),
    .rstn (rst_dst_n),
    .D    (data_sync1),
    .Q    (data_o)
  );
endmodule


