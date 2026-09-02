// Auto-generated (one always block per 32-bit register, with en_i and registered read)
module sys_regs #(
  parameter ADDR_W = 6
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire               en_i,
  input  wire               we_i,
  input  wire [ADDR_W-1:0]  addr_i,
  input  wire [31:0]        wdata_i,
  output reg  [31:0]        rdata_o,
  output reg                rvalid_o,
  //output reg  [31:0] ANA_CONF_ANA_THR_o,
  //output reg  [0:0] ANA_CSR_ANA_TEST_ONLY_o,
  //output reg  [15:0] ANA_DUMY_CONTROL_o,
  output reg  [0:0] ANA_CONF_BG_EN_o,
  output reg  [3:0] ANA_CONF_BG_ICC_RCALIB_o,
  output reg  [0:0] ANA_CONF_CLK_EN_o,
  output reg  [0:0] ANA_CONF_COMP_EN_o,
  output reg  [0:0] ANA_CONF_OP_EN_o,
  output reg  [7:0] ANA_CONF_OFFSET_TRIMN_o,
  output reg  [7:0] ANA_CONF_OFFSET_TRIMP_o,
  output reg  [0:0] ANA_CONF_LDO_0P55_EN_o,
  output reg  [0:0] ANA_CONF_LDO_0P275_EN_o,
  output reg  [2:0] ANA_CONF_LDO1P25_IPP_CALIB_o,
  output reg  [2:0] ANA_CONF_LDO1P875_IPP_CALIB_o,
  output reg  [0:0] ANA_CSR_ANA_TEST_ONLY_o,
  output reg  [0:0] ANA_CSR_rst_o,
  output reg  [5:0] ANA_CONF2_LDO1P25_VREF_CALIB_o,
  output reg  [5:0] ANA_CONF2_LDO1P875_VREF_CALIB_o,
  output reg  [19:0] ANA_CONF2_dummy_o,  
  output reg  [7:0] CDC_CONF_dat_grp_len_o,
  output reg  [7:0] CDC_CONF_dat_grp_num_o,
  output reg  [8:0] CDC_CONF_dat_grp_ful_o,
  output reg  [0:0] CDC_CSR_an_val_o,
  output reg  [0:0] CDC_CSR_dat_val_irq_en_o,
  input  wire [0:0] CDC_CSR_dat_val_irq_i,
  output reg  [0:0] CDC_CSR_cdc_test_only_o,
  output reg  [0:0] CDC_TEST_lsm_start_ctl_o,
  output reg  [0:0] CDC_TEST_lsm_step_ovr_o,
  output reg  [0:0] CDC_TEST_lsm_done_ctl_o,
  output reg  [3:0] RAM_D_CFG0_den_bank_sel_o,
  output reg  [4:0] RAM_D_CFG0_den_addr_o,
  output reg  [0:0] RAM_D_CFG0_den_wr_enable_o,
  output reg  [15:0] RAM_D_CFG0_den_wr_dat0_o,
  output reg  [31:0] RAM_D_CFG1_den_wr_dat1_o,
  output reg  [0:0] RAM_D_CSR_den_req_en_o,
  input wire  [15:0] RAM_D_DAT0_den_rd_dat0_i,
  input wire  [31:0] RAM_D_DAT1_den_rd_dat1_i,

