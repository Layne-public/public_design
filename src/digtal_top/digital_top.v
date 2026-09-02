//------------------------------------------------------------------------------
  //
  //  Filename       : digital_top.v
  //  Status         : draft
  //  Created        : 2025-08-23
  //  Description    : digital top
  //                   
//------------------------------------------------------------------------------
`include "defines.vh"

module digital_top #(
  parameter CU_NUM         = 8  ,
  parameter ADDR_W         = 6  ,
  parameter DMI_ADDR_BITS  = 6  ,
  parameter DMI_DATA_BITS  = 32 ,
  parameter DMI_OP_BITS    = 2
)(
  // ===== Clocks / resets =====
  input  wire         clk               ,
  input  wire         rst_n             , // SMT trigger

  // ===== JTAG pads =====
  input  wire         jtag_pin_TCK      ,
  input  wire         jtag_pin_TMS      , // pull up
  input  wire         jtag_pin_TDI      , // pull down
  output wire         jtag_pin_TDO      ,

  input  wire         AN_VAL_PAD        ,
  input  wire         AN_SD_PAD         ,   // 0: single-lead, 1: dual-lead
  input  wire         AN_DATA0_PAD      ,
  input  wire         AN_DATA1_PAD      ,
  input  wire         AN_RSTN_PAD       ,

  // ===== Core control hooks =====
  input  wire         TEST_MODE_PAD     ,          // tie 1'b1 in TB if needed
  input  wire         COR_START_PAD     ,
  output wire         RUST_VAL_PAD      ,
  output wire  [2:0]  RUST_DAT_PAD      ,


  // ===== Analog-front-end side (core-facing) =====
  input  wire         AN_CLK            , // !!need from port or from ADC
  input  wire         AN_DAT0           ,
  input  wire         AN_DAT1           ,
  //input  wire         AN_VAL            ,
  //input  wire         AN_RSTN           ,
  output wire         BUF_FUL           , // x not be used
//   output wire [31:0]  ANA_THR           ,
//   output wire [15:0]  DUMY_TRIM         ,
  output wire  [0:0]  AN_BG_EN              ,
  output wire  [3:0]  AN_BG_ICC_RCALIB      ,
  output wire  [0:0]  AN_CLK_EN             ,
  output wire  [0:0]  AN_COMP_EN            ,
  output wire  [0:0]  AN_OP_EN              ,
  output wire  [7:0]  AN_OFFSET_TRIMN       ,
  output wire  [7:0]  AN_OFFSET_TRIMP       ,
  output wire  [0:0]  AN_LDO_0P55_EN        ,
  output wire  [0:0]  AN_LDO_0P275_EN       ,
  output wire  [2:0]  AN_LDO1P25_IPP_CALIB  ,
  output wire  [2:0]  AN_LDO1P875_IPP_CALIB ,
  output wire  [0:0]  AN_rst                ,
  output wire  [5:0]  AN_LDO1P25_VREF_CALIB ,
  output wire  [5:0]  AN_LDO1P875_VREF_CALIB,
  output wire  [19:0] AN_dummy              ,  
  // ===== PAD control signals =====
  // clk PAD controls
  output wire        clk_DO,
  output wire        clk_IDDQ,
  output wire        clk_IE,
  output wire        clk_SMT,
  output wire        clk_PU,
  output wire        clk_PD,
  output wire        clk_OE,
  output wire        clk_PIN1,
  output wire        clk_PIN2,

  // rst_n PAD controls
  output wire        rst_n_DO,
  output wire        rst_n_IDDQ,
  output wire        rst_n_IE,
  output wire        rst_n_SMT,
  output wire        rst_n_PU,
  output wire        rst_n_PD,
  output wire        rst_n_OE,
  output wire        rst_n_PIN1,
  output wire        rst_n_PIN2,

  // JTAG TCK PAD controls
  output wire        jtag_TCK_DO,
  output wire        jtag_TCK_IDDQ,
  output wire        jtag_TCK_IE,
  output wire        jtag_TCK_SMT,
  output wire        jtag_TCK_PU,
  output wire        jtag_TCK_PD,
  output wire        jtag_TCK_OE,
  output wire        jtag_TCK_PIN1,
  output wire        jtag_TCK_PIN2,

  // JTAG TMS PAD controls
  output wire        jtag_TMS_DO,
  output wire        jtag_TMS_IDDQ,
  output wire        jtag_TMS_IE,
  output wire        jtag_TMS_SMT,
  output wire        jtag_TMS_PU,
  output wire        jtag_TMS_PD,
  output wire        jtag_TMS_OE,
  output wire        jtag_TMS_PIN1,
  output wire        jtag_TMS_PIN2,

  // JTAG TDI PAD controls
  output wire        jtag_TDI_DO,
  output wire        jtag_TDI_IDDQ,
  output wire        jtag_TDI_IE,
  output wire        jtag_TDI_SMT,
  output wire        jtag_TDI_PU,
  output wire        jtag_TDI_PD,
  output wire        jtag_TDI_OE,
  output wire        jtag_TDI_PIN1,
  output wire        jtag_TDI_PIN2,

  // JTAG TDO PAD controls (data = jtag_pin_TDO)
  output wire        jtag_TDO_IDDQ,
  output wire        jtag_TDO_IE,
  output wire        jtag_TDO_SMT,
  output wire        jtag_TDO_PU,
  output wire        jtag_TDO_PD,
  output wire        jtag_TDO_OE,
  output wire        jtag_TDO_PIN1,
  output wire        jtag_TDO_PIN2,

  // AN_VAL_PAD controls
  output wire        AN_VAL_PAD_DO,
  output wire        AN_VAL_PAD_IDDQ,
  output wire        AN_VAL_PAD_IE,
  output wire        AN_VAL_PAD_SMT,
  output wire        AN_VAL_PAD_PU,
  output wire        AN_VAL_PAD_PD,
  output wire        AN_VAL_PAD_OE,
  output wire        AN_VAL_PAD_PIN1,
  output wire        AN_VAL_PAD_PIN2,

  // rst_n PAD controls
  output wire        AN_RSTN_DO,
  output wire        AN_RSTN_IDDQ,
  output wire        AN_RSTN_IE,
  output wire        AN_RSTN_SMT,
  output wire        AN_RSTN_PU,
  output wire        AN_RSTN_PD,
  output wire        AN_RSTN_OE,
  output wire        AN_RSTN_PIN1,
  output wire        AN_RSTN_PIN2,

  // AN_SD_PAD controls
  output wire        AN_SD_PAD_DO,
  output wire        AN_SD_PAD_IDDQ,
  output wire        AN_SD_PAD_IE,
  output wire        AN_SD_PAD_SMT,
  output wire        AN_SD_PAD_PU,
  output wire        AN_SD_PAD_PD,
  output wire        AN_SD_PAD_OE,
  output wire        AN_SD_PAD_PIN1,
  output wire        AN_SD_PAD_PIN2,

  // AN_DATA0_PAD controls
  output wire        AN_DATA0_PAD_DO,
  output wire        AN_DATA0_PAD_IDDQ,
  output wire        AN_DATA0_PAD_IE,
  output wire        AN_DATA0_PAD_SMT,
  output wire        AN_DATA0_PAD_PU,
  output wire        AN_DATA0_PAD_PD,
  output wire        AN_DATA0_PAD_OE,
  output wire        AN_DATA0_PAD_PIN1,
  output wire        AN_DATA0_PAD_PIN2,

  // AN_DATA1_PAD controls
  output wire        AN_DATA1_PAD_DO,
  output wire        AN_DATA1_PAD_IDDQ,
  output wire        AN_DATA1_PAD_IE,
  output wire        AN_DATA1_PAD_SMT,
  output wire        AN_DATA1_PAD_PU,
  output wire        AN_DATA1_PAD_PD,
  output wire        AN_DATA1_PAD_OE,
  output wire        AN_DATA1_PAD_PIN1,
  output wire        AN_DATA1_PAD_PIN2,

  // TEST_MODE_PAD controls
  output wire        TEST_MODE_PAD_DO,
  output wire        TEST_MODE_PAD_IDDQ,
  output wire        TEST_MODE_PAD_IE,
  output wire        TEST_MODE_PAD_SMT,
  output wire        TEST_MODE_PAD_PU,
  output wire        TEST_MODE_PAD_PD,
  output wire        TEST_MODE_PAD_OE,
  output wire        TEST_MODE_PAD_PIN1,
  output wire        TEST_MODE_PAD_PIN2,

  // COR_START_PAD controls
  output wire        COR_START_PAD_DO,
  output wire        COR_START_PAD_IDDQ,
  output wire        COR_START_PAD_IE,
  output wire        COR_START_PAD_SMT,
  output wire        COR_START_PAD_PU,
  output wire        COR_START_PAD_PD,
  output wire        COR_START_PAD_OE,
  output wire        COR_START_PAD_PIN1,
  output wire        COR_START_PAD_PIN2,

  // RUST_VAL_PAD controls (data = RUST_VAL_PAD)
  output wire        RUST_VAL_PAD_IDDQ,
  output wire        RUST_VAL_PAD_IE,
  output wire        RUST_VAL_PAD_SMT,
  output wire        RUST_VAL_PAD_PU,
  output wire        RUST_VAL_PAD_PD,
  output wire        RUST_VAL_PAD_OE,
  output wire        RUST_VAL_PAD_PIN1,
  output wire        RUST_VAL_PAD_PIN2,

  // RUST_DAT_PAD[2:0] controls (shared for the 3 bits)
  output wire        RUST_DAT_PAD_IDDQ,
  output wire        RUST_DAT_PAD_IE,
  output wire        RUST_DAT_PAD_SMT,
  output wire        RUST_DAT_PAD_PU,
  output wire        RUST_DAT_PAD_PD,
  output wire        RUST_DAT_PAD_OE,
  output wire        RUST_DAT_PAD_PIN1,
  output wire        RUST_DAT_PAD_PIN2
);

//*** WIRE/REG *****************************************************************
  // ---------------------------
  // Wires between submodules
  // ---------------------------
  // RST
  wire                      rst_n_sync      ;
  wire                      AN_RSTN_SYNC    ;
  // JTAG <-> sys_regs
  wire                      reg_we          ;
  wire [ADDR_W-1:0]         reg_addr        ;
  wire [31:0]               reg_wdata       ;
  wire [31:0]               reg_rdata       ;
  wire                      op_req          ;   // enable for sys_regs

  // sys_regs <-> RAM bridge
  wire [3:0]                RAM_D_CFG0_den_bank_sel_o   ;
  wire [4:0]                RAM_D_CFG0_den_addr_o       ;
  wire                      RAM_D_CFG0_den_wr_enable_o  ;
  wire [15:0]               RAM_D_CFG0_den_wr_dat0_o    ;
  wire [31:0]               RAM_D_CFG1_den_wr_dat1_o    ;
  wire                      RAM_D_CSR_den_req_en_o      ;
  wire [15:0]               RAM_D_DAT0_den_rd_dat0_i    ;
  wire [31:0]               RAM_D_DAT1_den_rd_dat1_i    ;

//   wire [6:0]                RAM_L_CFG_lkup_addr_o       ;
//   wire                      RAM_L_CFG_lkup_wr_enable_o  ;
//   wire [12:0]               RAM_L_CFG_lkup_wr_dat_o     ;
//   wire                      RAM_L_CSR_lkup_req_en_o     ;
//   wire [12:0]               RAM_L_DAT0_lkup_rd_dat_i    ;

  wire [7:0]                RAM_S_CFG0_spr_addr_o       ;
  wire                      RAM_S_CFG0_spr_wr_enable_o  ;
  wire [1:0]                RAM_S_CSR_spr_wr_dat0_o     ;
  wire [31:0]               RAM_S_CFG1_spr_wr_dat1_o    ;
  wire [31:0]               RAM_S_CFG2_spr_wr_dat2_o    ;
  wire [31:0]               RAM_S_CFG3_spr_wr_dat3_o    ;
  wire [1:0]                RAM_S_CSR_spr_rd_dat0_i     ;
  wire [31:0]               RAM_S_DAT0_spr_rd_dat1_i    ;
  wire [31:0]               RAM_S_DAT1_spr_rd_dat2_i    ;
  wire [31:0]               RAM_S_DAT2_spr_rd_dat3_i    ;
  wire                      RAM_S_CSR_spr_req_en_o      ;

  // sys_regs -> core control (CDC/COR)
  wire                      ANA_CSR_ANA_TEST_ONLY_o     ;

  wire [7:0]                CDC_CONF_dat_grp_len_o      ;
  wire [7:0]                CDC_CONF_dat_grp_num_o      ;
  wire [8:0]                CDC_CONF_dat_grp_ful_o      ;
  wire                      CDC_CSR_an_val_o            ;
  wire                      CDC_CSR_dat_val_irq_en_o    ; // unused here
  wire                      CDC_CSR_dat_val_irq_i       ; // unused here
  wire                      CDC_CSR_cdc_test_only_o     ;
  wire                      CDC_TEST_lsm_start_ctl_o    ;
  wire                      CDC_TEST_lsm_step_ovr_o     ;
  wire                      CDC_TEST_lsm_done_ctl_o     ;

  wire [2:0]                COR_CONF_res_neu_cnt_cfg_o  ;
  wire                      COR_CONF_out_neu_cnt_cfg_o  ;
  wire [1:0]                COR_CONF_res_syn_cnt_cfg_o  ;
  wire [5:0]                COR_CONF_mem_thr_cfg_o      ;
  wire [4:0]                COR_CONF_neu_tau_cfg_o      ;
  wire                      COR_CONF_spr_wgt_bin_cfg_o  ;
  wire                      COR_CSR_test_halt_o         ;         
  wire                      COR_CSR_core_start_o        ;
  wire                      COR_CSR_result_out_irq_i    ;
  wire                      result_val_o                ;
                      
  wire [5:0]                COR_TEST_CFG_halt_state_o   ; // unused by core
  wire [10:0]               COR_TEST_CFG_halt_pnt_cnt_o ;
  wire [10:0]               COR_TEST_CFG_halt_rnt_cnt_o ;
  wire [3:0]                COR_TEST_CFG_halt_tnt_cnt_o ;
  wire [8:0]                COR_CALC_CPT0_CU0_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT0_CU1_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT0_CU2_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT1_CU3_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT1_CU4_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT1_CU5_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT2_CU6_sta_dat_i ;
  wire [8:0]                COR_CALC_CPT2_CU7_sta_dat_i ;
  // sys_regs readbacks (from core)
  wire [31:0]               CDC_DATA_0_cdc_dat0_i       ;
  wire [31:0]               CDC_DATA_1_cdc_dat1_i       ;
  wire [2:0]                COR_CSR_result_out_i        ;
  wire [2:0]                result_o                    ;
  // RAM bridge <-> core
  wire [3:0]                den_bank_sel_i              ;
  wire [4:0]                den_addr_i                  ;
  wire                      den_wr_val_i                ;
  wire                      den_rd_val_i                ;
  wire [47:0]               den_wr_dat_i                ;
  wire [47:0]               den_rd_dat_o                ;

//   wire [6:0]                spr_lkup_addr_i             ;
//   wire                      spr_lkup_wr_val_i           ;
//   wire                      spr_lkup_rd_val_i           ;
//   wire [12:0]               spr_lkup_wr_dat_i           ;
//   wire [12:0]               spr_lkup_rd_dat_o           ;

  wire [7:0]                spr_wgt_addr_i              ;
  wire                      spr_wgt_wr_val_i            ;
  wire [97:0]               spr_wgt_wr_dat_i            ;
  wire                      spr_wgt_rd_val_i            ;
  wire [97:0]               spr_wgt_rd_dat_o            ;

  
//*** MAIN BODY ****************************************************************
  //------------------------------
// IO PAD configuration
//------------------------------

// ===== clk PAD  (input only, no SMT, no pull) =====
assign clk_DO    = 1'b0;   // DO tied low for input-only pad
assign clk_IDDQ  = 1'b0;   // normal mode, no IDDQ test
assign clk_IE    = 1'b1;   // enable input buffer
assign clk_SMT   = 1'b0;   // no Schmitt trigger for clock
assign clk_PU    = 1'b0;   // no internal pull-up
assign clk_PD    = 1'b0;   // no internal pull-down
assign clk_OE    = 1'b0;   // disable output driver
assign clk_PIN1  = 1'b0;   // normal drive configuration
assign clk_PIN2  = 1'b0;

// ===== rst_n PAD  (input only, SMT enabled, no internal pull) =====
assign rst_n_DO   = 1'b0;  // DO tied low for input-only pad
assign rst_n_IDDQ = 1'b0;
assign rst_n_IE   = 1'b1;  // enable input buffer
assign rst_n_SMT  = 1'b1;  // Schmitt trigger for reset
assign rst_n_PU   = 1'b0;  // board-level pull-up will be used
assign rst_n_PD   = 1'b0;
assign rst_n_OE   = 1'b0;  // output driver disabled
assign rst_n_PIN1 = 1'b0;
assign rst_n_PIN2 = 1'b0;

// ===== JTAG TCK PAD  (input only, no pull) =====
assign jtag_TCK_DO   = 1'b0; // DO tied low for input-only pad
assign jtag_TCK_IDDQ = 1'b0;
assign jtag_TCK_IE   = 1'b1; // enable input buffer
assign jtag_TCK_SMT  = 1'b0; // no SMT on clock
assign jtag_TCK_PU   = 1'b0; // no internal pull
assign jtag_TCK_PD   = 1'b0;
assign jtag_TCK_OE   = 1'b0; // output driver disabled
assign jtag_TCK_PIN1 = 1'b0;
assign jtag_TCK_PIN2 = 1'b0;

// ===== JTAG TMS PAD  (input only, with pull-up) =====
assign jtag_TMS_DO   = 1'b0;
assign jtag_TMS_IDDQ = 1'b0;
assign jtag_TMS_IE   = 1'b1; // enable input buffer
assign jtag_TMS_SMT  = 1'b0;
assign jtag_TMS_PU   = 1'b1; // internal pull-up
assign jtag_TMS_PD   = 1'b0;
assign jtag_TMS_OE   = 1'b0; // output driver disabled
assign jtag_TMS_PIN1 = 1'b0;
assign jtag_TMS_PIN2 = 1'b0;

// ===== JTAG TDI PAD  (input only, with pull-up) =====
assign jtag_TDI_DO   = 1'b0;
assign jtag_TDI_IDDQ = 1'b0;
assign jtag_TDI_IE   = 1'b1; // enable input buffer
assign jtag_TDI_SMT  = 1'b0;
assign jtag_TDI_PU   = 1'b1; // internal pull-up
assign jtag_TDI_PD   = 1'b0;
assign jtag_TDI_OE   = 1'b0; // output driver disabled
assign jtag_TDI_PIN1 = 1'b0;
assign jtag_TDI_PIN2 = 1'b0;

// ===== JTAG TDO PAD  (output only, strong drive) =====
// Data comes from jtag_pin_TDO
assign jtag_TDO_IDDQ = 1'b0;
assign jtag_TDO_IE   = 1'b0; // input buffer disabled
assign jtag_TDO_SMT  = 1'b0;
assign jtag_TDO_PU   = 1'b0;
assign jtag_TDO_PD   = 1'b0;
assign jtag_TDO_OE   = 1'b1; // enable output driver
assign jtag_TDO_PIN1 = 1'b1; // strongest drive (PIN1=1, PIN2=1)
assign jtag_TDO_PIN2 = 1'b1;

// ===== AN_VAL_PAD  (input only, no pull) =====
assign AN_VAL_PAD_DO   = 1'b0;
assign AN_VAL_PAD_IDDQ = 1'b0;
assign AN_VAL_PAD_IE   = 1'b1; // enable input buffer
assign AN_VAL_PAD_SMT  = 1'b0;
assign AN_VAL_PAD_PU   = 1'b0;
assign AN_VAL_PAD_PD   = 1'b0;
assign AN_VAL_PAD_OE   = 1'b0; // output driver disabled
assign AN_VAL_PAD_PIN1 = 1'b0;
assign AN_VAL_PAD_PIN2 = 1'b0;

// ===== AN_RSTN_PAD  (input only, SMT enabled, no internal pull) =====
assign AN_RSTN_DO      = 1'b0;  // DO tied low for input-only pad
assign AN_RSTN_IDDQ    = 1'b0;
assign AN_RSTN_IE      = 1'b1;  // enable input buffer
assign AN_RSTN_SMT     = 1'b1;  // Schmitt trigger for reset
assign AN_RSTN_PU      = 1'b0;  // board-level pull-up will be used
assign AN_RSTN_PD      = 1'b0;
assign AN_RSTN_OE      = 1'b0;  // output driver disabled
assign AN_RSTN_PIN1    = 1'b0;
assign AN_RSTN_PIN2    = 1'b0;

// ===== AN_SD_PAD  (strap, default 0 = single-lead) =====
assign AN_SD_PAD_DO   = 1'b0;
assign AN_SD_PAD_IDDQ = 1'b0;
assign AN_SD_PAD_IE   = 1'b1; // read by core
assign AN_SD_PAD_SMT  = 1'b1; // SMT for strap stability
assign AN_SD_PAD_PU   = 1'b0;
assign AN_SD_PAD_PD   = 1'b0;
assign AN_SD_PAD_OE   = 1'b0;
assign AN_SD_PAD_PIN1 = 1'b0;
assign AN_SD_PAD_PIN2 = 1'b0;

// ===== AN_DATA0_PAD  (input only, no pull) =====
assign AN_DATA0_PAD_DO   = 1'b0;
assign AN_DATA0_PAD_IDDQ = 1'b0;
assign AN_DATA0_PAD_IE   = 1'b1;
assign AN_DATA0_PAD_SMT  = 1'b0;
assign AN_DATA0_PAD_PU   = 1'b0;
assign AN_DATA0_PAD_PD   = 1'b0;
assign AN_DATA0_PAD_OE   = 1'b0;
assign AN_DATA0_PAD_PIN1 = 1'b0;
assign AN_DATA0_PAD_PIN2 = 1'b0;

// ===== AN_DATA1_PAD  (input only, no pull) =====
assign AN_DATA1_PAD_DO   = 1'b0;
assign AN_DATA1_PAD_IDDQ = 1'b0;
assign AN_DATA1_PAD_IE   = 1'b1;
assign AN_DATA1_PAD_SMT  = 1'b0;
assign AN_DATA1_PAD_PU   = 1'b0;
assign AN_DATA1_PAD_PD   = 1'b0;
assign AN_DATA1_PAD_OE   = 1'b0;
assign AN_DATA1_PAD_PIN1 = 1'b0;
assign AN_DATA1_PAD_PIN2 = 1'b0;

// ===== TEST_MODE_PAD  (strap, default 1) =====
assign TEST_MODE_PAD_DO   = 1'b0;
assign TEST_MODE_PAD_IDDQ = 1'b0;
assign TEST_MODE_PAD_IE   = 1'b1;
assign TEST_MODE_PAD_SMT  = 1'b1; // SMT for strap signal
assign TEST_MODE_PAD_PU   = 1'b1; // default pull-up
assign TEST_MODE_PAD_PD   = 1'b0;
assign TEST_MODE_PAD_OE   = 1'b0;
assign TEST_MODE_PAD_PIN1 = 1'b0;
assign TEST_MODE_PAD_PIN2 = 1'b0;

// ===== COR_START_PAD  (input, default 0 = not started) =====
assign COR_START_PAD_DO   = 1'b0;
assign COR_START_PAD_IDDQ = 1'b0;
assign COR_START_PAD_IE   = 1'b1;
assign COR_START_PAD_SMT  = 1'b0; 
assign COR_START_PAD_PU   = 1'b0;
assign COR_START_PAD_PD   = 1'b0;
assign COR_START_PAD_OE   = 1'b0;
assign COR_START_PAD_PIN1 = 1'b0;
assign COR_START_PAD_PIN2 = 1'b0;

// ===== RUST_VAL_PAD  (output only, strong drive) =====
// Data is RUST_VAL_PAD itself
assign RUST_VAL_PAD_IDDQ = 1'b0;
assign RUST_VAL_PAD_IE   = 1'b0; // no input
assign RUST_VAL_PAD_SMT  = 1'b0;
assign RUST_VAL_PAD_PU   = 1'b0;
assign RUST_VAL_PAD_PD   = 1'b0;
assign RUST_VAL_PAD_OE   = 1'b1; // enable output driver
assign RUST_VAL_PAD_PIN1 = 1'b1; // strongest drive
assign RUST_VAL_PAD_PIN2 = 1'b1;

// ===== RUST_DAT_PAD[2:0]  (3-bit output bus, strong drive) =====
// Data is RUST_DAT_PAD[2:0]
assign RUST_DAT_PAD_IDDQ = 1'b0;
assign RUST_DAT_PAD_IE   = 1'b0; // no input
assign RUST_DAT_PAD_SMT  = 1'b0;
assign RUST_DAT_PAD_PU   = 1'b0;
assign RUST_DAT_PAD_PD   = 1'b0;
assign RUST_DAT_PAD_OE   = 1'b1; // bus output enabled
assign RUST_DAT_PAD_PIN1 = 1'b1; // strongest drive for the group
assign RUST_DAT_PAD_PIN2 = 1'b1;


  // ---------------------------
  // RST SYNC
  // ---------------------------
  rstn_sync D_RST_SYNC (
    .clk         (clk          ),
    .rstn_i      (rst_n        ),
    .rstn_o      (rst_n_sync   )
  );

  rstn_sync A_RST_SYNC (
    .clk         (AN_CLK       ),
    .rstn_i      (AN_RSTN_PAD  ),
    .rstn_o      (AN_RSTN_SYNC )
  );


  // ---------------------------
  // JTAG front-end
  // ---------------------------
  jtag #(
    .DMI_ADDR_BITS  (DMI_ADDR_BITS),
    .DMI_DATA_BITS  (DMI_DATA_BITS),
    .DMI_OP_BITS    (DMI_OP_BITS  )
  ) u_jtag (
    .clk            (clk          ),
    .rst_n          (rst_n_sync   ),
    .jtag_pin_TCK   (jtag_pin_TCK ),
    .jtag_pin_TMS   (jtag_pin_TMS ),
    .jtag_pin_TDI   (jtag_pin_TDI ),
    .jtag_pin_TDO   (jtag_pin_TDO ),
    .reg_we_o       (reg_we       ),
    .reg_addr_o     (reg_addr     ),
    .reg_wdata_o    (reg_wdata    ),
    .reg_rdata_i    (reg_rdata    ),
    .op_req_o       (op_req       )
  );

  // ---------------------------
  // sys_regs (auto-generated block)
  // ---------------------------
  sys_regs #(
    .ADDR_W(ADDR_W)
  ) u_sys_regs (
    .clk                        (clk                        ),
    .rst_n                      (rst_n_sync                 ),
    .en_i                       (op_req                     ),
    .we_i                       (reg_we                     ),
    .addr_i                     (reg_addr                   ),
    .wdata_i                    (reg_wdata                  ),
    .rdata_o                    (reg_rdata                  ),
    .rvalid_o                   (/*UNUSED   */              ),
    // AN region
    .ANA_CONF_BG_EN_o               (AN_BG_EN               ),    
    .ANA_CONF_BG_ICC_RCALIB_o       (AN_BG_ICC_RCALIB       ),    
    .ANA_CONF_CLK_EN_o              (AN_CLK_EN              ),                        
    .ANA_CONF_COMP_EN_o             (AN_COMP_EN             ),            
    .ANA_CONF_OP_EN_o               (AN_OP_EN               ),            
    .ANA_CONF_OFFSET_TRIMN_o        (AN_OFFSET_TRIMN        ),                    
    .ANA_CONF_OFFSET_TRIMP_o        (AN_OFFSET_TRIMP        ),                    
    .ANA_CONF_LDO_0P55_EN_o         (AN_LDO_0P55_EN         ),                
    .ANA_CONF_LDO_0P275_EN_o        (AN_LDO_0P275_EN        ),                    
    .ANA_CONF_LDO1P25_IPP_CALIB_o   (AN_LDO1P25_IPP_CALIB   ),                        
    .ANA_CONF_LDO1P875_IPP_CALIB_o  (AN_LDO1P875_IPP_CALIB  ),                        
    .ANA_CSR_ANA_TEST_ONLY_o        (ANA_CSR_ANA_TEST_ONLY_o),                    
    .ANA_CSR_rst_o                  (AN_rst                 ),        
    .ANA_CONF2_LDO1P25_VREF_CALIB_o (AN_LDO1P25_VREF_CALIB  ),                        
    .ANA_CONF2_LDO1P875_VREF_CALIB_o(AN_LDO1P875_VREF_CALIB ),                            
    .ANA_CONF2_dummy_o              (AN_dummy               ), 
             
    //.ANA_CONF_ANA_THR_o         (ANA_THR                    ),
    //.ANA_CSR_ANA_TEST_ONLY_o    (ANA_CSR_ANA_TEST_ONLY_o    ),
    //.ANA_DUMY_CONTROL_o         (DUMY_TRIM                  ),
    // CDC region
    .CDC_CONF_dat_grp_len_o     (CDC_CONF_dat_grp_len_o     ),
    .CDC_CONF_dat_grp_num_o     (CDC_CONF_dat_grp_num_o     ),
    .CDC_CONF_dat_grp_ful_o     (CDC_CONF_dat_grp_ful_o     ),
    .CDC_CSR_an_val_o           (CDC_CSR_an_val_o           ),
  //  .CDC_CSR_dat_val_irq_en_o   (CDC_CSR_dat_val_irq_en_o   ),
    .CDC_CSR_dat_val_irq_i      (CDC_CSR_dat_val_irq_i      ),
    .CDC_CSR_cdc_test_only_o    (CDC_CSR_cdc_test_only_o    ),
    .CDC_TEST_lsm_start_ctl_o   (CDC_TEST_lsm_start_ctl_o   ),
    .CDC_TEST_lsm_step_ovr_o    (CDC_TEST_lsm_step_ovr_o    ),
    .CDC_TEST_lsm_done_ctl_o    (CDC_TEST_lsm_done_ctl_o    ),

    // CDC readbacks from core
    .CDC_DATA_0_cdc_dat0_i      (CDC_DATA_0_cdc_dat0_i      ),
    .CDC_DATA_1_cdc_dat1_i      (CDC_DATA_1_cdc_dat1_i      ),

    // COR region (config)
    .COR_CONF_res_neu_cnt_cfg_o (COR_CONF_res_neu_cnt_cfg_o ),
    .COR_CONF_out_neu_cnt_cfg_o (COR_CONF_out_neu_cnt_cfg_o ),
    .COR_CONF_res_syn_cnt_cfg_o (COR_CONF_res_syn_cnt_cfg_o ),
    .COR_CONF_mem_thr_cfg_o     (COR_CONF_mem_thr_cfg_o     ),
    .COR_CONF_neu_tau_cfg_o     (COR_CONF_neu_tau_cfg_o     ),
    .COR_CONF_spr_wgt_bin_cfg_o (COR_CONF_spr_wgt_bin_cfg_o ),
    .COR_CSR_test_halt_o        (COR_CSR_test_halt_o        ),
    .COR_CSR_irq_en_o           (/*UNUSED                 */),
    .COR_CSR_core_start_o       (COR_CSR_core_start_o       ),
    .COR_CSR_result_out_irq_i   (COR_CSR_result_out_irq_i   ),
    .COR_TEST_CFG_halt_state_o  (COR_TEST_CFG_halt_state_o  ),
    .COR_TEST_CFG_halt_pnt_cnt_o(COR_TEST_CFG_halt_pnt_cnt_o),
    .COR_TEST_CFG_halt_rnt_cnt_o(COR_TEST_CFG_halt_rnt_cnt_o),
    .COR_TEST_CFG_halt_tnt_cnt_o(COR_TEST_CFG_halt_tnt_cnt_o),

    // COR readbacks
    .COR_CSR_result_out_i       (COR_CSR_result_out_i       ),
    .COR_CALC_CPT0_CU0_sta_dat_i(COR_CALC_CPT0_CU0_sta_dat_i),
    .COR_CALC_CPT0_CU1_sta_dat_i(COR_CALC_CPT0_CU1_sta_dat_i),
    .COR_CALC_CPT0_CU2_sta_dat_i(COR_CALC_CPT0_CU2_sta_dat_i),
    .COR_CALC_CPT1_CU3_sta_dat_i(COR_CALC_CPT1_CU3_sta_dat_i),
    .COR_CALC_CPT1_CU4_sta_dat_i(COR_CALC_CPT1_CU4_sta_dat_i),
    .COR_CALC_CPT1_CU5_sta_dat_i(COR_CALC_CPT1_CU5_sta_dat_i),
    .COR_CALC_CPT2_CU6_sta_dat_i(COR_CALC_CPT2_CU6_sta_dat_i),
    .COR_CALC_CPT2_CU7_sta_dat_i(COR_CALC_CPT2_CU7_sta_dat_i),

    // RAM_D block (to bridge)
    .RAM_D_CFG0_den_bank_sel_o  (RAM_D_CFG0_den_bank_sel_o  ),
    .RAM_D_CFG0_den_addr_o      (RAM_D_CFG0_den_addr_o      ),
    .RAM_D_CFG0_den_wr_enable_o (RAM_D_CFG0_den_wr_enable_o ),
    .RAM_D_CFG0_den_wr_dat0_o   (RAM_D_CFG0_den_wr_dat0_o   ),
    .RAM_D_CFG1_den_wr_dat1_o   (RAM_D_CFG1_den_wr_dat1_o   ),
    .RAM_D_CSR_den_req_en_o     (RAM_D_CSR_den_req_en_o     ),
    .RAM_D_DAT0_den_rd_dat0_i   (RAM_D_DAT0_den_rd_dat0_i   ),
    .RAM_D_DAT1_den_rd_dat1_i   (RAM_D_DAT1_den_rd_dat1_i   ),

    // // RAM_L block (to bridge)
    // .RAM_L_CFG_lkup_addr_o      (RAM_L_CFG_lkup_addr_o      ),
    // .RAM_L_CFG_lkup_wr_enable_o (RAM_L_CFG_lkup_wr_enable_o ),
    // .RAM_L_CFG_lkup_wr_dat_o    (RAM_L_CFG_lkup_wr_dat_o    ),
    // .RAM_L_CSR_lkup_req_en_o    (RAM_L_CSR_lkup_req_en_o    ),
    // .RAM_L_DAT0_lkup_rd_dat_i   (RAM_L_DAT0_lkup_rd_dat_i   ),

    // RAM_S block (to bridge)
    .RAM_S_CFG0_spr_addr_o      (RAM_S_CFG0_spr_addr_o      ),
    .RAM_S_CFG0_spr_wr_enable_o (RAM_S_CFG0_spr_wr_enable_o ),
    .RAM_S_CSR_spr_wr_dat0_o    (RAM_S_CSR_spr_wr_dat0_o    ),
    .RAM_S_CFG1_spr_wr_dat1_o   (RAM_S_CFG1_spr_wr_dat1_o   ),
    .RAM_S_CFG2_spr_wr_dat2_o   (RAM_S_CFG2_spr_wr_dat2_o   ),
    .RAM_S_CFG3_spr_wr_dat3_o   (RAM_S_CFG3_spr_wr_dat3_o   ),
    .RAM_S_CSR_spr_rd_dat0_i    (RAM_S_CSR_spr_rd_dat0_i    ),
    .RAM_S_DAT0_spr_rd_dat1_i   (RAM_S_DAT0_spr_rd_dat1_i   ),
    .RAM_S_DAT1_spr_rd_dat2_i   (RAM_S_DAT1_spr_rd_dat2_i   ),
    .RAM_S_DAT2_spr_rd_dat3_i   (RAM_S_DAT2_spr_rd_dat3_i   ),
    .RAM_S_CSR_spr_req_en_o     (RAM_S_CSR_spr_req_en_o     )
  );

  // ---------------------------
  // RAM bridge (sys_regs <-> core)
  // ---------------------------
  ram_intf u_ram_intf (
    .clk                        (clk                        ),
    .rst_n                      (rst_n_sync                 ),

    // from sys_regs
    .RAM_D_CFG0_den_bank_sel_o  (RAM_D_CFG0_den_bank_sel_o  ),
    .RAM_D_CFG0_den_addr_o      (RAM_D_CFG0_den_addr_o      ),
    .RAM_D_CFG0_den_wr_enable_o (RAM_D_CFG0_den_wr_enable_o ),
    .RAM_D_CFG0_den_wr_dat0_o   (RAM_D_CFG0_den_wr_dat0_o   ),
    .RAM_D_CFG1_den_wr_dat1_o   (RAM_D_CFG1_den_wr_dat1_o   ),
    .RAM_D_CSR_den_req_en_o     (RAM_D_CSR_den_req_en_o     ),
    .RAM_D_DAT0_den_rd_dat0_i   (RAM_D_DAT0_den_rd_dat0_i   ),
    .RAM_D_DAT1_den_rd_dat1_i   (RAM_D_DAT1_den_rd_dat1_i   ),

    // .RAM_L_CFG_lkup_addr_o      (RAM_L_CFG_lkup_addr_o      ),
    // .RAM_L_CFG_lkup_wr_enable_o (RAM_L_CFG_lkup_wr_enable_o ),
    // .RAM_L_CFG_lkup_wr_dat_o    (RAM_L_CFG_lkup_wr_dat_o    ),
    // .RAM_L_CSR_lkup_req_en_o    (RAM_L_CSR_lkup_req_en_o    ),
    // .RAM_L_DAT0_lkup_rd_dat_i   (RAM_L_DAT0_lkup_rd_dat_i   ),

    .RAM_S_CFG0_spr_addr_o      (RAM_S_CFG0_spr_addr_o      ),
    .RAM_S_CFG0_spr_wr_enable_o (RAM_S_CFG0_spr_wr_enable_o ),
    .RAM_S_CSR_spr_req_en_o     (RAM_S_CSR_spr_req_en_o     ),
    .RAM_S_CSR_spr_wr_dat0_o    (RAM_S_CSR_spr_wr_dat0_o    ),
    .RAM_S_CFG1_spr_wr_dat1_o   (RAM_S_CFG1_spr_wr_dat1_o   ),
    .RAM_S_CFG2_spr_wr_dat2_o   (RAM_S_CFG2_spr_wr_dat2_o   ),
    .RAM_S_CFG3_spr_wr_dat3_o   (RAM_S_CFG3_spr_wr_dat3_o   ),
    .RAM_S_CSR_spr_rd_dat0_i    (RAM_S_CSR_spr_rd_dat0_i    ),
    .RAM_S_DAT0_spr_rd_dat1_i   (RAM_S_DAT0_spr_rd_dat1_i   ),
    .RAM_S_DAT1_spr_rd_dat2_i   (RAM_S_DAT1_spr_rd_dat2_i   ),
    .RAM_S_DAT2_spr_rd_dat3_i   (RAM_S_DAT2_spr_rd_dat3_i   ),

    // to core (dense/sparse buses)
    .den_bank_sel_i             (den_bank_sel_i             ),
    .den_addr_i                 (den_addr_i                 ),
    .den_wr_val_i               (den_wr_val_i               ),
    .den_wr_dat_i               (den_wr_dat_i               ),
    .den_rd_val_i               (den_rd_val_i               ),
    .den_rd_dat_o               (den_rd_dat_o               ),

    // .spr_lkup_addr_i            (spr_lkup_addr_i            ),
    // .spr_lkup_wr_val_i          (spr_lkup_wr_val_i          ),
    // .spr_lkup_rd_val_i          (spr_lkup_rd_val_i          ),
    // .spr_lkup_wr_dat_i          (spr_lkup_wr_dat_i          ),
    // .spr_lkup_rd_dat_o          (spr_lkup_rd_dat_o          ),

    .spr_wgt_addr_i             (spr_wgt_addr_i             ),
    .spr_wgt_wr_val_i           (spr_wgt_wr_val_i           ),
    .spr_wgt_wr_dat_i           (spr_wgt_wr_dat_i           ),
    .spr_wgt_rd_val_i           (spr_wgt_rd_val_i           ),
    .spr_wgt_rd_dat_o           (spr_wgt_rd_dat_o           )
  );

  // ---------------------------
  // LSM core
  // ---------------------------
  // Gate analog-valid with register bit (mirrors TB)
  wire AN_VAL    ;
  wire COR_AN_VAL;
  wire COR_AN_DAT0 ;
  wire COR_AN_DAT1 ;
  assign AN_VAL  = 1'b1 ;
  assign COR_AN_VAL  = ANA_CSR_ANA_TEST_ONLY_o ? CDC_CSR_an_val_o & AN_VAL_PAD : 
                                        AN_VAL & CDC_CSR_an_val_o & AN_VAL_PAD ;
  assign COR_AN_DAT0 = ANA_CSR_ANA_TEST_ONLY_o ? AN_DATA0_PAD : AN_DAT0        ;
  assign COR_AN_DAT1 = ANA_CSR_ANA_TEST_ONLY_o ? AN_DATA1_PAD : AN_DAT1        ;
  
  // cdc_test path fanout
  wire        cdc_test_only_i     ;
  wire        cdc_test_strat_ctl_i;
  wire        cdc_test_step_over_i;
  wire        cdc_test_done_ctl_i ;
  wire [71:0] cor_CU_dat          ;
  wire        cor_glb_start_trg_i ;
  assign cdc_test_only_i      = CDC_CSR_cdc_test_only_o ;
  assign cdc_test_strat_ctl_i = CDC_TEST_lsm_start_ctl_o;
  assign cdc_test_step_over_i = CDC_TEST_lsm_step_ovr_o ;
  assign cdc_test_done_ctl_i  = CDC_TEST_lsm_done_ctl_o ;
  assign cor_glb_start_trg_i  = COR_CSR_core_start_o & COR_START_PAD ;
  // Core instance
  lsm_core #(
    .CU_NUM               ( CU_NUM                  )
  ) u_lsm_core (
    // ANALOG domain
    .AN_CLK               (AN_CLK                   ),
    .AN_DAT0              (COR_AN_DAT0              ),
    .AN_DAT1              (COR_AN_DAT1              ),
    .AN_VAL               (COR_AN_VAL               ),
    .AN_RSTN              (AN_RSTN_SYNC             ),
    .BUF_FUL              (BUF_FUL                  ),
    .AN_SD_ACTIVE_NUM     (AN_SD_PAD                ),

    // digital        
    .clk                  (clk                      ),
    .rstn                 (rst_n_sync               ),
    .TEST_MODE            (TEST_MODE_PAD            ),
    .glb_start_trg_i      (cor_glb_start_trg_i      ),

    // CDC configs
    .dat_grp_len_cfg_i    (CDC_CONF_dat_grp_len_o   ),
    .dat_grp_num_cfg_i    (CDC_CONF_dat_grp_num_o   ),
    .dat_grp_ful_cfg_i    (CDC_CONF_dat_grp_ful_o   ),

    // test path controls
    .cdc_test_only_i      (cdc_test_only_i          ),
    .cdc_test_strat_ctl_i (cdc_test_strat_ctl_i     ),
    .cdc_test_step_over_i (cdc_test_step_over_i     ),
    .cdc_test_done_ctl_i  (cdc_test_done_ctl_i      ),
    .cdc_test_dat0_o      (CDC_DATA_0_cdc_dat0_i    ),
    .cdc_test_dat1_o      (CDC_DATA_1_cdc_dat1_i    ),
    .cdc_test_irq         (CDC_CSR_dat_val_irq_i    ),

    // COR configs
    .res_neu_cnt_cfg_i    (COR_CONF_res_neu_cnt_cfg_o ),
    .out_neu_cnt_cfg_i    (COR_CONF_out_neu_cnt_cfg_o ),
    .res_syn_cnt_cfg_i    (COR_CONF_res_syn_cnt_cfg_o ),
    .cfg_mem_thr_i        (COR_CONF_mem_thr_cfg_o     ),
    .cfg_mem_tau_i        (COR_CONF_neu_tau_cfg_o     ),

    // Dense RAM buses
    .den_bank_sel_i       (den_bank_sel_i             ),
    .den_addr_i           (den_addr_i                 ),
    .den_wr_val_i         (den_wr_val_i               ),
    .den_wr_dat_i         (den_wr_dat_i               ),
    .den_rd_val_i         (den_rd_val_i               ),
    .den_rd_dat_o         (den_rd_dat_o               ),

    // Lookup RAM buses
    // .spr_lkup_addr_i      (spr_lkup_addr_i            ),
    // .spr_lkup_wr_val_i    (spr_lkup_wr_val_i          ),
    // .spr_lkup_wr_dat_i    (spr_lkup_wr_dat_i          ),
    // .spr_lkup_rd_val_i    (spr_lkup_rd_val_i          ),
    // .spr_lkup_rd_dat_o    (spr_lkup_rd_dat_o          ),

    // Sparse weight store
    .spr_wgt_bin_depth_i  (COR_CONF_spr_wgt_bin_cfg_o ),
    .spr_wgt_addr_i       (spr_wgt_addr_i             ),
    .spr_wgt_wr_val_i     (spr_wgt_wr_val_i           ),
    .spr_wgt_wr_dat_i     (spr_wgt_wr_dat_i           ),
    .spr_wgt_rd_val_i     (spr_wgt_rd_val_i           ),
    .spr_wgt_rd_dat_o     (spr_wgt_rd_dat_o           ),

    // Results
    .result_o             (result_o                   ),
    .result_val_o         (result_val_o               ),
    .cor_test_halt        (COR_CSR_test_halt_o        ),   
    .cor_halt_state       (COR_TEST_CFG_halt_state_o  ),
    .cor_halt_pnt         (COR_TEST_CFG_halt_pnt_cnt_o),
    .cor_halt_rnt         (COR_TEST_CFG_halt_rnt_cnt_o),
    .cor_halt_tnt         (COR_TEST_CFG_halt_tnt_cnt_o),
    .cor_CU_dat           (cor_CU_dat                 )

  );
  
  // Map 3 LSBs of result as COR_CSR_result_out_i for sys_regs readback
  assign COR_CSR_result_out_i = result_o;
  assign {COR_CALC_CPT2_CU7_sta_dat_i,
          COR_CALC_CPT2_CU6_sta_dat_i,
          COR_CALC_CPT1_CU5_sta_dat_i,
          COR_CALC_CPT1_CU4_sta_dat_i,
          COR_CALC_CPT1_CU3_sta_dat_i,
          COR_CALC_CPT0_CU2_sta_dat_i,
          COR_CALC_CPT0_CU1_sta_dat_i,
          COR_CALC_CPT0_CU0_sta_dat_i} = cor_CU_dat ;
  assign COR_CSR_result_out_irq_i = result_val_o ;
  assign RUST_VAL_PAD = result_val_o ;
  assign RUST_DAT_PAD = result_o     ;
endmodule
