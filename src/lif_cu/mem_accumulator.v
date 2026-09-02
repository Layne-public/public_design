//------------------------------------------------------------------------------
  //
  //  Filename       : mem_accumulator.v
  //  Status         : draft
  //  Created        : 2025-06-06
  //  Description    : accumulator for membrane potential
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module mem_accumulator(
  // global
  clk             ,
  rstn            ,
  // config input
  cfg_wr_val_i    ,
  cfg_wr_dat_i    ,
  // acc data
  dat_wr_i        ,
  dat_val_i       ,
  // output
  dat_rd_o
);

//*** PARAMETER ****************************************************************

  // global
  parameter    INP_WIDTH                =  'd9              ;
  parameter    OUT_WIDTH                =  'd9              ;

//*** INPUT/OUTPUT *************************************************************
  // global
  input wire                          clk     ;
  input wire                          rstn    ;
  // input
  input                               cfg_wr_val_i    ;
  input  signed   [INP_WIDTH -1 :0]   cfg_wr_dat_i    ;
  input                               dat_val_i       ;
  input  signed   [INP_WIDTH -1 :0]   dat_wr_i        ;
  
  //output
  output signed   [OUT_WIDTH -1 :0]   dat_rd_o        ;

//*** WIRE/REG *****************************************************************

  reg  signed   [OUT_WIDTH -1 :0] mem_reg     ;
  wire signed   [INP_WIDTH -1 :0] add_src     ;
  wire signed   [OUT_WIDTH    :0] add_result  ;
  wire signed   [OUT_WIDTH -1 :0] add_rst_clp ;
  
//*** MAIN BODY ****************************************************************

  assign add_src      =   cfg_wr_val_i ? cfg_wr_dat_i : mem_reg ;
  assign add_result   =   add_src + dat_wr_i                    ;
  // clamp add_result to mem_reg width
  clamp #(
    .INP_WIDTH (OUT_WIDTH + 1 ),
    .OUT_WIDTH (OUT_WIDTH     )
  ) u_clamp_acc (
    .raw_dat_i (add_result    ),
    .clp_dat_o (add_rst_clp   )
  );
  // mem_accumulator
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        mem_reg <= 'd0;
    end else begin
        if (dat_val_i) begin
            mem_reg <= add_rst_clp  ;
        end 
        else if (cfg_wr_val_i) begin
            mem_reg <= cfg_wr_dat_i ;
        end
    end
  end

  assign dat_rd_o = mem_reg  ;

endmodule
