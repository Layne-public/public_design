//------------------------------------------------------------------------------
  //
  //  Filename       : LIF_CU.v
  //  Status         : draft
  //  Created        : 2025-06-03
  //  Description    : lif_cu unit support density and sparsity calculation
  //                   
//------------------------------------------------------------------------------
`include "defines.vh" 

module LIF_CU( 
  // global
  clk             ,
  rstn            ,
  // mode config
  op_mode_i       ,  // '1': density adder '2':sparsity adder '3': firing and decay ctl
  // state access
  cfg_sta_val_i   ,
  cfg_sta_dat_wr_i,
  cfg_sta_rd_req_i,
  cfg_sta_dat_rd_o, // always ready, data out valid isps_wgt_in next cycle
  // density adder
  den_spk_i       ,
  den_wgt_i       ,
  den_val_i       ,
  // sparsity adder
  sps_wgt_i       ,
  sps_val_i       ,
  // firing and decay
  cfg_mem_thr_i   , // firing threshold
  cfg_mem_tau_i   , // '1XXXX':IF model '00000': LS model '0XXXX': LIF model  
  fir_mem_dat_i   ,
  fir_mem_val_i   ,
  fir_mem_dat_o   ,
  fir_spk_dat_o      
//  fir_spk_val_o       

);
//*** PARAMETER ****************************************************************

  // global
  parameter    WGT_WIDTH                =  'd6                    ;
  parameter    MEM_WIDTH                =  'd9                    ;

  // derived
  localparam   SPK_DEPTH                =  'd16                   ;
  localparam   WGT_DEPTH                =  SPK_DEPTH * WGT_WIDTH  ;
  localparam   OP_WIDTH                 = 'd3                     ;
  //localparam   OPT_TREE_0_STG           = 'd1                     ; // 第0级进行近似计算降低功耗
  localparam   OPT_TREE_0_STG           = 'd1                     ; 
  localparam   OPT_TREE_1_STG           = 'd0                     ;
  localparam   TREE_WD_0_STG            = WGT_WIDTH               ;
  localparam   TREE_WD_1_STG            = WGT_WIDTH + 2           ;
  localparam   TREE_NUM_0_STG           = `FUNC_LOG2( SPK_DEPTH ) ;

  localparam   CFG_TAU_WD               = 'd5                     ;
  localparam   CFG_THR_WD               = 'd6                     ;

//*** INPUT/OUTPUT *************************************************************
  // global
  input                            clk              ;
  input                            rstn             ;
  // mode config
  input      [OP_WIDTH -1 :0]      op_mode_i        ;
  input                            cfg_sta_val_i    ;
  input      [MEM_WIDTH-1 :0]      cfg_sta_dat_wr_i ;
  input                            cfg_sta_rd_req_i ;
  output     [MEM_WIDTH-1 :0]      cfg_sta_dat_rd_o ;
   // density adder 
  input      [SPK_DEPTH-1 :0]      den_spk_i        ;
  input      [WGT_DEPTH-1 :0]      den_wgt_i        ;
  input                            den_val_i        ;
   // sparsity adder 
  input      [WGT_WIDTH-1 :0]      sps_wgt_i        ;
  input                            sps_val_i        ;
  // firing and decay
  input      [CFG_THR_WD-1:0]      cfg_mem_thr_i    ;
  input      [CFG_TAU_WD-1:0]      cfg_mem_tau_i    ;
  input      [MEM_WIDTH-1 :0]      fir_mem_dat_i    ;
  input                            fir_mem_val_i    ;
  output reg [MEM_WIDTH-1 :0]      fir_mem_dat_o    ;
  output                           fir_spk_dat_o    ;
//  output reg                       fir_spk_val_o    ;

//*** WIRE/REG *****************************************************************

  // DIGITAL LOGIC
  wire                       MEM_cfg_wr_val_i    ;
  wire   [MEM_WIDTH -1 :0]   MEM_cfg_wr_dat_i    ;
  wire                       MEM_dat_val_i       ;
  wire   [MEM_WIDTH -1 :0]   MEM_dat_wr_i        ;

  wire [TREE_WD_0_STG   -1 :0]  TREE_dat_0   [0: TREE_NUM_0_STG-1] ;
  wire [TREE_WD_0_STG   -1 :0]  TREE_dat_1   [0: TREE_NUM_0_STG-1] ;  
  wire [TREE_WD_0_STG   -1 :0]  TREE_dat_2   [0: TREE_NUM_0_STG-1] ;  
  wire [TREE_WD_0_STG   -1 :0]  TREE_dat_3   [0: TREE_NUM_0_STG-1] ;
  wire [TREE_WD_0_STG+2 -1 :0]  TREE_dat_sum [0: TREE_NUM_0_STG-1] ;
  wire [TREE_WD_1_STG+2 -1 :0]  TREE_dat_fin                       ;

  wire [TREE_WD_1_STG-1 :0] TREE_TAU_dat_0 ;
  wire [TREE_WD_1_STG-1 :0] TREE_TAU_dat_1 ;
  wire [TREE_WD_1_STG-1 :0] TREE_TAU_dat_2 ;
  wire [TREE_WD_1_STG-1 :0] TREE_TAU_dat_3 ;

  wire [TREE_WD_1_STG + 2 -1 :0] CLP_dat_i ;
  wire [MEM_WIDTH         -1 :0] CLP_dat_o ;

  wire [MEM_WIDTH-1 :0] fir_mem_dat_cur ;