//   output reg  [6:0] RAM_L_CFG_lkup_addr_o,
//   output reg  [0:0] RAM_L_CFG_lkup_wr_enable_o,
//   output reg  [12:0] RAM_L_CFG_lkup_wr_dat_o,
//   output reg  [0:0] RAM_L_CSR_lkup_req_en_o,
//   input  wire [12:0] RAM_L_DAT0_lkup_rd_dat_i,

  output reg  [7:0]  RAM_S_CFG0_spr_addr_o     ,
  output reg  [0:0]  RAM_S_CFG0_spr_wr_enable_o,
  output reg  [31:0] RAM_S_CFG1_spr_wr_dat1_o  ,
  output reg  [31:0] RAM_S_CFG2_spr_wr_dat2_o  ,
  output reg  [31:0] RAM_S_CFG3_spr_wr_dat3_o  ,
  input  wire [31:0] RAM_S_DAT0_spr_rd_dat1_i  ,
  input  wire [31:0] RAM_S_DAT1_spr_rd_dat2_i  ,
  input  wire [31:0] RAM_S_DAT2_spr_rd_dat3_i  ,
  output reg  [0:0] RAM_S_CSR_spr_req_en_o,
  output reg  [1:0] RAM_S_CSR_spr_wr_dat0_o,
  input  wire [1:0] RAM_S_CSR_spr_rd_dat0_i,  
  output reg  [2:0] COR_CONF_res_neu_cnt_cfg_o,
  output reg  [0:0] COR_CONF_out_neu_cnt_cfg_o,
  output reg  [1:0] COR_CONF_res_syn_cnt_cfg_o,
  output reg  [5:0] COR_CONF_mem_thr_cfg_o,
  output reg  [4:0] COR_CONF_neu_tau_cfg_o,
  output reg  [0:0] COR_CONF_spr_wgt_bin_cfg_o,
  output reg  [0:0] COR_CSR_test_halt_o,
  output reg  [0:0] COR_CSR_irq_en_o,
  output reg  [0:0] COR_CSR_core_start_o,
  input  wire [0:0] COR_CSR_result_out_irq_i,
  output reg  [5:0] COR_TEST_CFG_halt_state_o,
  output reg  [10:0] COR_TEST_CFG_halt_pnt_cnt_o,
  output reg  [10:0] COR_TEST_CFG_halt_rnt_cnt_o,
  output reg  [3:0] COR_TEST_CFG_halt_tnt_cnt_o,
  input  wire [31:0] CDC_DATA_0_cdc_dat0_i,
  input  wire [31:0] CDC_DATA_1_cdc_dat1_i,


  input  wire [2:0] COR_CSR_result_out_i,
  input  wire [8:0] COR_CALC_CPT0_CU0_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT0_CU1_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT0_CU2_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT1_CU3_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT1_CU4_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT1_CU5_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT2_CU6_sta_dat_i,
  input  wire [8:0] COR_CALC_CPT2_CU7_sta_dat_i
);

// Address constants
localparam [ADDR_W-1:0] ADDR_ANA_CONF = 6'd0;
localparam [ADDR_W-1:0] ADDR_ANA_CSR = 6'd1;
localparam [ADDR_W-1:0] ADDR_ANA_CONF2 = 6'd2;
localparam [ADDR_W-1:0] ADDR_ANA_DUMY = 6'd2;
localparam [ADDR_W-1:0] ADDR_CDC_CONF = 6'd3;
localparam [ADDR_W-1:0] ADDR_CDC_CSR = 6'd4;
localparam [ADDR_W-1:0] ADDR_CDC_TEST = 6'd5;
localparam [ADDR_W-1:0] ADDR_CDC_DATA_0 = 6'd6;
localparam [ADDR_W-1:0] ADDR_CDC_DATA_1 = 6'd7;
localparam [ADDR_W-1:0] ADDR_RAM_D_CFG0 = 6'd9;
localparam [ADDR_W-1:0] ADDR_RAM_D_CFG1 = 6'd10;
localparam [ADDR_W-1:0] ADDR_RAM_D_CSR = 6'd11;
localparam [ADDR_W-1:0] ADDR_RAM_D_DAT0 = 6'd12;
localparam [ADDR_W-1:0] ADDR_RAM_D_DAT1 = 6'd13;
// localparam [ADDR_W-1:0] ADDR_RAM_L_CFG = 6'd15;
// localparam [ADDR_W-1:0] ADDR_RAM_L_CSR = 6'd16;
// localparam [ADDR_W-1:0] ADDR_RAM_L_DAT0 = 6'd17;
localparam [ADDR_W-1:0] ADDR_RAM_S_CFG0 = 6'd19;
localparam [ADDR_W-1:0] ADDR_RAM_S_CFG1 = 6'd20;
localparam [ADDR_W-1:0] ADDR_RAM_S_CFG2 = 6'd21;
localparam [ADDR_W-1:0] ADDR_RAM_S_CFG3 = 6'd22;
localparam [ADDR_W-1:0] ADDR_RAM_S_CSR = 6'd23;
localparam [ADDR_W-1:0] ADDR_RAM_S_DAT0 = 6'd24;
localparam [ADDR_W-1:0] ADDR_RAM_S_DAT1 = 6'd25;
localparam [ADDR_W-1:0] ADDR_RAM_S_DAT2 = 6'd26;
localparam [ADDR_W-1:0] ADDR_COR_CONF = 6'd28;
localparam [ADDR_W-1:0] ADDR_COR_CSR = 6'd29;
localparam [ADDR_W-1:0] ADDR_COR_TEST_CFG = 6'd30;
localparam [ADDR_W-1:0] ADDR_COR_CALC_CPT0 = 6'd31;
localparam [ADDR_W-1:0] ADDR_COR_CALC_CPT1 = 6'd32;
localparam [ADDR_W-1:0] ADDR_COR_CALC_CPT2 = 6'd33;

