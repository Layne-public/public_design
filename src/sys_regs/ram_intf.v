//------------------------------------------------------------------------------
  //
  //  Filename       : ram_intf.v
  //  Status         : draft
  //  Created        : 2025-08-21
  //  Description    : glue logic to transfer register to core top.
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module ram_intf(
  // global
  clk                        ,
  rst_n                      ,
  // from rsgister
  RAM_D_CFG0_den_bank_sel_o  ,
  RAM_D_CFG0_den_addr_o      ,
  RAM_D_CFG0_den_wr_enable_o ,
  RAM_D_CFG0_den_wr_dat0_o   ,
  RAM_D_CFG1_den_wr_dat1_o   ,
  RAM_D_CSR_den_req_en_o     ,
  RAM_D_DAT0_den_rd_dat0_i   ,
  RAM_D_DAT1_den_rd_dat1_i   ,

  den_bank_sel_i             ,
  den_addr_i                 ,
  den_wr_val_i               , 
  den_wr_dat_i               ,
  den_rd_val_i               ,
  den_rd_dat_o               ,
  //
//   RAM_L_CFG_lkup_addr_o      ,
//   RAM_L_CFG_lkup_wr_enable_o ,
//   RAM_L_CFG_lkup_wr_dat_o    ,
//   RAM_L_CSR_lkup_req_en_o    ,
//   RAM_L_DAT0_lkup_rd_dat_i   ,

//   spr_lkup_addr_i            ,
//   spr_lkup_wr_val_i          ,
//   spr_lkup_rd_val_i          ,
//   spr_lkup_wr_dat_i          ,
//   spr_lkup_rd_dat_o          ,
  //
  RAM_S_CFG0_spr_addr_o      ,
  RAM_S_CFG0_spr_wr_enable_o ,
  RAM_S_CSR_spr_req_en_o     ,
  RAM_S_CSR_spr_wr_dat0_o    ,
  RAM_S_CFG1_spr_wr_dat1_o   ,
  RAM_S_CFG2_spr_wr_dat2_o   ,
  RAM_S_CFG3_spr_wr_dat3_o   ,
  RAM_S_CSR_spr_rd_dat0_i    ,
  RAM_S_DAT0_spr_rd_dat1_i   ,
  RAM_S_DAT1_spr_rd_dat2_i   ,
  RAM_S_DAT2_spr_rd_dat3_i   ,

  spr_wgt_addr_i             ,
  spr_wgt_wr_val_i           ,
  spr_wgt_wr_dat_i           ,
  spr_wgt_rd_val_i           ,
  spr_wgt_rd_dat_o           


);

//*** PARAMETER ****************************************************************
//
//*** INPUT/OUTPUT *************************************************************
  input  wire        clk    ;
  input  wire        rst_n  ;

  input  wire [3:0]  RAM_D_CFG0_den_bank_sel_o  ;
  input  wire [4:0]  RAM_D_CFG0_den_addr_o      ;
  input  wire [0:0]  RAM_D_CFG0_den_wr_enable_o ;
  input  wire [15:0] RAM_D_CFG0_den_wr_dat0_o   ;
  input  wire [31:0] RAM_D_CFG1_den_wr_dat1_o   ;
  input  wire [0:0]  RAM_D_CSR_den_req_en_o     ;
  output reg  [15:0] RAM_D_DAT0_den_rd_dat0_i   ;
  output reg  [31:0] RAM_D_DAT1_den_rd_dat1_i   ;

  output wire [3:0]  den_bank_sel_i ;
  output wire [4:0]  den_addr_i     ;
  output wire        den_wr_val_i   ;
  output wire        den_rd_val_i   ;
  output wire [47:0] den_wr_dat_i   ;
  input  wire [47:0] den_rd_dat_o   ;


//   input  wire [6:0]  RAM_L_CFG_lkup_addr_o;
//   input  wire [0:0]  RAM_L_CFG_lkup_wr_enable_o;
//   input  wire [12:0] RAM_L_CFG_lkup_wr_dat_o;
//   input  wire [0:0]  RAM_L_CSR_lkup_req_en_o;
//   output reg  [12:0] RAM_L_DAT0_lkup_rd_dat_i;


