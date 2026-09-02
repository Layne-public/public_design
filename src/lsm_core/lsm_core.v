//------------------------------------------------------------------------------
  //
  //  Filename       : lsm_core.v
  //  Status         : draft
  //  Created        : 2025-06-17
  //  Description    : core top
  //                   
//------------------------------------------------------------------------------
`include "defines.vh"

module lsm_core(
  // ANALOGY
  AN_CLK            ,
  AN_DAT0           ,
  AN_DAT1           ,
  AN_VAL            ,
  AN_RSTN           ,
  BUF_FUL           ,
  AN_SD_ACTIVE_NUM  ,  // 0 for single lead valid, 1 for double leads valid
  // global
  clk               ,
  rstn              ,
  TEST_MODE         ,
  // cfg
  glb_start_trg_i   ,

  dat_grp_len_cfg_i ,  // 10
  dat_grp_num_cfg_i ,  // 30
  dat_grp_ful_cfg_i ,  //299
  cdc_test_only_i   ,
  cdc_test_strat_ctl_i ,
  cdc_test_step_over_i ,
  cdc_test_done_ctl_i , 
  cdc_test_dat0_o    , 
  cdc_test_dat1_o    , 
  cdc_test_irq       , 

  res_neu_cnt_cfg_i ,  // 48 neurons / 4 cu = 16 cycle 第一层状态机大循环数配置
  out_neu_cnt_cfg_i ,  // 5 neurons  / 4 cu = 2 cycle
  res_syn_cnt_cfg_i ,  // 60 or 30 synapse / 16 = 4 or 2 cycle 第一层状态机小循环数配置

  cfg_mem_thr_i    ,   //'b01000
  cfg_mem_tau_i    ,   //'b01111
  //== for core test
  cor_test_halt    ,
  cor_halt_state   ,
  cor_halt_pnt     ,
  cor_halt_rnt     ,
  cor_halt_tnt     ,
  cor_CU_dat       ,
  //== for core test
  den_bank_sel_i   ,
  den_addr_i       ,
  den_wr_val_i     , 
  den_wr_dat_i     ,
  den_rd_val_i     ,
  den_rd_dat_o     ,

//   spr_lkup_addr_i  ,
//   spr_lkup_wr_val_i,
//   spr_lkup_wr_dat_i,
//   spr_lkup_rd_val_i,
//   spr_lkup_rd_dat_o,
  spr_wgt_bin_depth_i ,
  spr_wgt_addr_i   ,
  spr_wgt_wr_dat_i ,
  spr_wgt_wr_val_i ,
  spr_wgt_rd_val_i , 
  spr_wgt_rd_dat_o ,

  result_o         , 
  result_val_o 
   );
//*** PARAMETER ****************************************************************

  // global
  parameter    BUF_DEPTH            =  'd512                   ;
  parameter    OUT_DEPTH            =  'd32                    ;
  // derived
  localparam   BUF_WIDTH            = `FUNC_LOG2( BUF_DEPTH
                                        )                      ;
  localparam   OUT_WIDTH            = `FUNC_LOG2( OUT_DEPTH
                                        )                      ;
  parameter    WGT_WIDTH            =  'd6                     ;
  parameter    MEM_WIDTH            =  'd9                     ;
  parameter    CU_NUM               =  'd4                     ;   
  localparam   CU_WD                = `FUNC_LOG2( CU_NUM )     ;

  localparam   RES_NEU_NUM_WD       =  'd6                         ;
  localparam   RES_NEU_CYCLE        = RES_NEU_NUM_WD - CU_WD       ;
  localparam   OUT_NEU_NUM_WD       =  'd3                         ; 
  localparam   OUT_NEU_CYCLE        = OUT_NEU_NUM_WD - CU_WD + 1   ;
  localparam   RES_SYN_NUM_WD       =  'd6                         ;
  localparam   DEN_BANK_NUM         =  'd16                        ;
  localparam   DEN_BANK_WD          =  `FUNC_LOG2(DEN_BANK_NUM)    ;
  localparam   RES_SYN_CYCLE        = RES_SYN_NUM_WD - DEN_BANK_WD ; 
  
  // storage module
  // neuron state
  parameter    NEU_WIDTH                =  'd9                    ;
  parameter    NEU_SIZE                 =  'd64                   ;
  localparam   NEU_SIZE_WD              =  `FUNC_LOG2( NEU_SIZE ) ;
  localparam   NEU_ADR_WD               =  NEU_SIZE_WD * CU_NUM   ;
  localparam   NEU_DAT_WD               =  NEU_WIDTH * CU_NUM     ;  
  // density weight (input layer weight)
  parameter    DEN_SIZE                 =  'd256 / CU_NUM          ;
  localparam   DEN_WIDTH_DTB            =  WGT_WIDTH * CU_NUM      ;