reg  [0:0] CDC_CSR_dat_val_irq_o ;
reg  [0:0] COR_CSR_result_out_irq_o;
// ANA_CONF register block @ ADDR_ANA_CONF
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    ANA_CONF_BG_EN_o <= 1'h1;
    ANA_CONF_BG_ICC_RCALIB_o <= 4'd1;
    ANA_CONF_CLK_EN_o <= 1'h1;
    ANA_CONF_COMP_EN_o <= 1'h1;
    ANA_CONF_OP_EN_o <= 1'h1;
    ANA_CONF_OFFSET_TRIMN_o <= 8'd172;
    ANA_CONF_OFFSET_TRIMP_o <= 8'd108;
    ANA_CONF_LDO_0P55_EN_o <= 1'h1;
    ANA_CONF_LDO_0P275_EN_o <= 1'h1;
    ANA_CONF_LDO1P25_IPP_CALIB_o <= 3'h2;
    ANA_CONF_LDO1P875_IPP_CALIB_o <= 3'h2;
  end else begin
    if (en_i && we_i && addr_i == ADDR_ANA_CONF) begin
      ANA_CONF_BG_EN_o <= wdata_i[0];
      ANA_CONF_BG_ICC_RCALIB_o <= wdata_i[4:1];
      ANA_CONF_CLK_EN_o <= wdata_i[5];
      ANA_CONF_COMP_EN_o <= wdata_i[6];
      ANA_CONF_OP_EN_o <= wdata_i[7];
      ANA_CONF_OFFSET_TRIMN_o <= wdata_i[15:8];
      ANA_CONF_OFFSET_TRIMP_o <= wdata_i[23:16];
      ANA_CONF_LDO_0P55_EN_o <= wdata_i[24];
      ANA_CONF_LDO_0P275_EN_o <= wdata_i[25];
      ANA_CONF_LDO1P25_IPP_CALIB_o <= wdata_i[28:26];
      ANA_CONF_LDO1P875_IPP_CALIB_o <= wdata_i[31:29];
    end
  end
end
// ANA_CONF2 register block @ ADDR_ANA_CONF2
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    ANA_CONF2_LDO1P25_VREF_CALIB_o <= 6'd31;
    ANA_CONF2_LDO1P875_VREF_CALIB_o <= 6'd33;
    ANA_CONF2_dummy_o <= 20'b1111_1000_0011_1110_0010;
  end else begin
    if (en_i && we_i && addr_i == ADDR_ANA_CONF2) begin
      ANA_CONF2_LDO1P25_VREF_CALIB_o <= wdata_i[5:0];
      ANA_CONF2_LDO1P875_VREF_CALIB_o <= wdata_i[11:6];
      ANA_CONF2_dummy_o <= wdata_i[31:12];
    end
  end