//   output wire [6:0]  spr_lkup_addr_i   ;
//   output wire        spr_lkup_wr_val_i ;
//   output wire        spr_lkup_rd_val_i ;
//   output wire [12:0] spr_lkup_wr_dat_i ;
//   input  wire [12:0] spr_lkup_rd_dat_o ;


  input  wire [7:0]  RAM_S_CFG0_spr_addr_o     ;
  input  wire [0:0]  RAM_S_CFG0_spr_wr_enable_o;
  input  wire [0:0]  RAM_S_CSR_spr_req_en_o    ;
  input  wire [1:0]  RAM_S_CSR_spr_wr_dat0_o   ;
  input  wire [31:0] RAM_S_CFG1_spr_wr_dat1_o  ;
  input  wire [31:0] RAM_S_CFG2_spr_wr_dat2_o  ;
  input  wire [31:0] RAM_S_CFG3_spr_wr_dat3_o  ;
  output reg  [1:0]  RAM_S_CSR_spr_rd_dat0_i   ;
  output reg  [31:0] RAM_S_DAT0_spr_rd_dat1_i  ;
  output reg  [31:0] RAM_S_DAT1_spr_rd_dat2_i  ;
  output reg  [31:0] RAM_S_DAT2_spr_rd_dat3_i  ;

  output wire [7:0]  spr_wgt_addr_i    ;
  output wire        spr_wgt_wr_val_i  ;
  output wire [97:0] spr_wgt_wr_dat_i  ;
  output wire        spr_wgt_rd_val_i  ;
  input  wire [97:0] spr_wgt_rd_dat_o  ;

//*** MAIN BODY ****************************************************************
//*data latch enbale
  reg den_dat_latch ;
//  reg lkp_dat_latch ;
  reg spr_dat_latch ;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      den_dat_latch <= 1'b0;
//      lkp_dat_latch <= 1'b0;
      spr_dat_latch <= 1'b0;
    end else begin
      den_dat_latch  <= den_rd_val_i;
//      lkp_dat_latch  <= spr_lkup_rd_val_i;
      spr_dat_latch  <= spr_wgt_rd_val_i ;
    end
  end
 //******** sparsity ram *************************
  assign spr_wgt_addr_i   = RAM_S_CFG0_spr_addr_o ;
  assign spr_wgt_wr_val_i = RAM_S_CFG0_spr_wr_enable_o & RAM_S_CSR_spr_req_en_o ;
  assign spr_wgt_rd_val_i = !RAM_S_CFG0_spr_wr_enable_o & RAM_S_CSR_spr_req_en_o ;
  assign spr_wgt_wr_dat_i = {RAM_S_CFG3_spr_wr_dat3_o, RAM_S_CFG2_spr_wr_dat2_o, RAM_S_CFG1_spr_wr_dat1_o ,RAM_S_CSR_spr_wr_dat0_o};
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {RAM_S_DAT2_spr_rd_dat3_i,
       RAM_S_DAT1_spr_rd_dat2_i,
       RAM_S_DAT0_spr_rd_dat1_i,
       RAM_S_CSR_spr_rd_dat0_i} <= 'b0;
    end else begin
      if(spr_dat_latch) begin
      {RAM_S_DAT2_spr_rd_dat3_i,
       RAM_S_DAT1_spr_rd_dat2_i,
       RAM_S_DAT0_spr_rd_dat1_i,
       RAM_S_CSR_spr_rd_dat0_i} <= spr_wgt_rd_dat_o ;
      end
    end
  end

//  //******** lookup ram *************************
//   assign spr_lkup_addr_i   = RAM_L_CFG_lkup_addr_o ;
//   assign spr_lkup_wr_val_i = RAM_L_CFG_lkup_wr_enable_o & RAM_L_CSR_lkup_req_en_o ;
//   assign spr_lkup_rd_val_i = !RAM_L_CFG_lkup_wr_enable_o & RAM_L_CSR_lkup_req_en_o ;
//   assign spr_lkup_wr_dat_i = RAM_L_CFG_lkup_wr_dat_o ;
  
//   always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//       RAM_L_DAT0_lkup_rd_dat_i <= 'b0;
//     end else begin
//       if(lkp_dat_latch) begin
//         RAM_L_DAT0_lkup_rd_dat_i <= spr_lkup_rd_dat_o ;
//       end
//     end
//   end

 //******** density ram *************************
  assign den_bank_sel_i = RAM_D_CFG0_den_bank_sel_o ;
  assign den_addr_i     = RAM_D_CFG0_den_addr_o     ;
  assign den_wr_val_i   = RAM_D_CFG0_den_wr_enable_o & RAM_D_CSR_den_req_en_o ;
  assign den_rd_val_i   = !RAM_D_CFG0_den_wr_enable_o & RAM_D_CSR_den_req_en_o ;
  assign den_wr_dat_i   = {RAM_D_CFG1_den_wr_dat1_o,RAM_D_CFG0_den_wr_dat0_o} ;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {RAM_D_DAT1_den_rd_dat1_i, RAM_D_DAT0_den_rd_dat0_i}  <= 'b0;
    end else begin
      if(den_dat_latch) begin
        {RAM_D_DAT1_den_rd_dat1_i, RAM_D_DAT0_den_rd_dat0_i} <= den_rd_dat_o ;
      end
    end
  end




endmodule
