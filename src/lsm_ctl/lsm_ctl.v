//------------------------------------------------------------------------------
  //
  //  Filename       : lsm_ctl.v
  //  Status         : draft
  //  Created        : 2025-06-10
  //  Description    : main contol for whole liquid state machine
  //                   
//------------------------------------------------------------------------------
`include "defines.vh"

module lsm_ctl(                  
  // global
  clk               ,
  rstn              ,
  // digital
  glb_start_trg_i   , // io or register cfg
  // CONFIG
  res_neu_cnt_cfg_i ,  // 48 neurons / 4 cu = 12 cycle 第一层状态机大循环数配置
  out_neu_cnt_cfg_i ,  // 5 neurons  / 4 cu = 2 cycle
  AN_SD_ACTIVE_NUM  ,  // 0 for single lead valid, 1 for double leads valid
  res_syn_cnt_cfg_i ,  // 60 or 30 synapse / 16 = 4 or 2 cycle 第一层状态机小循环数配置

  dat_grp_len_cfg_i , // time step
  dat_grp_num_cfg_i , // inp neurons / channel
  //== for core test
  cor_test_halt     ,
  cor_halt_state    ,
  cor_halt_pnt      ,
  cor_halt_rnt      ,
  cor_halt_tnt      ,
  //== for core test
  //**** inp module *******************
    lsm_start_ctl_o   ,
    lsm_step_ovr_o    ,
    lsm_done_ctl_o    ,
    asyn_dat_0_i      ,
    asyn_dat_1_i      ,
    asyn_dat_rdy_i    ,
  //**** storage module ****************
    // neuron state
    neu_wr_addr_o     ,
    neu_wr_dat_o      ,
    neu_wr_val_o      ,
    neu_rd_addr_o     ,
    neu_rd_val_o      ,
    neu_rd_dat_i      ,
    // den weight
    den_bank_sel_o    ,
    den_addr_o        ,
    den_wr_val_o      ,
    den_wr_dat_o      ,
    den_rd_val_o      ,
    den_rd_dat_i      ,

    // sparisty weight
    // spr_lkup_addr_o   ,
    // spr_lkup_wr_val_o ,
    // spr_lkup_wr_dat_o ,
    // spr_lkup_rd_val_o ,
    // spr_lkup_rd_dat_i ,
    spr_wgt_bin_depth_i,  
    spr_wgt_addr_o    ,
    spr_wgt_wr_val_o  ,
    spr_wgt_wr_dat_o  ,
    spr_wgt_rd_val_o  ,
    spr_wgt_rd_dat_i  ,
    //**** LIF module ****************
    op_mode_o         ,
    cfg_sta_val_o     ,
    cfg_sta_dat_wr_o  ,
    cfg_sta_dat_rd_i  ,
    // density addr
    den_spk_o         ,
    den_wgt_o         ,
    den_val_o         ,
    // sparsity adder
    sps_wgt_o         ,
    sps_val_o         , 
    // fire_spk_val
    fir_mem_dat_o     ,
    fir_mem_val_o     ,
    fir_mem_dat_i     ,
    fir_spk_dat_i     ,
    result_o          ,
    result_val_o 

   );
//*** PARAMETER ****************************************************************

  // fsm
  localparam   FSM_WD            = 'd5            ;
  localparam   IDLE              = 5'd0           ;
  localparam   WAIT_INPUT        = 5'd1           ;
  localparam   RES0_MEM_LOAD     = 5'd2           ;
  localparam   INP_SYN_CALC      = 5'd3           ;
  localparam   RES0_MEM_STOR     = 5'd4           ;
  localparam   RES_AER_LKUP      = 5'd5           ;
  localparam   RES1_MEM_LOAD     = 5'd6           ;
  localparam   RES_SYN_CALC      = 5'd7           ;
  localparam   RES1_MEM_STOR     = 5'd8           ;
  localparam   RES_SPK_GEN       = 5'd10          ;
  localparam   OUT_AER_LKUP      = 5'd11          ;
  localparam   OUT_MEM_LOAD      = 5'd12          ;
  localparam   LIQ_SYN_CALC      = 5'd13          ;
  localparam   OUT_MEM_STOR      = 5'd14          ;
  localparam   OUT_SPK_GEN       = 5'd15          ;
  localparam   TIM_STEP_CTL      = 5'd16          ;
  localparam   OUT_CAL_STAT      = 5'd17          ;
  localparam   TIME_STEP_DONE    = 5'd18          ;
  localparam   FINAL_RESET       = 5'd19          ;

  // global
  parameter    WGT_WIDTH                =  'd6                    ;
  parameter    MEM_WIDTH                =  'd9                    ;
  parameter    CU_NUM                   =  'd4                    ;
  localparam   CU_WD                    = `FUNC_LOG2( CU_NUM )    ;

  // contorl to neuron storage
  localparam   RES_NEU_NUM_WD   =  'd6    ; // 最大RES层神经元为64
  localparam   RES_NEU_CYCLE    = RES_NEU_NUM_WD - CU_WD;
  localparam   OUT_NEU_NUM_WD   =  'd3    ;
  //localparam   OUT_NEU_CYCLE    = OUT_NEU_NUM_WD - CU_WD;
  localparam   OUT_NEU_CYCLE    = OUT_NEU_NUM_WD - CU_WD + 1;
  localparam   RES_SYN_NUM_WD   =  'd6    ;


  // derived

  //**** inp module *******************
    parameter    BUF_DEPTH                =  'd512                       ;
    parameter    OUT_DEPTH                =  'd32                        ;

    localparam   BUF_WIDTH                =  `FUNC_LOG2( BUF_DEPTH )     ;
    localparam   OUT_WIDTH                =  `FUNC_LOG2( OUT_DEPTH )     ;
  //**** storage module ****************
    // neuron state
    parameter    NEU_WIDTH                =  'd9                         ;
    parameter    NEU_SIZE                 =  'd64                        ;
    localparam   NEU_SIZE_WD              =  `FUNC_LOG2( NEU_SIZE )      ;
    localparam   NEU_ADR_WD               =  NEU_SIZE_WD * CU_NUM        ;
    localparam   NEU_DAT_WD               =  NEU_WIDTH * CU_NUM          ;  
    // density weight (input layer weight)
    parameter    DEN_SIZE                 =  'd256 / CU_NUM              ;
    localparam   DEN_WIDTH_DTB            =  WGT_WIDTH * CU_NUM          ;
    localparam   DEN_BANK_NUM             =  'd16                        ;
    localparam   DEN_BANK_HAF             =  DEN_BANK_NUM /2             ;
    localparam   DEN_BANK_WD              =  `FUNC_LOG2(DEN_BANK_NUM)    ;
    localparam   DEN_BANK_HAF_WD          =  DEN_BANK_WD  -1  		 ;
    localparam   RES_SYN_CYCLE            =  RES_SYN_NUM_WD - DEN_BANK_WD; 

    localparam   DEN_SIZE_WD              =  `FUNC_LOG2( DEN_SIZE )      ;
    localparam   DEN_RD_WD                =  DEN_WIDTH_DTB * DEN_BANK_NUM;
    // sparisty weight
    // parameter    LOOKUP_SIZE              =  'd128                       ;
    // parameter    LOOKUP_WIDTH             =  'd16 - CU_WD                ;  //msb 8bit for synapse# num
    // localparam   LOOKUP_SIZE_WD           =  `FUNC_LOG2(LOOKUP_SIZE)     ;
    localparam   WGT_BIN_DEPTH_WD         =  `FUNC_LOG2('d32/CU_NUM)     ;
    parameter    WGT_STR_SIZE             =  'd2048 / CU_NUM             ;// 512/636 = 80% sparsity weight can be storage
    localparam   WGT_STR_WIDTH            =  'd12 * CU_NUM  +'d2         ; // 6bit for neurons order, 6 bit for weight
    localparam   WGT_STR_SIZE_WD          =  `FUNC_LOG2(WGT_STR_SIZE)    ;
    localparam   SPR_WIDTH_DTB            =  DEN_WIDTH_DTB               ;
  //**** LIF module *******************
    localparam   SPK_DEPTH                =  DEN_BANK_NUM                ;
    localparam   WGT_DEPTH                =  SPK_DEPTH * WGT_WIDTH       ;
    localparam   OP_WIDTH                 =  'd3                         ;


  //**** OUT result module ***********
    localparam   OUT_SPK_SIZE             = 'd8                          ; 
    localparam   TIM_STP_WIDTH            = 'd5                          ;
    localparam   OUT_SPK_SIZE_WD          = `FUNC_LOG2( OUT_SPK_SIZE )   ;

//*** INPUT/OUTPUT *************************************************************
  // global
  input                                 clk               ;
  input                                 rstn              ;
  // digital
  input      [RES_SYN_CYCLE-1 :0]	res_syn_cnt_cfg_i ;  
  input      [OUT_NEU_CYCLE-1 :0]	out_neu_cnt_cfg_i ; 
  input 	                        AN_SD_ACTIVE_NUM  ;
  input                                 glb_start_trg_i   ;
  input      [RES_NEU_CYCLE-1 :0]       res_neu_cnt_cfg_i ;  // RES层累加周期数，4个CU的话最大需要 64/4 = 16个状态机大循环
  input      [BUF_WIDTH-2     :0]       dat_grp_len_cfg_i;
  input      [BUF_WIDTH-2     :0]       dat_grp_num_cfg_i;
  // for core test
  input                                 cor_test_halt     ;
  input      [5 :0]                     cor_halt_state    ;
  input      [10:0]                     cor_halt_pnt      ;
  input      [10:0]                     cor_halt_rnt      ;
  input      [3 :0]                     cor_halt_tnt      ;
  //**** inp module *******************
    output                               lsm_start_ctl_o  ;
    output                               lsm_step_ovr_o   ;
    output                               lsm_done_ctl_o   ;
    input    [OUT_DEPTH-1     :0]        asyn_dat_0_i     ;
    input    [OUT_DEPTH-1     :0]        asyn_dat_1_i     ;
    input                                asyn_dat_rdy_i   ;

  //**** LIF module ****************
    output reg [OP_WIDTH -1  :0]      op_mode_o        ;
    output                            cfg_sta_val_o    ;
    output     [NEU_DAT_WD-1 :0]      cfg_sta_dat_wr_o ;
    input      [NEU_DAT_WD-1 :0]      cfg_sta_dat_rd_i ;
    // density adder 
    output     [SPK_DEPTH    -1 :0]   den_spk_o        ;
    output     [DEN_RD_WD    -1 :0]   den_wgt_o        ;
    output                            den_val_o        ;
    // sparsity adder 
    output     [WGT_WIDTH*CU_NUM-1 :0] sps_wgt_o        ;
    output                             sps_val_o        ;
    // firing and decay
    output     [MEM_WIDTH*CU_NUM-1 :0] fir_mem_dat_o    ;
    output                             fir_mem_val_o    ;
    input      [MEM_WIDTH*CU_NUM-1 :0] fir_mem_dat_i    ;
    input      [CU_NUM -1          :0] fir_spk_dat_i    ;   

  //**** storage module ****************
    // membrance potential
    output     [NEU_ADR_WD -1 :0]     neu_wr_addr_o    ;
    output     [NEU_DAT_WD -1 :0]     neu_wr_dat_o     ;
    output                            neu_wr_val_o     ;
    output     [NEU_ADR_WD -1 :0]     neu_rd_addr_o    ;
    input      [NEU_DAT_WD -1 :0]     neu_rd_dat_i     ;
    output                            neu_rd_val_o     ;
    // density calc
    output     [DEN_BANK_WD-1    :0]  den_bank_sel_o   ;
    output     [DEN_SIZE_WD-1    :0]  den_addr_o       ;
    output                            den_wr_val_o     ;
    output     [DEN_WIDTH_DTB-1  :0]  den_wr_dat_o     ;
    output                            den_rd_val_o     ;
    input      [DEN_RD_WD-1      :0]  den_rd_dat_i     ;
    // sparsity calc   
    // output      [LOOKUP_SIZE_WD-1 :0]    spr_lkup_addr_o  ;
    // output                               spr_lkup_wr_val_o;
    // output      [LOOKUP_WIDTH-1   :0]    spr_lkup_wr_dat_o;
    // output                               spr_lkup_rd_val_o;
    // input       [LOOKUP_WIDTH-1   :0]    spr_lkup_rd_dat_i;
    input                                spr_wgt_bin_depth_i ;
    output      [WGT_STR_SIZE_WD-1:0]    spr_wgt_addr_o   ;
    output                               spr_wgt_wr_val_o ;
    output      [WGT_STR_WIDTH-1  :0]    spr_wgt_wr_dat_o ;
    output                               spr_wgt_rd_val_o ;
    input       [WGT_STR_WIDTH-1  :0]    spr_wgt_rd_dat_i ;
    output      [OUT_SPK_SIZE_WD-1:0]    result_o          ;
    output                               result_val_o      ;

//*** WIRE/REG *****************************************************************
  // fsm
  reg        [FSM_WD   -1 :0]    cur_state_r ;
  reg        [FSM_WD   -1 :0]    nxt_state_w ;

//********* spking result saved and Leading 1 detection logic ****** 
    wire [CU_NUM        -1:0]  res_spk_i         ;
    wire                       res_spk_val_i     ;
    wire                       spk_buf_clr_i     ;
    wire [NEU_SIZE_WD     :0]  res_spk_lod_o     ;

    wire                       res_calc_val      ;
    wire                       res_fetch_lo_val  ;
    wire [RES_SYN_CYCLE-1 :0]  res_syn_cnt_sft   ;
    wire [CU_NUM        -1:0]  out_spk_i         ;
    wire                       out_spk_val_i     ;

    wire                       out_calc_val      ;
    wire                       comp_val_i        ; 

//********* common counter inside single state ***********************************
  // cnt_pnt_r
  reg [10:0]    cnt_pnt_r           ; // for state control
  reg           cnt_pnt_done_w      ;
  reg           cnt_pnt_val         ;
//********* NO.1 common counter record recurrent times between two dependent state ******

  // cnt_rnt_r
  reg [10:0]    cnt_rnt_r           ; // for state control
  reg           cnt_rnt_done_w      ;
  reg           cnt_rnt_val         ;
//********* NO.2 common counter record recurrent times between two dependent state ******

  // cnt_tnt_r
  reg [10:0]    cnt_tnt_r           ; // for state control
  reg           cnt_tnt_done_w      ;
  reg           cnt_tnt_val         ;

//*** MAIN BODY ****************************************************************
  // for core test
    wire   halt_trigger ;
    assign halt_trigger = (cor_test_halt == 1'b1                ) 
                        & (cur_state_r == cor_halt_state[4:0]   )
                        & (cnt_pnt_r   == cor_halt_pnt          )
                        & (cnt_rnt_r   == cor_halt_rnt          )
                        & (cnt_tnt_r   == {7'b0,cor_halt_tnt}   ) ;

  //********* asyn_inp_buf control***************************************************
    assign  lsm_start_ctl_o = cur_state_r == WAIT_INPUT                      ;
    assign  lsm_done_ctl_o  = cur_state_r == TIM_STEP_CTL &&  cnt_tnt_done_w ;
    assign  lsm_step_ovr_o  = cur_state_r == TIM_STEP_CTL && !cnt_rnt_done_w ;
    //读脉冲

  //********* neuron_storage control*************************************************
    // 读膜电位
    wire  [NEU_ADR_WD -1 :0]     neu_rd_addr_com    ;
    genvar cu_idx;
    generate
      for (cu_idx = 0; cu_idx < CU_NUM; cu_idx = cu_idx + 1) begin : gen_rd
        wire [NEU_SIZE_WD-1:0] addr_per_cu ;
        wire [NEU_SIZE_WD-1:0] bias_per_cu ;
        wire [10           :0] pnt_sft     ;
        wire [10           :0] rnt_sft     ;
        assign pnt_sft     = cnt_pnt_r << CU_WD ;
        assign rnt_sft     = cnt_rnt_r << CU_WD ;
        assign bias_per_cu = (cur_state_r == RES_SPK_GEN | cur_state_r == OUT_SPK_GEN ) ?  pnt_sft[NEU_SIZE_WD-1:0] 
                                                                                        :  rnt_sft[NEU_SIZE_WD-1:0] ;
        assign addr_per_cu = cu_idx + bias_per_cu ;
  
        assign neu_rd_addr_com[(cu_idx + 1) * NEU_SIZE_WD - 1 
                              : cu_idx      * NEU_SIZE_WD    ] = neu_rd_val_o | neu_wr_val_o     ?
								                                 cur_state_r == OUT_SPK_GEN      ?  addr_per_cu + 'd52  :
                                                                 addr_per_cu  : 'd0              ;
      end
    endgenerate
    assign neu_rd_val_o  = cur_state_r == RES0_MEM_LOAD                      | //cur_state_r == RES0_MEM_STOR |
                          (cur_state_r == RES1_MEM_LOAD && cnt_pnt_r == 'd1) | //cur_state_r == RES1_MEM_STOR |
                           cur_state_r == RES_SPK_GEN                        | //                             |
                          (cur_state_r == OUT_MEM_LOAD && cnt_pnt_r == 'd1)  | //cur_state_r == OUT_MEM_STOR  |
                           cur_state_r == OUT_SPK_GEN                                                        ;
    assign neu_rd_addr_o = cur_state_r == RES0_MEM_LOAD                      | cur_state_r == RES0_MEM_STOR           ?  neu_rd_addr_com                                  :
                          (cur_state_r == RES1_MEM_LOAD && cnt_pnt_r == 'd1) | cur_state_r == RES1_MEM_STOR           ?  spr_wgt_rd_dat_i[WGT_STR_WIDTH-1: DEN_WIDTH_DTB+2] :
                           cur_state_r == RES_SPK_GEN                        | cur_state_r == OUT_SPK_GEN             ?  neu_rd_addr_com                                  :
                          (cur_state_r == OUT_MEM_LOAD && cnt_pnt_r == 'd1)  | cur_state_r == OUT_MEM_STOR            ?  spr_wgt_rd_dat_i[WGT_STR_WIDTH-1: DEN_WIDTH_DTB+2] :
                                                                                                                         'd0 ;
    // 写膜电位
    assign neu_wr_val_o  =  ~halt_trigger & (
                           cur_state_r == RES0_MEM_STOR | 
                           cur_state_r == RES1_MEM_STOR |
                           cur_state_r == RES_SPK_GEN   |
                           cur_state_r == OUT_MEM_STOR  |
                           cur_state_r == OUT_SPK_GEN   );
    assign neu_wr_addr_o = neu_wr_val_o ? neu_rd_addr_o      : 'd0 ; // 原位写回 //!!! 后面需要改变
    assign neu_wr_dat_o  = neu_wr_val_o ? (cur_state_r == RES_SPK_GEN | cur_state_r == OUT_SPK_GEN )  ? fir_mem_dat_i 
                                                                                                      : cfg_sta_dat_rd_i   : 'd0 ; 

    // 读权重
    assign res_syn_cnt_sft = res_syn_cnt_cfg_i == 'd3 ? 'd2 : 'd1 ; 
    assign den_addr_o    =  cur_state_r == INP_SYN_CALC ? cnt_pnt_r  + (cnt_rnt_r << res_syn_cnt_sft) : 'd0 ;
    assign den_rd_val_o  =  cur_state_r == INP_SYN_CALC && !cnt_pnt_done_w ;

    // // 二级查表读权重
    // assign spr_lkup_addr_o   =  cur_state_r == RES_AER_LKUP ? res_spk_lod_o  : res_spk_lod_o + 'd64 ; //add offset for lookup out neurons
    // //wire  spk_val =  ~(&res_spk_lod_o)  ;
    // assign spr_lkup_rd_val_o = ( cur_state_r == RES_AER_LKUP |
    //                              cur_state_r == OUT_AER_LKUP ) && cnt_pnt_r =='d0 && (|(~res_spk_lod_o)) ; //&& spk_val;
    // reg  [RES_NEU_CYCLE-1 :0 ]  connect_nums ;
    // always @(posedge clk or negedge rstn ) begin :syna_nums
    //   if( !rstn ) begin
    //     connect_nums <= 'd0 ;
    //   end
    //   else begin
    //     if( ( cur_state_r == RES_AER_LKUP | cur_state_r == OUT_AER_LKUP ) && cnt_pnt_r =='d1 )begin
    //       connect_nums <= spr_lkup_rd_dat_i[RES_NEU_CYCLE-1 :0] ;
    //     end
    //   end
    // end

    // Inline-transition AER address generation.  The two state registers are
    // the flat address and the number of outstanding +BinW transitions.
    wire [WGT_STR_SIZE_WD-1:0]  wgt_addr_ptr;
    wire [WGT_STR_SIZE_WD-1:0]  wgt_sft;
    wire [WGT_STR_SIZE_WD-1:0]  aer_lod_ext;
    wire [WGT_STR_SIZE_WD-1:0]  aer_start_addr;
    wire                         aer_start;
    wire                         aer_step;
    wire                         aer_end;

    assign aer_lod_ext   = res_spk_lod_o;
    assign wgt_sft       = 'd48
                         << ({1'b0, spr_wgt_bin_depth_i} + 2'd1);
    assign aer_start     = (cur_state_r == RES_AER_LKUP)
                         | (cur_state_r == OUT_AER_LKUP);
    assign aer_step      = (cur_state_r == RES1_MEM_STOR)
                         | (cur_state_r == OUT_MEM_STOR);
    assign aer_start_addr = (cur_state_r == RES_AER_LKUP)
                          ? (aer_lod_ext
                             << ({1'b0, spr_wgt_bin_depth_i} + 2'd1))
                          : (aer_lod_ext + wgt_sft);

    it_aer_addr_gen #(
      .ADDR_WIDTH       ( WGT_STR_SIZE_WD )
    ) u_it_aer_addr_gen (
      .clk              ( clk                       ),
      .rstn             ( rstn                      ),
      .start_i          ( aer_start                 ),
      .start_addr_i     ( aer_start_addr            ),
      .step_i           ( aer_step                  ),
      .flag_i           ( spr_wgt_rd_dat_i[1:0]     ),
      .bin_depth_i      ( spr_wgt_bin_depth_i       ),
      .addr_o           ( wgt_addr_ptr              ),
      .end_o            ( aer_end                   )
    );

    assign spr_wgt_addr_o   = wgt_addr_ptr;
    assign spr_wgt_rd_val_o = cur_state_r == RES1_MEM_LOAD | cur_state_r == OUT_MEM_LOAD | cur_state_r == LIQ_SYN_CALC | cur_state_r == RES_SYN_CALC ;


  //********* LIF_CU control*********************************************************

    assign cfg_sta_val_o    =  ~halt_trigger & neu_rd_val_o  ;
    assign cfg_sta_dat_wr_o = neu_rd_dat_i  ;
    // 树形加法单元
    reg den_val_r;
    always @(posedge clk or negedge rstn ) begin
      if( !rstn ) begin
        den_val_r <= 'd0 ;
      end
      else begin
        if( den_rd_val_o )begin
          den_val_r <= 'd1 ;
        end
        else if( cnt_pnt_done_w )begin
          den_val_r <= 'd0 ;
        end
      end
    end
    assign den_val_o = ~halt_trigger & den_val_r ;
    // 片选两路的数据
    wire [DEN_BANK_NUM -1:0] den_spk_single          ;
    wire [DEN_BANK_HAF -1:0] data_0_half, data_1_half;
    reg  [DEN_BANK_NUM -1:0] den_spk_dual            ;
    wire [OUT_WIDTH    -1:0] idx_sft                 ;
    wire [10             :0] HAF_sft                 ;
    wire [10             :0] FUL_sft                 ;
    assign HAF_sft = (cnt_pnt_r - 1) << DEN_BANK_HAF_WD ;
    assign FUL_sft = (cnt_pnt_r - 1) << DEN_BANK_WD     ;

    assign idx_sft = (cnt_pnt_r != 0 && cur_state_r == INP_SYN_CALC ) ? AN_SD_ACTIVE_NUM ? HAF_sft[OUT_WIDTH    -1:0] :
	  								  		                                               FUL_sft[OUT_WIDTH    -1:0] : 0;
    genvar i;
    generate
      for (i = 0; i < DEN_BANK_NUM; i = i + 1) begin : gen_single
        assign den_spk_single[i] =  asyn_dat_0_i[idx_sft + i];
      end
    endgenerate
    // double lead
    generate
      for (i = 0; i < DEN_BANK_HAF; i = i + 1) begin : gen_dual
        assign data_0_half[i] = asyn_dat_0_i[idx_sft + i] ;
        assign data_1_half[i] = asyn_dat_1_i[idx_sft + i] ;
      end
    endgenerate

    integer j;
    always @(*) begin
      for (j = 0; j < DEN_BANK_HAF; j = j + 1) begin
        den_spk_dual[2*j]   = data_0_half[j];
        den_spk_dual[2*j+1] = data_1_half[j];
      end
    end

    assign den_spk_o = (AN_SD_ACTIVE_NUM) ? den_spk_dual : den_spk_single;
    assign den_wgt_o = den_rd_dat_i ;  

    // sparsity wgt
    assign sps_val_o  =  ~halt_trigger & (cur_state_r == RES_SYN_CALC       |
                                          cur_state_r == LIQ_SYN_CALC       );
    assign sps_wgt_o  = spr_wgt_rd_dat_i[DEN_WIDTH_DTB-1 + 2 : 2] ;
    // firing 
    assign fir_mem_val_o =  ~halt_trigger & (cur_state_r == RES_SPK_GEN | cur_state_r == OUT_SPK_GEN )   ;
    assign fir_mem_dat_o = neu_rd_dat_i                     ;
    
    always @(*) begin
                           op_mode_o = 'd0   ;
      case( cur_state_r )
        RES0_MEM_LOAD  :   op_mode_o = 'd1   ;
        INP_SYN_CALC   :   op_mode_o = 'd1   ;
        RES0_MEM_STOR  :   op_mode_o = 'd1   ;

        RES_AER_LKUP   :   op_mode_o = 'd2   ;
        RES1_MEM_LOAD  :   op_mode_o = 'd2   ;  
        RES_SYN_CALC   :   op_mode_o = 'd2   ;
        RES1_MEM_STOR  :   op_mode_o = 'd2   ; 

        OUT_AER_LKUP   :   op_mode_o = 'd2   ;
        OUT_MEM_LOAD   :   op_mode_o = 'd2   ;  
        LIQ_SYN_CALC   :   op_mode_o = 'd2   ;
        OUT_MEM_STOR   :   op_mode_o = 'd2   ;

        RES_SPK_GEN    :   op_mode_o = 'd3   ;
        OUT_SPK_GEN    :   op_mode_o = 'd3   ;

      endcase
    end
  //**************** Leading one detection ******************************************
    assign res_calc_val     = (cur_state_r == RES0_MEM_STOR && nxt_state_w == RES_AER_LKUP) |
                              (cur_state_r == RES_SPK_GEN   && nxt_state_w == OUT_AER_LKUP) ;
    assign res_fetch_lo_val =  cur_state_r == RES_AER_LKUP | 
                               cur_state_r == OUT_AER_LKUP ;
    generate
      for (cu_idx = 0; cu_idx < CU_NUM; cu_idx = cu_idx + 1) begin : gen_spk
        assign res_spk_i[cu_idx]   = fir_spk_dat_i[CU_NUM-1 -cu_idx] ;
        assign out_spk_i[cu_idx]   = fir_spk_dat_i[CU_NUM-1 -cu_idx] ;
      end
    endgenerate
    assign res_spk_val_i  = cur_state_r == RES_SPK_GEN ;
    assign out_spk_val_i  = cur_state_r == OUT_SPK_GEN ;
    assign spk_buf_clr_i  = (cur_state_r == RES1_MEM_STOR
          		            |cur_state_r == RES_AER_LKUP ) && nxt_state_w == RES_SPK_GEN ;

    assign out_calc_val   = cur_state_r == TIM_STEP_CTL   ;
    assign comp_val_i     = cur_state_r == OUT_CAL_STAT   ;

  //********** main control *********************************************************
  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cur_state_r <= IDLE ;
    end
    else begin
      cur_state_r <= nxt_state_w ;
    end
  end

  // nxt_state_w
  always @(*) begin
                                                         nxt_state_w = IDLE              ;
      case( cur_state_r )
        IDLE              : if ( glb_start_trg_i  )      nxt_state_w = WAIT_INPUT        ;
                           else                          nxt_state_w = IDLE              ;
        // input to resevior layer                   
        WAIT_INPUT        : if ( asyn_dat_rdy_i   )      nxt_state_w = RES0_MEM_LOAD     ; // mean adc data out ready
                           else                          nxt_state_w = WAIT_INPUT        ;
        RES0_MEM_LOAD     :                              nxt_state_w = INP_SYN_CALC      ;
        INP_SYN_CALC      : if ( cnt_pnt_done_w   )      nxt_state_w = RES0_MEM_STOR     ;
                           else                          nxt_state_w = INP_SYN_CALC      ;
        RES0_MEM_STOR     : if ( cnt_rnt_done_w   )      nxt_state_w = RES_AER_LKUP      ;
                           else                          nxt_state_w = RES0_MEM_LOAD     ;
        
        // resevior to resevior layer
        RES_AER_LKUP      : if ( &res_spk_lod_o   )      nxt_state_w = RES_SPK_GEN       ;
                           else                          nxt_state_w = RES1_MEM_LOAD     ;
        //                   else                          nxt_state_w = RES_AER_LKUP      ;
        RES1_MEM_LOAD     : if ( cnt_pnt_done_w   )      nxt_state_w = RES_SYN_CALC      ;
                           else                          nxt_state_w = RES1_MEM_LOAD     ;
        RES_SYN_CALC      :                              nxt_state_w = RES1_MEM_STOR     ;
        RES1_MEM_STOR     : if ( (&res_spk_lod_o) & 
  				                 cnt_rnt_done_w   )      nxt_state_w = RES_SPK_GEN       ; // leading 1 detection = 0
                        else if( cnt_rnt_done_w   )      nxt_state_w = RES_AER_LKUP      ;
                           else                          nxt_state_w = RES1_MEM_LOAD     ;

        // spiking firing
        RES_SPK_GEN       : if ( cnt_pnt_done_w   )      nxt_state_w = OUT_AER_LKUP     ;
                           else                          nxt_state_w = RES_SPK_GEN      ;

        // resevior to output layer
        OUT_AER_LKUP      : if ( &res_spk_lod_o   )      nxt_state_w = OUT_SPK_GEN       ;
                           else                          nxt_state_w = OUT_MEM_LOAD      ;
                        //    else                          nxt_state_w = OUT_AER_LKUP      ;
        OUT_MEM_LOAD      :if  ( cnt_pnt_done_w   )      nxt_state_w = LIQ_SYN_CALC      ;
                           else                          nxt_state_w = OUT_MEM_LOAD      ;
        LIQ_SYN_CALC      :                              nxt_state_w = OUT_MEM_STOR      ;
        OUT_MEM_STOR     : if  ( (&res_spk_lod_o) & 
  				                 cnt_rnt_done_w   )      nxt_state_w = OUT_SPK_GEN       ; // leading 1 detection = 0
                        else if( cnt_rnt_done_w   )      nxt_state_w = OUT_AER_LKUP      ;
                           else                          nxt_state_w = OUT_MEM_LOAD      ;

        // spiking firing
        OUT_SPK_GEN       : if ( cnt_pnt_done_w   )      nxt_state_w = TIM_STEP_CTL	 ;
                           else                          nxt_state_w = OUT_SPK_GEN       ;

        TIM_STEP_CTL      : if ( cnt_tnt_done_w   )      nxt_state_w = OUT_CAL_STAT      ;
                           else                          nxt_state_w = WAIT_INPUT        ; 
        OUT_CAL_STAT      :                              nxt_state_w = TIME_STEP_DONE    ; 
        TIME_STEP_DONE    : if ( result_val_o     )      nxt_state_w = FINAL_RESET       ;
  		 	   else 			 nxt_state_w = TIME_STEP_DONE    ;
        FINAL_RESET       :                              nxt_state_w = IDLE              ;
  
        default           :                              nxt_state_w = IDLE              ;
      endcase
  end

//********* common counter inside single state ***********************************

  // pnt_val
  always @(*) begin
                        cnt_pnt_val = 'd0   			;
    case( cur_state_r )
      INP_SYN_CALC  :   cnt_pnt_val = 'd1   			;
      RES_SPK_GEN   :   cnt_pnt_val = 'd1   			;
      OUT_SPK_GEN   :   cnt_pnt_val = 'd1   			;
    //   RES_AER_LKUP  :   cnt_pnt_val = 'd1 & ~(&res_spk_lod_o)   ;
      RES1_MEM_LOAD :   cnt_pnt_val = 'd1   			;  
    //   OUT_AER_LKUP  :   cnt_pnt_val = 'd1 & ~(&res_spk_lod_o) 	;
      OUT_MEM_LOAD  :   cnt_pnt_val = 'd1   			;  
    endcase
  end
  // cnt_pnt_done_w
  always @(*) begin
                        cnt_pnt_done_w = 'd0 ;
    case( cur_state_r )
      INP_SYN_CALC  :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == res_syn_cnt_cfg_i  + 'd1 ) ;
      RES_SPK_GEN   :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == {8'b0,res_neu_cnt_cfg_i} ) ;
      OUT_SPK_GEN   :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == {10'b0,out_neu_cnt_cfg_i}) ;
    //   RES_AER_LKUP  :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == 'd1  			);
      RES1_MEM_LOAD :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == 'd1                      ) ;
    //   OUT_AER_LKUP  :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == 'd1                     ) ;
      OUT_MEM_LOAD  :   cnt_pnt_done_w = ~halt_trigger & ( cnt_pnt_r == 'd1                      ) ;   
    endcase
  end
  // counter
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_pnt_r <= 'd0 ;
    end
    else begin
      if( cnt_pnt_done_w )begin
        cnt_pnt_r <= 'd0 ;
      end
      else if( cnt_pnt_val& ~halt_trigger )begin
        cnt_pnt_r <= cnt_pnt_r + 'd1 ;
      end
    end
  end

//********* NO.1 common counter record recurrent times between two dependent state ******


  // pnt_val
  always @(*) begin
                        cnt_rnt_val = 'd0   ;
    case( cur_state_r )
      RES0_MEM_STOR :   cnt_rnt_val = 'd1   ;
      RES_SYN_CALC  :   cnt_rnt_val = 'd1   ;
      LIQ_SYN_CALC  :   cnt_rnt_val = 'd1   ;
    endcase
  end
  // cnt_rnt_done_w
  always @(*) begin
                        cnt_rnt_done_w = 'd0 ;
    case( cur_state_r )
      RES0_MEM_STOR  :  cnt_rnt_done_w =  ~halt_trigger & ( cnt_rnt_r == {8'b0,res_neu_cnt_cfg_i}     )    ;
      RES1_MEM_STOR  :  cnt_rnt_done_w =  ~halt_trigger & aer_end ; //RES_SYN_CALC
      OUT_MEM_STOR   :  cnt_rnt_done_w =  ~halt_trigger & aer_end ; //LIQ_SYN_CALC
    endcase
  end
  // counter
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_rnt_r <= 'd0 ;
    end
    else begin
      if( cnt_rnt_done_w )begin
        cnt_rnt_r <= 'd0 ;
      end
      else if( cnt_rnt_val& ~halt_trigger )begin
        cnt_rnt_r <= cnt_rnt_r + 'd1 ;
      end
    end
  end

//********* NO.2 common counter record recurrent times between two dependent state ******

  // pnt_val
  always @(*) begin
                        cnt_tnt_val = 'd0   ;
    case( cur_state_r )
      TIM_STEP_CTL  :   cnt_tnt_val = 'd1   ;
    endcase
  end
  // cnt_tnt_done_w
  always @(*) begin
                        cnt_tnt_done_w = 'd0 ;
    case( cur_state_r )
      TIM_STEP_CTL   :  cnt_tnt_done_w =  ~halt_trigger & (cnt_tnt_r == dat_grp_len_cfg_i - 'd1  )      ;
    endcase
  end
  // counter
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_tnt_r <= 'd0 ;
    end
    else begin
      if( cnt_tnt_done_w )begin
        cnt_tnt_r <= 'd0 ;
      end
      else if( cnt_tnt_val & ~halt_trigger )begin
        cnt_tnt_r <= cnt_tnt_r + 'd1 ;
      end
    end
  end

//********* spking result saved and Leading 1 detection logic ******


    result_storage #(
      .CU_NUM        ( CU_NUM        ),
      .RES_SPK_SIZE  ( NEU_SIZE      ),
      .OUT_SPK_SIZE  ( OUT_SPK_SIZE  ),
      .TIM_STP_WIDTH ( TIM_STP_WIDTH )
    ) u_result_storage (
      .clk             (clk              ),
      .rstn            (rstn             ),

      .res_neu_cfg     (res_neu_cnt_cfg_i),
      .res_spk_i       (res_spk_i        ),
      .res_spk_val_i   (res_spk_val_i    ),
      .spk_buf_clr_i   (spk_buf_clr_i    ),
      .res_spk_lod_o   (res_spk_lod_o    ),

      .res_calc_val    (res_calc_val     ),
      .res_fetch_lo_val(res_fetch_lo_val ),

      .out_spk_i       (out_spk_i        ),
      .out_spk_val_i   (out_spk_val_i    ),

      .out_calc_val    (out_calc_val     ),
      .comp_val_i      (comp_val_i       ),

      .result_o        (result_o         ),
      .result_val_o    (result_val_o     )
    );

endmodule