//   localparam   DEN_BANK_NUM             =  'd16                    ;
//   localparam   DEN_BANK_WD              =  `FUNC_LOG2(DEN_BANK_NUM);
  localparam   DEN_BANK_HAF             =  DEN_BANK_NUM /2         ;
  localparam   DEN_SIZE_WD              =  `FUNC_LOG2( DEN_SIZE )  ;
  localparam   DEN_RD_WD                =  DEN_WIDTH_DTB * DEN_BANK_NUM ;
  // sparisty weight
//   parameter    LOOKUP_SIZE              =  'd128                   ;
//   parameter    LOOKUP_WIDTH             =  'd16 - CU_WD            ;  //msb 8bit for synapse# num
//   localparam   LOOKUP_SIZE_WD           =  `FUNC_LOG2(LOOKUP_SIZE) ;
  localparam   WGT_BIN_DEPTH_WD         =  `FUNC_LOG2('d32/CU_NUM)     ;
  parameter    WGT_STR_SIZE             =  'd2048 / CU_NUM         ; // 512/636 = 80% sparsity weight can be storage
  localparam   WGT_STR_WIDTH            =  'd12 * CU_NUM + 'd2     ; // 6bit for neurons order, 6 bit for weight
  localparam   WGT_STR_SIZE_WD          =  `FUNC_LOG2(WGT_STR_SIZE);
  localparam   SPR_WIDTH_DTB            =  DEN_WIDTH_DTB           ;

  localparam   SPK_DEPTH                =  DEN_BANK_NUM           ;
  localparam   WGT_DEPTH                =  SPK_DEPTH * WGT_WIDTH  ;
  localparam   OP_WIDTH                 = 'd3                     ;

  localparam   CFG_TAU_WD               = 'd5                     ;
  localparam   CFG_THR_WD               = 'd6                     ;
  localparam   OUT_SPK_SIZE             = 'd8                          ; 
  localparam   OUT_SPK_SIZE_WD          = `FUNC_LOG2( OUT_SPK_SIZE )   ;
//*** INPUT/OUTPUT *************************************************************
  // ANALOG
  input                            AN_CLK        ;
  input                            AN_DAT0       ;
  input                            AN_DAT1       ;
  input                            AN_VAL        ;
  input                            AN_RSTN       ;
  output                           BUF_FUL       ;
  input                            AN_SD_ACTIVE_NUM ;
  // DIGITAL CONFIG
  input                            clk               ;
  input                            rstn              ;

  input                            glb_start_trg_i   ;
  input                            TEST_MODE         ;
  input      [BUF_WIDTH-2 :0]      dat_grp_len_cfg_i ;
  input      [BUF_WIDTH-2 :0]      dat_grp_num_cfg_i ;
  input      [BUF_WIDTH-1 :0]      dat_grp_ful_cfg_i ;
  input                            cdc_test_only_i   ;
  input                            cdc_test_strat_ctl_i ;
  input                            cdc_test_step_over_i ;
  input                            cdc_test_done_ctl_i  ;
  output     [OUT_DEPTH-1 :0]      cdc_test_dat0_o    ; 
  output     [OUT_DEPTH-1 :0]      cdc_test_dat1_o    ; 
  output                           cdc_test_irq       ; 

  input      [RES_NEU_CYCLE-1:0]   res_neu_cnt_cfg_i ;
  input      [OUT_NEU_CYCLE-1:0]   out_neu_cnt_cfg_i ;
  input      [RES_SYN_CYCLE-1:0]   res_syn_cnt_cfg_i ;
  input      [CFG_THR_WD-1 :0]     cfg_mem_thr_i     ; //'b010000
  input      [CFG_TAU_WD-1 :0]     cfg_mem_tau_i     ; //'b01111
  
  input      [DEN_BANK_WD-1  :0]   den_bank_sel_i    ;
  input      [DEN_SIZE_WD -1 :0]   den_addr_i        ;
  input                            den_wr_val_i      ;
  input                            den_rd_val_i      ;
  input      [DEN_WIDTH_DTB-1:0]   den_wr_dat_i      ;
  output     [DEN_WIDTH_DTB-1:0]   den_rd_dat_o      ;

//   input      [LOOKUP_SIZE_WD-1 :0] spr_lkup_addr_i   ;
//   input                            spr_lkup_wr_val_i ;
//   input      [LOOKUP_WIDTH-1 :0]   spr_lkup_wr_dat_i ;
//   input                            spr_lkup_rd_val_i ;
//   output     [LOOKUP_WIDTH-1 :0]   spr_lkup_rd_dat_o ;
  input                            spr_wgt_bin_depth_i ;
  input      [WGT_STR_SIZE_WD-1:0] spr_wgt_addr_i    ;
  input                            spr_wgt_wr_val_i  ;
  input      [WGT_STR_WIDTH-1:0]   spr_wgt_wr_dat_i  ;
  input                            spr_wgt_rd_val_i  ;
  output     [WGT_STR_WIDTH-1:0]   spr_wgt_rd_dat_o  ;

  output     [OUT_SPK_SIZE_WD-1:0] result_o          ;
  output                           result_val_o      ;
  // for core test
  input                            cor_test_halt     ;
  input      [5 :0]                cor_halt_state    ;
  input      [10:0]                cor_halt_pnt      ;
  input      [10:0]                cor_halt_rnt      ;
  input      [3 :0]                cor_halt_tnt      ;
  output     [NEU_DAT_WD-1:0]      cor_CU_dat        ;

  // for core test

//*** WIRE/REG *****************************************************************

// neuron state signals
wire     [NEU_ADR_WD -1     :0] STR_neu_wr_addr_i   ;
wire     [NEU_DAT_WD -1     :0] STR_neu_wr_dat_i    ;
wire                            STR_neu_wr_val_i    ;
wire     [NEU_ADR_WD -1     :0] STR_neu_rd_addr_i   ;
wire     [NEU_DAT_WD -1     :0] STR_neu_rd_dat_o    ;
wire                            STR_neu_rd_val_i    ;

// density weight signals
wire     [DEN_BANK_WD -1     :0] STR_den_bank_sel_i  ;
wire     [DEN_SIZE_WD -1     :0] STR_den_addr_i      ;
wire                             STR_den_wr_val_i    ;
wire     [DEN_WIDTH_DTB -1   :0] STR_den_wr_dat_i    ;
wire                             STR_den_rd_val_i    ;
wire     [DEN_RD_WD -1       :0] STR_den_rd_dat_o    ;

// sparsity lookup signals
// wire     [LOOKUP_SIZE_WD -1  :0] STR_spr_lkup_addr_i    ;
// wire                             STR_spr_lkup_wr_val_i  ;
// wire     [LOOKUP_WIDTH -1    :0] STR_spr_lkup_wr_dat_i  ;
// wire                             STR_spr_lkup_rd_val_i  ;
// wire     [LOOKUP_WIDTH -1    :0] STR_spr_lkup_rd_dat_o  ;

// sparsity weight storage signals
wire     [WGT_STR_SIZE_WD -1 :0] STR_spr_wgt_addr_i    ;
wire                             STR_spr_wgt_wr_val_i  ;
wire     [WGT_STR_WIDTH -1   :0] STR_spr_wgt_wr_dat_i  ;
wire                             STR_spr_wgt_rd_val_i  ;
wire     [WGT_STR_WIDTH -1   :0] STR_spr_wgt_rd_dat_o  ;

// ADC BUFFER
wire                            ADC_window_trigger_i  ;
wire                            ADC_window_trigger_an ;
wire                            ADC_lsm_start_ctl_i   ;
wire                            ADC_lsm_step_ovr_i    ;
wire                            ADC_lsm_done_ctl_i    ;

wire     [OUT_DEPTH-1 :0]       ADC_dat0_o            ;
wire     [OUT_DEPTH-1 :0]       ADC_dat1_o            ;
wire                            ADC_dat_val_o         ;
// lsm control
// global signals


//**** inp module *******************
wire     [OUT_DEPTH-1 :0]       LSM_asyn_dat_0_i            ;
wire     [OUT_DEPTH-1 :0]       LSM_asyn_dat_1_i            ;
wire                            LSM_asyn_dat_rdy_i          ;

wire                            LSM_lsm_start_ctl_o         ;
wire                            LSM_lsm_step_ovr_o          ;
wire                            LSM_lsm_done_ctl_o          ;


//**** LIF module ******************
wire    [OP_WIDTH -1 :0]        LSM_op_mode_o               ;
wire                            LSM_cfg_sta_val_o           ;
wire    [NEU_DAT_WD-1 :0]       LSM_cfg_sta_dat_wr_o        ;
wire    [NEU_DAT_WD-1 :0]       LSM_cfg_sta_dat_rd_i        ;

wire    [SPK_DEPTH-1 :0]        LSM_den_spk_o               ;
wire    [DEN_RD_WD-1 :0]        LSM_den_wgt_o               ;
wire                            LSM_den_val_o               ;

wire    [WGT_WIDTH*CU_NUM-1:0]  LSM_sps_wgt_o               ;
wire                            LSM_sps_val_o               ;

wire    [MEM_WIDTH*CU_NUM-1:0]  LSM_fir_mem_dat_o           ;
wire                            LSM_fir_mem_val_o           ;
wire    [MEM_WIDTH*CU_NUM-1:0]  LSM_fir_mem_dat_i           ;
wire    [CU_NUM -1         :0]  LSM_fir_spk_dat_i           ;


//**** storage module ****************
// neuron state
wire    [NEU_ADR_WD -1 :0]      LSM_neu_wr_addr_o           ;
wire    [NEU_DAT_WD -1 :0]      LSM_neu_wr_dat_o            ;
wire                            LSM_neu_wr_val_o            ;
wire    [NEU_ADR_WD -1 :0]      LSM_neu_rd_addr_o           ;
wire                            LSM_neu_rd_val_o            ;
wire    [NEU_DAT_WD -1 :0]      LSM_neu_rd_dat_i            ;

// density weight

wire    [DEN_SIZE_WD-1    :0]   LSM_den_addr_o              ;

wire                            LSM_den_rd_val_o             ;
wire    [DEN_RD_WD-1      :0]   LSM_den_rd_dat_i             ;

// sparsity lookup
// wire    [LOOKUP_SIZE_WD-1 :0]   LSM_spr_lkup_addr_o          ;
// wire                            LSM_spr_lkup_rd_val_o        ;
// wire    [LOOKUP_WIDTH-1   :0]   LSM_spr_lkup_rd_dat_i        ;

// sparsity weight storage
wire    [WGT_STR_SIZE_WD-1:0]   LSM_spr_wgt_addr_o           ;
wire                            LSM_spr_wgt_rd_val_o         ;
wire    [WGT_STR_WIDTH-1  :0]   LSM_spr_wgt_rd_dat_i         ;

// Global control signals (shared by all CUs)

wire    [OP_WIDTH -1 :0]        CU_op_mode_i                   ;
wire                            CU_cfg_sta_val_i               ;
wire    [MEM_WIDTH-1 :0]        CU_cfg_sta_dat_wr_i[CU_NUM-1:0];
wire                            CU_cfg_sta_rd_req_i            ;
wire    [MEM_WIDTH-1 :0]        CU_cfg_sta_dat_rd_o[CU_NUM-1:0];

wire    [SPK_DEPTH-1 :0]        CU_den_spk_i[CU_NUM-1:0];
wire    [WGT_DEPTH-1 :0]        CU_den_wgt_i[CU_NUM-1:0];
wire                            CU_den_val_i            ;

wire    [WGT_WIDTH-1 :0]        CU_sps_wgt_i[CU_NUM-1:0];
wire                            CU_sps_val_i            ;


wire      [MEM_WIDTH-1 :0]      CU_fir_mem_dat_i[CU_NUM-1:0];
wire                            CU_fir_mem_val_i            ;
wire      [MEM_WIDTH-1 :0]      CU_fir_mem_dat_o[CU_NUM-1:0];
wire                            CU_fir_spk_dat_o[CU_NUM-1:0];

//*** MAIN BODY ****************************************************************

//== CU CORE =================================
assign CU_op_mode_i         = LSM_op_mode_o;
assign CU_cfg_sta_val_i     = LSM_cfg_sta_val_o;
assign CU_cfg_sta_rd_req_i  = 1'b1;  //not used actually

assign CU_den_val_i         = LSM_den_val_o;
assign CU_sps_val_i         = LSM_sps_val_o;

assign CU_fir_mem_val_i    = LSM_fir_mem_val_o;

//== CU 数组输入信号拆分（从一组密集/稀疏数据中 split 成 CU_NUM 份）==

genvar i, j;
generate
  for (i = 0; i < CU_NUM; i = i + 1) begin : assign_to_CU

    assign CU_cfg_sta_dat_wr_i[i] = LSM_cfg_sta_dat_wr_o[(i+1)*NEU_WIDTH-1    : i*NEU_WIDTH   ];

    assign CU_den_spk_i[i]        = LSM_den_spk_o  					       ;
    //assign CU_den_wgt_i[i]        = LSM_den_wgt_o       [(i+1)*WGT_DEPTH-1    : i*WGT_DEPTH   ];
    for (j= 0; j < DEN_BANK_NUM; j = j + 1) begin : per_weight
      assign CU_den_wgt_i[CU_NUM-1-i][(DEN_BANK_NUM-1-j+1) * WGT_WIDTH-1 : 
                             (DEN_BANK_NUM-1-j  ) * WGT_WIDTH    ] = LSM_den_wgt_o[((j*CU_NUM + i)+1)* WGT_WIDTH - 1 
 										  : (j*CU_NUM + i)   * WGT_WIDTH     ];
    end

    assign CU_sps_wgt_i[i]        = LSM_sps_wgt_o       [(i+1)*WGT_WIDTH-1    : i*WGT_WIDTH   ];
    assign CU_fir_mem_dat_i[i]    = LSM_fir_mem_dat_o   [(i+1)*MEM_WIDTH-1    : i*MEM_WIDTH   ];
  end
endgenerate

//== CU 输出连接回 LSM 控制模块（用于读回更新状态、发放状态）==
generate
  for (i = 0; i < CU_NUM; i = i + 1) begin : assign_from_CU
    assign LSM_cfg_sta_dat_rd_i[(i+1)*NEU_WIDTH-1 : i*NEU_WIDTH]  = CU_cfg_sta_dat_rd_o[i];
    assign LSM_fir_mem_dat_i[(i+1)*MEM_WIDTH-1 : i*MEM_WIDTH]        = CU_fir_mem_dat_o[i];
    assign LSM_fir_spk_dat_i[(i+1)*1 - 1 : i*1]                      = CU_fir_spk_dat_o[i]; // spk为单bit
  end
endgenerate

assign cor_CU_dat = LSM_cfg_sta_dat_rd_i ;

generate
genvar cu_idx;

for (cu_idx = 0; cu_idx < CU_NUM; cu_idx = cu_idx + 1) begin : gen_LIF_CU

  LIF_CU u_LIF_CU (
      .clk               (clk               ),
      .rstn              (rstn              ),

      // mode config
      .op_mode_i         (CU_op_mode_i         ),
      // state access
      .cfg_sta_val_i     (CU_cfg_sta_val_i           ),
      .cfg_sta_dat_wr_i  (CU_cfg_sta_dat_wr_i[cu_idx]),
      .cfg_sta_rd_req_i  (CU_cfg_sta_rd_req_i        ),
      .cfg_sta_dat_rd_o  (CU_cfg_sta_dat_rd_o[cu_idx]),

      // density adder
      .den_spk_i         (CU_den_spk_i[cu_idx]      ),
      .den_wgt_i         (CU_den_wgt_i[cu_idx]      ),
      .den_val_i         (CU_den_val_i              ),

      // sparsity adder
      .sps_wgt_i         (CU_sps_wgt_i[cu_idx]      ),
      .sps_val_i         (CU_sps_val_i              ),

      // firing and decay
      .cfg_mem_thr_i     (cfg_mem_thr_i             ),
      .cfg_mem_tau_i     (cfg_mem_tau_i             ),
      .fir_mem_dat_i     (CU_fir_mem_dat_i[cu_idx]  ),
      .fir_mem_val_i     (CU_fir_mem_val_i          ),
      .fir_mem_dat_o     (CU_fir_mem_dat_o[cu_idx]  ),
      .fir_spk_dat_o     (CU_fir_spk_dat_o[cu_idx]  )
  );

end
endgenerate


//== LSM control =============================
assign LSM_asyn_dat_0_i    = ADC_dat0_o ;
assign LSM_asyn_dat_1_i    = ADC_dat1_o ;
assign LSM_asyn_dat_rdy_i  = ADC_dat_val_o ;

assign LSM_spr_wgt_rd_dat_i  = STR_spr_wgt_rd_dat_o;
// assign LSM_spr_lkup_rd_dat_i = STR_spr_lkup_rd_dat_o;
assign LSM_den_rd_dat_i      = STR_den_rd_dat_o;
assign LSM_neu_rd_dat_i      = STR_neu_rd_dat_o;

lsm_ctl #(
    .CU_NUM            ( CU_NUM          )
  ) u_lsm_ctl          (
    .clk               (clk               ),
    .rstn              (rstn              ),

    // digital control input
    .glb_start_trg_i   (glb_start_trg_i  ),
    .res_neu_cnt_cfg_i (res_neu_cnt_cfg_i),
    .dat_grp_len_cfg_i (dat_grp_len_cfg_i),
    .dat_grp_num_cfg_i (dat_grp_num_cfg_i),
    .res_syn_cnt_cfg_i (res_syn_cnt_cfg_i),  // 48 neurons / 4 cu = 16 cycle 第�?�?�?��??�?�大循�?��?��??置
    .out_neu_cnt_cfg_i (out_neu_cnt_cfg_i),  // 5 neurons  / 4 cu = 2 cycle
    .AN_SD_ACTIVE_NUM  (AN_SD_ACTIVE_NUM ),
    .cor_test_halt     (cor_test_halt    ),
    .cor_halt_state    (cor_halt_state   ),
    .cor_halt_pnt      (cor_halt_pnt     ),
    .cor_halt_rnt      (cor_halt_rnt     ),
    .cor_halt_tnt      (cor_halt_tnt     ),
    //**** inp module *******************
    .asyn_dat_0_i      (LSM_asyn_dat_0_i     ),
    .asyn_dat_1_i      (LSM_asyn_dat_1_i     ),
    .asyn_dat_rdy_i    (LSM_asyn_dat_rdy_i   ),

    .lsm_start_ctl_o   (LSM_lsm_start_ctl_o  ),
    .lsm_step_ovr_o    (LSM_lsm_step_ovr_o   ),
    .lsm_done_ctl_o    (LSM_lsm_done_ctl_o   ),

    //**** LIF module ******************
    .op_mode_o         (LSM_op_mode_o        ),
    .cfg_sta_val_o     (LSM_cfg_sta_val_o    ),
    .cfg_sta_dat_wr_o  (LSM_cfg_sta_dat_wr_o ),
    .cfg_sta_dat_rd_i  (LSM_cfg_sta_dat_rd_i ),

    .den_spk_o         (LSM_den_spk_o        ),
    .den_wgt_o         (LSM_den_wgt_o        ),
    .den_val_o         (LSM_den_val_o        ),

    .sps_wgt_o         (LSM_sps_wgt_o        ),
    .sps_val_o         (LSM_sps_val_o        ),

    .fir_mem_dat_o     (LSM_fir_mem_dat_o    ),
    .fir_mem_val_o     (LSM_fir_mem_val_o    ),
    .fir_mem_dat_i     (LSM_fir_mem_dat_i    ),
    .fir_spk_dat_i     (LSM_fir_spk_dat_i    ),

    //**** storage module **************
    .neu_wr_addr_o     (LSM_neu_wr_addr_o    ),
    .neu_wr_dat_o      (LSM_neu_wr_dat_o     ),
    .neu_wr_val_o      (LSM_neu_wr_val_o     ),
    .neu_rd_addr_o     (LSM_neu_rd_addr_o    ),
    .neu_rd_val_o      (LSM_neu_rd_val_o     ),
    .neu_rd_dat_i      (LSM_neu_rd_dat_i     ),

    //.den_bank_sel_i    (LSM_den_bank_sel_i   ),
    .den_addr_o        (LSM_den_addr_o       ),
    //.den_wr_val_i      (LSM_den_wr_val_i     ),
    //.den_wr_dat_i      (LSM_den_wr_dat_i     ),
    .den_rd_val_o      (LSM_den_rd_val_o     ),
    .den_rd_dat_i      (LSM_den_rd_dat_i     ),

    // .spr_lkup_addr_o   (LSM_spr_lkup_addr_o  ),
    // //.spr_lkup_wr_val_i (LSM_spr_lkup_wr_val_i),
    // //.spr_lkup_wr_dat_i (LSM_spr_lkup_wr_dat_i),
    // .spr_lkup_rd_val_o (LSM_spr_lkup_rd_val_o),
    // .spr_lkup_rd_dat_i (LSM_spr_lkup_rd_dat_i),
    .spr_wgt_bin_depth_i(spr_wgt_bin_depth_i ),
    .spr_wgt_addr_o    (LSM_spr_wgt_addr_o   ),
    //.spr_wgt_wr_val_i  (LSM_spr_wgt_wr_val_i ),
    //.spr_wgt_wr_dat_i  (LSM_spr_wgt_wr_dat_i ),
    .spr_wgt_rd_val_o  (LSM_spr_wgt_rd_val_o ),
    .spr_wgt_rd_dat_i  (LSM_spr_wgt_rd_dat_i ),
    .result_o          (result_o	         ),
    .result_val_o      (result_val_o         )
);

//== adc buffer ==============================
assign ADC_window_trigger_i = (TEST_MODE & cdc_test_only_i) ? cdc_test_strat_ctl_i:
                                                               glb_start_trg_i;
assign ADC_lsm_start_ctl_i = (TEST_MODE & cdc_test_only_i) ? cdc_test_strat_ctl_i:
                                                             LSM_lsm_start_ctl_o ;
assign ADC_lsm_step_ovr_i  = (TEST_MODE & cdc_test_only_i) ? cdc_test_step_over_i:
                                                             LSM_lsm_step_ovr_o  ;
assign ADC_lsm_done_ctl_i  = (TEST_MODE & cdc_test_only_i) ? cdc_test_done_ctl_i :
                                                             LSM_lsm_done_ctl_o  ;
assign cdc_test_dat0_o     = TEST_MODE ? ADC_dat0_o    : 'd0    ;
assign cdc_test_dat1_o     = TEST_MODE ? ADC_dat1_o    : 'd0    ;
assign cdc_test_irq        = TEST_MODE ? ADC_dat_val_o : 'd0    ;

// One R-peak synchronizer is shared by both lead buffers.
pulse_async u_window_trigger_async2AN (
    .clk_src_i      (clk                    ),
    .rst_src_ni     (rstn                   ),
    .src_pulse_i    (ADC_window_trigger_i   ),
    .src_pulse_en_o (/*UNUSED */            ),
    .src_busy_o     (/*UNUSED */            ),
    .clk_dst_i      (AN_CLK                 ),
    .rst_dst_ni     (AN_RSTN                ),
    .dst_pulse_o    (ADC_window_trigger_an  )
);


asyn_inp_buf u_asyn_inp_buf0 (
    .AN_CLK            (AN_CLK             ),
    .AN_DAT            (AN_DAT0            ),
    .AN_VAL            (AN_VAL             ),
    .AN_RSTN           (AN_RSTN            ),
    .BUF_FUL           (BUF_FUL            ),

    .clk               (clk                ),
    .rstn              (rstn               ),
    .window_trigger_an_i(ADC_window_trigger_an),
    .lsm_start_ctl_i   (ADC_lsm_start_ctl_i),
    .lsm_step_ovr_i    (ADC_lsm_step_ovr_i ),
    .lsm_done_ctl_i    (ADC_lsm_done_ctl_i ),
    .dat_grp_len_cfg_i (dat_grp_len_cfg_i  ),
    .dat_grp_num_cfg_i (dat_grp_num_cfg_i  ),
    .dat_grp_ful_cfg_i (dat_grp_ful_cfg_i  ),

    .dat_o             (ADC_dat0_o         ),
    .dat_val_o         (ADC_dat_val_o      )
);

asyn_inp_buf u_asyn_inp_buf1 (
    .AN_CLK            (AN_CLK             ),
    .AN_DAT            (AN_DAT1            ),
    .AN_VAL            (AN_VAL             ),
    .AN_RSTN           (AN_RSTN            ),
    .BUF_FUL           (/*UNUSED */        ),

    .clk               (clk                ),
    .rstn              (rstn               ),
    .window_trigger_an_i(ADC_window_trigger_an),
    .lsm_start_ctl_i   (ADC_lsm_start_ctl_i),
    .lsm_step_ovr_i    (ADC_lsm_step_ovr_i ),
    .lsm_done_ctl_i    (ADC_lsm_done_ctl_i ),
    .dat_grp_len_cfg_i (dat_grp_len_cfg_i  ),
    .dat_grp_num_cfg_i (dat_grp_num_cfg_i  ),
    .dat_grp_ful_cfg_i (dat_grp_ful_cfg_i  ),

    .dat_o             (ADC_dat1_o         ),
    .dat_val_o         (/*UNUSED */        )
);


//== storge module =============================

assign STR_neu_wr_addr_i     = LSM_neu_wr_addr_o;
assign STR_neu_wr_dat_i      = LSM_neu_wr_dat_o;
assign STR_neu_wr_val_i      = LSM_neu_wr_val_o;
assign STR_neu_rd_addr_i     = LSM_neu_rd_addr_o;
assign STR_neu_rd_val_i      = LSM_neu_rd_val_o;


assign STR_den_bank_sel_i    = den_bank_sel_i;
assign STR_den_addr_i        = (den_wr_val_i | den_rd_val_i) ? den_addr_i: LSM_den_addr_o;
assign STR_den_wr_val_i      = den_wr_val_i;
assign STR_den_wr_dat_i      = den_wr_dat_i;
assign STR_den_rd_val_i      = LSM_den_rd_val_o | den_rd_val_i;
//assign den_rd_dat_o          = STR_den_rd_dat_o ;
wire  [DEN_BANK_WD-1  :0]   inverted_bank_sel    ;
assign inverted_bank_sel     = (~den_bank_sel_i) ;
assign den_rd_dat_o          = STR_den_rd_dat_o[ inverted_bank_sel * DEN_WIDTH_DTB +: DEN_WIDTH_DTB];

// assign STR_spr_lkup_addr_i   = (spr_lkup_wr_val_i | spr_lkup_rd_val_i) ? spr_lkup_addr_i: LSM_spr_lkup_addr_o;
// assign STR_spr_lkup_wr_val_i = spr_lkup_wr_val_i;
// assign STR_spr_lkup_wr_dat_i = spr_lkup_wr_dat_i;
// assign STR_spr_lkup_rd_val_i = LSM_spr_lkup_rd_val_o | spr_lkup_rd_val_i ;
// assign spr_lkup_rd_dat_o     = STR_spr_lkup_rd_dat_o ;

assign STR_spr_wgt_addr_i    = (spr_wgt_wr_val_i | spr_wgt_rd_val_i )? spr_wgt_addr_i: LSM_spr_wgt_addr_o;
assign STR_spr_wgt_wr_val_i  = spr_wgt_wr_val_i;
assign STR_spr_wgt_wr_dat_i  = spr_wgt_wr_dat_i;
assign STR_spr_wgt_rd_val_i  = LSM_spr_wgt_rd_val_o | spr_wgt_rd_val_i;
assign spr_wgt_rd_dat_o      = STR_spr_wgt_rd_dat_o ;

wire STR_sta_clr_i ;

assign STR_sta_clr_i = result_val_o  ;

neuron_storage#(
    .CU_NUM             ( CU_NUM          )
  ) u_neuron_storage    (
    .clk                (clk              ),
    .rstn               (rstn             ),
    .sta_clr_i          (STR_sta_clr_i    ),
    // neuron state
    .neu_wr_addr_i      (STR_neu_wr_addr_i    ),
    .neu_wr_dat_i       (STR_neu_wr_dat_i     ),
    .neu_wr_val_i       (STR_neu_wr_val_i     ),
    .neu_rd_addr_i      (STR_neu_rd_addr_i    ),
    .neu_rd_dat_o       (STR_neu_rd_dat_o     ),
    .neu_rd_val_i       (STR_neu_rd_val_i     ),

    // density weight
    .den_bank_sel_i     (STR_den_bank_sel_i   ),
    .den_addr_i         (STR_den_addr_i       ),
    .den_wr_val_i       (STR_den_wr_val_i     ),
    .den_wr_dat_i       (STR_den_wr_dat_i     ),
    .den_rd_val_i       (STR_den_rd_val_i     ),
    .den_rd_dat_o       (STR_den_rd_dat_o     ),

    // // sparsity lookup
    // .spr_lkup_addr_i    (STR_spr_lkup_addr_i    ),
    // .spr_lkup_wr_val_i  (STR_spr_lkup_wr_val_i  ),
    // .spr_lkup_wr_dat_i  (STR_spr_lkup_wr_dat_i  ),
    // .spr_lkup_rd_val_i  (STR_spr_lkup_rd_val_i  ),
    // .spr_lkup_rd_dat_o  (STR_spr_lkup_rd_dat_o  ),

    // sparsity weight storage
    .spr_wgt_addr_i     (STR_spr_wgt_addr_i     ),
    .spr_wgt_wr_val_i   (STR_spr_wgt_wr_val_i   ),
    .spr_wgt_wr_dat_i   (STR_spr_wgt_wr_dat_i   ),
    .spr_wgt_rd_val_i   (STR_spr_wgt_rd_val_i   ),
    .spr_wgt_rd_dat_o   (STR_spr_wgt_rd_dat_o   )
);



endmodule