end
// ANA_CSR register block @ ADDR_ANA_CSR
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    ANA_CSR_ANA_TEST_ONLY_o <= 1'h0;
    ANA_CSR_rst_o <= 1'h1;
  end else begin
    if (en_i && we_i && addr_i == ADDR_ANA_CSR) begin
      ANA_CSR_ANA_TEST_ONLY_o <= wdata_i[0];
      ANA_CSR_rst_o <= wdata_i[1];
    end
  end
end

// CDC_CONF register block @ ADDR_CDC_CONF
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    CDC_CONF_dat_grp_len_o <= 8'h0A;
    CDC_CONF_dat_grp_num_o <= 8'h1E;
    CDC_CONF_dat_grp_ful_o <= 9'h12B;
  end else begin
    if (en_i && we_i && addr_i == ADDR_CDC_CONF) begin
      CDC_CONF_dat_grp_len_o <= wdata_i[7:0];
      CDC_CONF_dat_grp_num_o <= wdata_i[15:8];
      CDC_CONF_dat_grp_ful_o <= wdata_i[24:16];
    end
  end
end

// CDC_CSR register block @ ADDR_CDC_CSR
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    CDC_CSR_an_val_o <= 1'h0;
    CDC_CSR_dat_val_irq_en_o <= 1'h0;
    CDC_CSR_cdc_test_only_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_CDC_CSR) begin
      CDC_CSR_an_val_o <= wdata_i[0];
      CDC_CSR_dat_val_irq_en_o <= wdata_i[1];
      CDC_CSR_cdc_test_only_o <= wdata_i[3];
    end
  end
end

// CDC_CSR irq W1C logic
reg CDC_CSR_dat_val_irq_r ;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    CDC_CSR_dat_val_irq_r <= 1'b0;
  end else begin
    CDC_CSR_dat_val_irq_r <= CDC_CSR_dat_val_irq_i ;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    CDC_CSR_dat_val_irq_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_CDC_CSR) begin
      CDC_CSR_dat_val_irq_o <= !(CDC_CSR_dat_val_irq_o &  wdata_i[2]);
    end
    else if (~CDC_CSR_dat_val_irq_r & CDC_CSR_dat_val_irq_i)begin
      CDC_CSR_dat_val_irq_o <= 'd1 ;
    end
  end
end

// CDC_TEST register block @ ADDR_CDC_TEST
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    CDC_TEST_lsm_start_ctl_o <= 1'h0;
    CDC_TEST_lsm_step_ovr_o <= 1'h0;
    CDC_TEST_lsm_done_ctl_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_CDC_TEST) begin
      CDC_TEST_lsm_start_ctl_o <= wdata_i[0];
      CDC_TEST_lsm_step_ovr_o  <= wdata_i[1];
      CDC_TEST_lsm_done_ctl_o  <= wdata_i[2];
    end else begin
      CDC_TEST_lsm_step_ovr_o  <= 'd0;
      CDC_TEST_lsm_done_ctl_o  <= 'd0;
    end
  end
end

// RAM_D_CFG0 register block @ ADDR_RAM_D_CFG0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_D_CFG0_den_bank_sel_o <= 4'h0;
    RAM_D_CFG0_den_addr_o <= 5'h00;
    RAM_D_CFG0_den_wr_enable_o <= 1'h0;
    RAM_D_CFG0_den_wr_dat0_o <= 16'h0000;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_D_CFG0) begin
      RAM_D_CFG0_den_bank_sel_o <= wdata_i[3:0];
      RAM_D_CFG0_den_addr_o <= wdata_i[8:4];
      RAM_D_CFG0_den_wr_enable_o <= wdata_i[9];
      RAM_D_CFG0_den_wr_dat0_o <= wdata_i[31:16];
    end
  end