//*** MAIN BODY ***************************************************************  
  //== mem acc part =================   


  assign MEM_cfg_wr_val_i = cfg_sta_val_i    ;
  assign MEM_cfg_wr_dat_i = cfg_sta_dat_wr_i ;
  
  assign MEM_dat_wr_i     = (op_mode_i=='d1) ? CLP_dat_o :
                            (op_mode_i=='d2) ? {{(MEM_WIDTH-WGT_WIDTH){sps_wgt_i[WGT_WIDTH-1]}},sps_wgt_i} : 'd0   ;
  assign MEM_dat_val_i    = (op_mode_i=='d1) ? den_val_i :
                            (op_mode_i=='d2) ? sps_val_i : 'd0   ;

  mem_accumulator #(
      .INP_WIDTH        ( MEM_WIDTH       ),
      .OUT_WIDTH        ( MEM_WIDTH       )
  ) u_mem_accumulator (
    // global
      .clk              ( clk             ),  
      .rstn             ( rstn            ),  
    // config
      .cfg_wr_val_i     ( MEM_cfg_wr_val_i),  // 配置写入使能
      .cfg_wr_dat_i     ( MEM_cfg_wr_dat_i),  // 配置写入数据（[8:0]）
    // data
      .dat_wr_i         ( MEM_dat_wr_i    ),  // 累加输入数据（[8:0]）
      .dat_val_i        ( MEM_dat_val_i   ),  // 输入数据有效
      .dat_rd_o         ( cfg_sta_dat_rd_o)
  );


  //== tree adder part ===============
  // - comb logic should check timing

  // stage 0
  genvar i;
  generate
    for (i = 0; i < TREE_NUM_0_STG; i = i + 1) begin : gen_adder
      assign TREE_dat_0[i] = den_spk_i[0 + 4*i] ? den_wgt_i[  WGT_WIDTH-1 + 4*i*WGT_WIDTH: 0           + 4*i*WGT_WIDTH] : 'd0;
      assign TREE_dat_1[i] = den_spk_i[1 + 4*i] ? den_wgt_i[2*WGT_WIDTH-1 + 4*i*WGT_WIDTH: 1*WGT_WIDTH + 4*i*WGT_WIDTH] : 'd0;
      assign TREE_dat_2[i] = den_spk_i[2 + 4*i] ? den_wgt_i[3*WGT_WIDTH-1 + 4*i*WGT_WIDTH: 2*WGT_WIDTH + 4*i*WGT_WIDTH] : 'd0;
      assign TREE_dat_3[i] = den_spk_i[3 + 4*i] ? den_wgt_i[4*WGT_WIDTH-1 + 4*i*WGT_WIDTH: 3*WGT_WIDTH + 4*i*WGT_WIDTH] : 'd0;
      tree_adder_4_way #(
        .INP_WIDTH       ( TREE_WD_0_STG      ),
        .OUT_WIDTH       ( TREE_WD_0_STG + 2  ),
        .TREE_ADDER_OPT  ( OPT_TREE_0_STG     )
      ) u_adder_tree_0_stg (
        .a               ( TREE_dat_0[i]      ),
        .b               ( TREE_dat_1[i]      ),
        .c               ( TREE_dat_2[i]      ),
        .d               ( TREE_dat_3[i]      ),
        .sum             ( TREE_dat_sum[i]    )
      );
    end
  endgenerate

  //== common part ===================
  // add tree stage 1 and tau reuse
  wire  [MEM_WIDTH-1 :0]      fir_mem_dat_sft_1 ;
  wire  [MEM_WIDTH-1 :0]      fir_mem_dat_sft_2 ;
  wire  [MEM_WIDTH-1 :0]      fir_mem_dat_sft_3 ;
  wire  [MEM_WIDTH-1 :0]      fir_mem_dat_sft_4 ;

  wire signed [MEM_WIDTH-1 :0] fir_mem_dat_bias_1 ;   // 2^1 - 1
  wire signed [MEM_WIDTH-1 :0] fir_mem_dat_bias_2 ;   // 2^2 - 1
  wire signed [MEM_WIDTH-1 :0] fir_mem_dat_bias_3 ;   // 2^3 - 1
  wire signed [MEM_WIDTH-1 :0] fir_mem_dat_bias_4 ;   // 2^4 - 1

  assign fir_mem_dat_bias_1 = fir_mem_dat_i[MEM_WIDTH-1] ? fir_mem_dat_i + 'd1   : $signed(fir_mem_dat_i) ; 
  assign fir_mem_dat_bias_2 = fir_mem_dat_i[MEM_WIDTH-1] ? fir_mem_dat_i + 'd3   : $signed(fir_mem_dat_i) ; 
  assign fir_mem_dat_bias_3 = fir_mem_dat_i[MEM_WIDTH-1] ? fir_mem_dat_i + 'd7   : $signed(fir_mem_dat_i) ;   
  assign fir_mem_dat_bias_4 = fir_mem_dat_i[MEM_WIDTH-1] ? fir_mem_dat_i + 'd15  : $signed(fir_mem_dat_i) ; 

  assign fir_mem_dat_sft_1 =fir_mem_dat_bias_1 >>> 'd1  ;
  assign fir_mem_dat_sft_2 =fir_mem_dat_bias_2 >>> 'd2  ;
  assign fir_mem_dat_sft_3 =fir_mem_dat_bias_3 >>> 'd3  ;
  assign fir_mem_dat_sft_4 =fir_mem_dat_bias_4 >>> 'd4  ;
 

  assign TREE_TAU_dat_0 = op_mode_i == 'd1 ? TREE_dat_sum[0]:
                          op_mode_i == 'd3 ? (!cfg_mem_tau_i[CFG_TAU_WD-1] && cfg_mem_tau_i[CFG_TAU_WD-2]? 
                                             fir_mem_dat_sft_1  : 'd0 ) : 'd0 ;    // 判断是不是需要decay 
  assign TREE_TAU_dat_1 = op_mode_i == 'd1 ? TREE_dat_sum[1]:
                          op_mode_i == 'd3 ? (!cfg_mem_tau_i[CFG_TAU_WD-1] && cfg_mem_tau_i[CFG_TAU_WD-3]? 
                                             fir_mem_dat_sft_2  : 'd0 ) : 'd0 ;
  assign TREE_TAU_dat_2 = op_mode_i == 'd1 ? TREE_dat_sum[2]:
                          op_mode_i == 'd3 ? (!cfg_mem_tau_i[CFG_TAU_WD-1] && cfg_mem_tau_i[CFG_TAU_WD-4]? 
                                             fir_mem_dat_sft_3  : 'd0 ) : 'd0 ;  
  assign TREE_TAU_dat_3 = op_mode_i == 'd1 ? TREE_dat_sum[3]:
                          op_mode_i == 'd3 ? (!cfg_mem_tau_i[CFG_TAU_WD-1] && cfg_mem_tau_i[CFG_TAU_WD-5]? 
                                             fir_mem_dat_sft_4  : 'd0 ) : 'd0 ;                                     

  tree_adder_4_way #(
    .INP_WIDTH       ( TREE_WD_1_STG      ),
    .OUT_WIDTH       ( TREE_WD_1_STG + 2  ),
    .TREE_ADDER_OPT  ( OPT_TREE_1_STG     )
  ) u_adder_tree_1_stg (
    .a               ( TREE_TAU_dat_0     ),
    .b               ( TREE_TAU_dat_1     ),
    .c               ( TREE_TAU_dat_2     ),
    .d               ( TREE_TAU_dat_3     ),
    .sum             ( TREE_dat_fin       )
  );

  // clamp to fit accumulator input
  // from TREE_WD_1_STG + 2 = 10 to MEM_WIDTH = 9
  assign CLP_dat_i = (op_mode_i == 'd1 | op_mode_i == 'd3) ? TREE_dat_fin : 'd0 ;

  clamp #(
    .INP_WIDTH       ( TREE_WD_1_STG + 2 ),
    .OUT_WIDTH       ( MEM_WIDTH         )
  ) u_clamp_mem (
    .raw_dat_i       ( CLP_dat_i         ),
    .clp_dat_o       ( CLP_dat_o         )
  );

  //== spiking generate ====================
  // spk out
  wire     		fir_val 	;
  wire [MEM_WIDTH-1 :0] cfg_mem_thr_ext ;

  assign fir_val         = op_mode_i=='d3 & fir_mem_val_i ;
  assign cfg_mem_thr_ext = {{(MEM_WIDTH-CFG_THR_WD){1'b0}},cfg_mem_thr_i} ;

  assign  fir_spk_dat_o = fir_val                                         ? 
                          $signed(fir_mem_dat_i) >= $signed(cfg_mem_thr_ext)  ? 'd1  : 'd0
                                                                                     : 'd0        ;

  // membrance votage update
  assign fir_mem_dat_cur = cfg_mem_tau_i[CFG_TAU_WD-1] ? fir_mem_dat_i : CLP_dat_o;

  always @(*)begin
    if (fir_val)begin
      if (cfg_mem_tau_i[CFG_TAU_WD-1:0] == 'd0)begin
        fir_mem_dat_o = 'd0 ;
      end
      else begin
        fir_mem_dat_o = fir_spk_dat_o ? $signed(fir_mem_dat_cur) - $signed(cfg_mem_thr_ext)
                                      : fir_mem_dat_cur ;
      end
    end
    else begin
      fir_mem_dat_o = 'd0 ;
    end
  end

endmodule