end

// RAM_D_CFG1 register block @ ADDR_RAM_D_CFG1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_D_CFG1_den_wr_dat1_o <= 32'h00000000;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_D_CFG1) begin
      RAM_D_CFG1_den_wr_dat1_o <= wdata_i[31:0];
    end
  end
end

// RAM_D_CSR register block @ ADDR_RAM_D_CSR
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_D_CSR_den_req_en_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_D_CSR) begin
      RAM_D_CSR_den_req_en_o <= wdata_i[0];
    end else if (RAM_D_CSR_den_req_en_o) begin
      RAM_D_CSR_den_req_en_o <= 'd0 ;
    end
  end
end

// RAM_D_DAT0 register block @ ADDR_RAM_D_DAT0
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     RAM_D_DAT0_den_rd_dat0_o <= 17'h00000;
//   end else begin
//     if (en_i && we_i && addr_i == ADDR_RAM_D_DAT0) begin
//       RAM_D_DAT0_den_rd_dat0_o <= wdata_i[16:0];
//     end
//   end
// end

// RAM_D_DAT1 register block @ ADDR_RAM_D_DAT1
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     RAM_D_DAT1_den_rd_dat1_o <= 32'h00000000;
//   end else begin
//     if (en_i && we_i && addr_i == ADDR_RAM_D_DAT1) begin
//       RAM_D_DAT1_den_rd_dat1_o <= wdata_i[31:0];
//     end
//   end
// end

// RAM_L_CFG register block @ ADDR_RAM_L_CFG
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     RAM_L_CFG_lkup_addr_o <= 7'h00;
//     RAM_L_CFG_lkup_wr_enable_o <= 1'h0;
//     RAM_L_CFG_lkup_wr_dat_o <= 13'h0000;
//   end else begin
//     if (en_i && we_i && addr_i == ADDR_RAM_L_CFG) begin
//       RAM_L_CFG_lkup_addr_o <= wdata_i[6:0];
//       RAM_L_CFG_lkup_wr_enable_o <= wdata_i[7];
//       RAM_L_CFG_lkup_wr_dat_o <= wdata_i[28:16];
//     end
//   end
// end

// // RAM_L_CSR register block @ ADDR_RAM_L_CSR
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     RAM_L_CSR_lkup_req_en_o <= 1'h0;
//   end else begin
//     if (en_i && we_i && addr_i == ADDR_RAM_L_CSR) begin
//       RAM_L_CSR_lkup_req_en_o <= wdata_i[0];
//     end else if (RAM_L_CSR_lkup_req_en_o) begin
//       RAM_L_CSR_lkup_req_en_o <= 'd0 ;
//     end
//   end
// end

// RAM_S_CFG0 register block @ ADDR_RAM_S_CFG0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_S_CFG0_spr_addr_o <= 8'h00;
    RAM_S_CFG0_spr_wr_enable_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_S_CFG0) begin
      RAM_S_CFG0_spr_addr_o <= wdata_i[7:0];
      RAM_S_CFG0_spr_wr_enable_o <= wdata_i[8];
    end
  end
end

// RAM_S_CFG1 register block @ ADDR_RAM_S_CFG1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_S_CFG1_spr_wr_dat1_o <= 32'h00000000;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_S_CFG1) begin
      RAM_S_CFG1_spr_wr_dat1_o <= wdata_i[31:0];
    end
  end
end

// RAM_S_CFG2 register block @ ADDR_RAM_S_CFG2
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_S_CFG2_spr_wr_dat2_o <= 32'h00000000;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_S_CFG2) begin
      RAM_S_CFG2_spr_wr_dat2_o <= wdata_i[31:0];
    end
  end
end

// RAM_S_CFG3 register block @ ADDR_RAM_S_CFG3
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_S_CFG3_spr_wr_dat3_o <= 32'h00000000;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_S_CFG3) begin
      RAM_S_CFG3_spr_wr_dat3_o <= wdata_i[31:0];
    end
  end
end

// RAM_S_CSR register block @ ADDR_RAM_S_CSR
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    RAM_S_CSR_spr_req_en_o <= 1'h0;
    RAM_S_CSR_spr_wr_dat0_o <= 2'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_RAM_S_CSR) begin
      RAM_S_CSR_spr_req_en_o <= wdata_i[0];
      RAM_S_CSR_spr_wr_dat0_o <= wdata_i[2:1];
    end else if (RAM_S_CSR_spr_req_en_o) begin
      RAM_S_CSR_spr_req_en_o <= 'd0 ;
    end
  end
end

// COR_CONF register block @ ADDR_COR_CONF
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    COR_CONF_res_neu_cnt_cfg_o <= 3'h5;
    COR_CONF_out_neu_cnt_cfg_o <= 1'h0;
    COR_CONF_res_syn_cnt_cfg_o <= 2'h3;
    COR_CONF_mem_thr_cfg_o <= 6'h10;
    COR_CONF_neu_tau_cfg_o <= 5'h0F;
    COR_CONF_spr_wgt_bin_cfg_o<= 1'b1;
  end else begin
    if (en_i && we_i && addr_i == ADDR_COR_CONF) begin
      COR_CONF_res_neu_cnt_cfg_o <= wdata_i[2:0];
      COR_CONF_out_neu_cnt_cfg_o <= wdata_i[3];
      COR_CONF_res_syn_cnt_cfg_o <= wdata_i[5:4];
      COR_CONF_mem_thr_cfg_o <= wdata_i[11:6];
      COR_CONF_neu_tau_cfg_o <= wdata_i[16:12];
      COR_CONF_spr_wgt_bin_cfg_o<= wdata_i[17];
    end
  end
end

// COR_CSR register block @ ADDR_COR_CSR
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    COR_CSR_test_halt_o <= 1'h0;
    COR_CSR_irq_en_o <= 1'h0;
    COR_CSR_core_start_o <= 1'b0 ;
  end else begin
    if (en_i && we_i && addr_i == ADDR_COR_CSR) begin
      COR_CSR_test_halt_o <= wdata_i[0];
      COR_CSR_irq_en_o <= wdata_i[1];
      COR_CSR_core_start_o <= wdata_i[5];
    end
  end
end

// CDC_CSR irq W1C logic

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    COR_CSR_result_out_irq_o <= 1'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_COR_CSR) begin
      COR_CSR_result_out_irq_o <= !(COR_CSR_result_out_irq_o &  wdata_i[6]);
    end
    else if (COR_CSR_result_out_irq_i)begin
      COR_CSR_result_out_irq_o <= 'd1 ;
    end
  end
end

// COR_TEST_CFG register block @ ADDR_COR_TEST_CFG
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    COR_TEST_CFG_halt_state_o <= 6'h00;
    COR_TEST_CFG_halt_pnt_cnt_o <= 11'h000;
    COR_TEST_CFG_halt_rnt_cnt_o <= 11'h000;
    COR_TEST_CFG_halt_tnt_cnt_o <= 4'h0;
  end else begin
    if (en_i && we_i && addr_i == ADDR_COR_TEST_CFG) begin
      COR_TEST_CFG_halt_state_o <= wdata_i[5:0];
      COR_TEST_CFG_halt_pnt_cnt_o <= wdata_i[16:6];
      COR_TEST_CFG_halt_rnt_cnt_o <= wdata_i[27:17];
      COR_TEST_CFG_halt_tnt_cnt_o <= wdata_i[31:28];
    end
  end
end

// Readback combinational mux (built as concatenations)
reg [31:0] rdata_comb;
always @* begin
  case (addr_i)
    ADDR_ANA_CONF: begin
      rdata_comb = {ANA_CONF_LDO1P875_IPP_CALIB_o[2:0], ANA_CONF_LDO1P25_IPP_CALIB_o[2:0], ANA_CONF_LDO_0P275_EN_o[0], ANA_CONF_LDO_0P55_EN_o[0], ANA_CONF_OFFSET_TRIMP_o[7:0], ANA_CONF_OFFSET_TRIMN_o[7:0], ANA_CONF_OP_EN_o[0], ANA_CONF_COMP_EN_o[0], ANA_CONF_CLK_EN_o[0], ANA_CONF_BG_ICC_RCALIB_o[3:0], ANA_CONF_BG_EN_o[0]};
    end
    ADDR_ANA_CSR: begin
      rdata_comb = {30'h0, ANA_CSR_rst_o[0], ANA_CSR_ANA_TEST_ONLY_o[0]};
    end
    ADDR_ANA_CONF2: begin
      rdata_comb = {ANA_CONF2_dummy_o[19:0], ANA_CONF2_LDO1P875_VREF_CALIB_o[5:0], ANA_CONF2_LDO1P25_VREF_CALIB_o[5:0]};
    end
    ADDR_CDC_CONF: begin
      rdata_comb = {7'h0, CDC_CONF_dat_grp_ful_o[8:0], CDC_CONF_dat_grp_num_o[7:0], CDC_CONF_dat_grp_len_o[7:0]};
    end
    ADDR_CDC_CSR: begin
      rdata_comb = {28'h0, CDC_CSR_cdc_test_only_o[0], CDC_CSR_dat_val_irq_o[0], CDC_CSR_dat_val_irq_en_o[0], CDC_CSR_an_val_o[0]};
    end
    ADDR_CDC_TEST: begin
      rdata_comb = {29'h0, CDC_TEST_lsm_done_ctl_o[0], CDC_TEST_lsm_step_ovr_o[0], CDC_TEST_lsm_start_ctl_o[0]};
    end
    ADDR_CDC_DATA_0: begin
      rdata_comb = {CDC_DATA_0_cdc_dat0_i[31:0]};
    end
    ADDR_CDC_DATA_1: begin
      rdata_comb = {CDC_DATA_1_cdc_dat1_i[31:0]};
    end
    ADDR_RAM_D_CFG0: begin
      rdata_comb = {RAM_D_CFG0_den_wr_dat0_o[15:0], 6'h0, RAM_D_CFG0_den_wr_enable_o[0], RAM_D_CFG0_den_addr_o[4:0], RAM_D_CFG0_den_bank_sel_o[3:0]};
    end
    ADDR_RAM_D_CFG1: begin
      rdata_comb = {RAM_D_CFG1_den_wr_dat1_o[31:0]};
    end
    ADDR_RAM_D_CSR: begin
      rdata_comb = {31'h0, RAM_D_CSR_den_req_en_o[0]};
    end
    ADDR_RAM_D_DAT0: begin
      rdata_comb = {16'h0, RAM_D_DAT0_den_rd_dat0_i[15:0]};
    end
    ADDR_RAM_D_DAT1: begin
      rdata_comb = {RAM_D_DAT1_den_rd_dat1_i[31:0]};
    end
    // ADDR_RAM_L_CFG: begin
    //   rdata_comb = {3'h0, RAM_L_CFG_lkup_wr_dat_o[12:0], 8'h0, RAM_L_CFG_lkup_wr_enable_o[0], RAM_L_CFG_lkup_addr_o[6:0]};
    // end
    // ADDR_RAM_L_CSR: begin
    //   rdata_comb = {31'h0, RAM_L_CSR_lkup_req_en_o[0]};
    // end
    // ADDR_RAM_L_DAT0: begin
    //   rdata_comb = {19'h0, RAM_L_DAT0_lkup_rd_dat_i[12:0]};
    // end
    ADDR_RAM_S_CFG0: begin
      rdata_comb = {23'h0, RAM_S_CFG0_spr_wr_enable_o[0], RAM_S_CFG0_spr_addr_o[7:0]};
    end
    ADDR_RAM_S_CFG1: begin
      rdata_comb = {RAM_S_CFG1_spr_wr_dat1_o[31:0]};
    end
    ADDR_RAM_S_CFG2: begin
      rdata_comb = {RAM_S_CFG2_spr_wr_dat2_o[31:0]};
    end
    ADDR_RAM_S_CFG3: begin
      rdata_comb = {RAM_S_CFG3_spr_wr_dat3_o[31:0]};
    end
    ADDR_RAM_S_CSR: begin
      rdata_comb = {27'h0, RAM_S_CSR_spr_rd_dat0_i[1:0],RAM_S_CSR_spr_wr_dat0_o[1:0],RAM_S_CSR_spr_req_en_o[0]};
    end
    ADDR_RAM_S_DAT0: begin
      rdata_comb = {RAM_S_DAT0_spr_rd_dat1_i[31:0]};
    end
    ADDR_RAM_S_DAT1: begin
      rdata_comb = {RAM_S_DAT1_spr_rd_dat2_i[31:0]};
    end
    ADDR_RAM_S_DAT2: begin
      rdata_comb = {RAM_S_DAT2_spr_rd_dat3_i[31:0]};
    end
    ADDR_COR_CONF: begin
      rdata_comb = {14'h0, COR_CONF_spr_wgt_bin_cfg_o,COR_CONF_neu_tau_cfg_o[4:0], COR_CONF_mem_thr_cfg_o[5:0], COR_CONF_res_syn_cnt_cfg_o[1:0], COR_CONF_out_neu_cnt_cfg_o[0], COR_CONF_res_neu_cnt_cfg_o[2:0]};
    end
    ADDR_COR_CSR: begin
      rdata_comb = {25'h0,COR_CSR_result_out_irq_o[0],COR_CSR_core_start_o[0], COR_CSR_result_out_i[2:0], COR_CSR_irq_en_o[0], COR_CSR_test_halt_o[0]};
    end
    ADDR_COR_TEST_CFG: begin
      rdata_comb = {COR_TEST_CFG_halt_tnt_cnt_o[3:0], COR_TEST_CFG_halt_rnt_cnt_o[10:0], COR_TEST_CFG_halt_pnt_cnt_o[0], COR_TEST_CFG_halt_state_o[5:0]};
    end
    ADDR_COR_CALC_CPT0: begin
      rdata_comb = {3'h0, COR_CALC_CPT0_CU2_sta_dat_i[8:0], 1'h0, COR_CALC_CPT0_CU1_sta_dat_i[8:0], 1'h0, COR_CALC_CPT0_CU0_sta_dat_i[8:0]};
    end
    ADDR_COR_CALC_CPT1: begin
      rdata_comb = {3'h0, COR_CALC_CPT1_CU5_sta_dat_i[8:0], 1'h0, COR_CALC_CPT1_CU4_sta_dat_i[8:0], 1'h0, COR_CALC_CPT1_CU3_sta_dat_i[8:0]};
    end
    ADDR_COR_CALC_CPT2: begin
      rdata_comb = {13'h0, COR_CALC_CPT2_CU7_sta_dat_i[8:0], 1'h0, COR_CALC_CPT2_CU6_sta_dat_i[8:0]};
    end
    default: rdata_comb = 32'h0;
  endcase
end

// Registered read output (1-cycle latency when en_i=1)
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rdata_o  <= 32'h0;
    rvalid_o <= 1'b0;
  end else begin
    if (en_i) begin
      rdata_o  <= rdata_comb;
      rvalid_o <= 1'b1;
    end else begin
      rvalid_o <= 1'b0;
    end
  end
end

endmodule
