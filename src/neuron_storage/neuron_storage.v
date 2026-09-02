//------------------------------------------------------------------------------
  //
  //  Filename       : neuron_storage.v
  //  Status         : draft
  //  Created        : 2025-06-09
  //  Description    : distribution neuron_storage for both weight and state
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module neuron_storage(
  // global
  clk                ,
  rstn               ,
  sta_clr_i          ,
  // neuron state
  neu_wr_addr_i      ,
  neu_wr_val_i       ,
  neu_wr_dat_i       ,
  neu_rd_addr_i      ,
  neu_rd_val_i       ,
  neu_rd_dat_o       ,
  // density weight
  den_bank_sel_i     ,
  den_addr_i         ,
  den_wr_val_i       ,
  den_wr_dat_i       ,
  den_rd_val_i       ,
  den_rd_dat_o       ,
  // sparisty weight
//   spr_lkup_addr_i    ,
//   spr_lkup_wr_val_i  ,
//   spr_lkup_wr_dat_i  ,
//   spr_lkup_rd_val_i  ,
//   spr_lkup_rd_dat_o  ,

  spr_wgt_addr_i     ,
  spr_wgt_wr_val_i   ,
  spr_wgt_wr_dat_i   ,
  spr_wgt_rd_val_i   ,
  spr_wgt_rd_dat_o

);
//*** PARAMETER ****************************************************************
  // global
  parameter    WGT_WIDTH                =  'd6                     ;
  // CU number
  parameter    CU_NUM                   =  'd4                     ;
  localparam   CU_WD                    = `FUNC_LOG2( CU_NUM )     ;
  // neuron state
  parameter    NEU_WIDTH                =  'd9                     ;
  parameter    NEU_SIZE                 =  'd64                    ;
  localparam   NEU_SIZE_WD              =  `FUNC_LOG2( NEU_SIZE )  ;
  localparam   NEU_ADR_WD               =  NEU_SIZE_WD * CU_NUM    ;
  localparam   NEU_DAT_WD               =  NEU_WIDTH   * CU_NUM    ;

  // density weight (input layer weight)
  parameter    DEN_SIZE                 =  'd256 /  CU_NUM         ;
  localparam   DEN_WIDTH_DTB            =  WGT_WIDTH * CU_NUM      ;
  localparam   DEN_BANK_NUM             =  'd16                    ;
  localparam   DEN_BANK_WD              =  `FUNC_LOG2(DEN_BANK_NUM);
  localparam   DEN_SIZE_WD              =  `FUNC_LOG2( DEN_SIZE )  ;
  localparam   DEN_RD_WD                =  DEN_WIDTH_DTB * DEN_BANK_NUM ;
 // sparisty weight
//   parameter    LOOKUP_SIZE              =  'd128                   ;
//   parameter    LOOKUP_WIDTH             =  'd16 - CU_WD            ;  //msb 8bit for synapse# num
//   localparam   LOOKUP_SIZE_WD           =  `FUNC_LOG2(LOOKUP_SIZE) ;
  parameter    WGT_STR_SIZE             =  'd2048 /  CU_NUM        ; // 512/636 = 80% sparsity weight can be storage
  localparam   WGT_STR_WIDTH            =  'd12 * CU_NUM  + 'd2    ; //    6*CU_NUM                  , 2 is flag bit
  localparam   WGT_STR_SIZE_WD          =  `FUNC_LOG2(WGT_STR_SIZE);
//*** INPUT/OUTPUT *************************************************************
  // global
  input                               clk              ;
  input                               rstn             ;
  input                               sta_clr_i        ;
  // neuron state
  input      [NEU_ADR_WD -1    :0]    neu_wr_addr_i    ;
  input      [NEU_DAT_WD -1    :0]    neu_wr_dat_i     ;
  input                               neu_wr_val_i     ;
  input      [NEU_ADR_WD -1    :0]    neu_rd_addr_i    ;
  output     [NEU_DAT_WD -1    :0]    neu_rd_dat_o     ;
  input                               neu_rd_val_i     ;
  // density calc
  input      [DEN_BANK_WD-1    :0]    den_bank_sel_i   ;
  input      [DEN_SIZE_WD-1    :0]    den_addr_i       ;
  input                               den_wr_val_i     ;
  input      [DEN_WIDTH_DTB-1  :0]    den_wr_dat_i     ;
  input                               den_rd_val_i     ;
  output     [DEN_RD_WD-1      :0]    den_rd_dat_o     ;
  // sparsity calc   
//   input      [LOOKUP_SIZE_WD-1 :0]    spr_lkup_addr_i  ;
//   input                               spr_lkup_wr_val_i;
//   input      [LOOKUP_WIDTH-1   :0]    spr_lkup_wr_dat_i;
//   input                               spr_lkup_rd_val_i;
//   output     [LOOKUP_WIDTH-1   :0]    spr_lkup_rd_dat_o;

  input      [WGT_STR_SIZE_WD-1:0]    spr_wgt_addr_i   ;
  input                               spr_wgt_wr_val_i ;
  input      [WGT_STR_WIDTH-1  :0]    spr_wgt_wr_dat_i ;
  input                               spr_wgt_rd_val_i ;
  output     [WGT_STR_WIDTH-1  :0]    spr_wgt_rd_dat_o ;


//*** WIRE/REG *****************************************************************
  // neuron state ram  
  reg  [NEU_WIDTH-1    :0] neuron_state      [NEU_SIZE-1    :0];
  reg  [NEU_WIDTH-1    :0] neuron_cache      [CU_NUM  -2    :0];
  wire [NEU_SIZE_WD-1  :0] cu_addr           [0      :CU_NUM-1];
  wire [NEU_WIDTH  -1  :0] cu_data           [0      :CU_NUM-1];
  // density ram
  wire [DEN_BANK_NUM-1 :0] wr_en_i_per_bank                    ;
  wire [DEN_BANK_NUM-1 :0] rd_val_i_per_bank                   ;
  wire [DEN_WIDTH_DTB-1:0] rd_dat_o_per_bank [0:DEN_BANK_NUM-1];

//*** MAIN BODY ****************************************************************
  //====== neuron state ram 64*9 bits SP RAM 0.07KB
  //`ifdef ASIC
    // TODO should generate ram block or register based
  //`else
    genvar cu_idx;
    generate
      for (cu_idx = 0; cu_idx < CU_NUM; cu_idx = cu_idx + 1) begin : gen_rd
        wire [NEU_SIZE_WD-1:0] addr_per_cu ;
        assign addr_per_cu = neu_rd_addr_i[(cu_idx + 1)*NEU_SIZE_WD - 1 
                                          : cu_idx     *NEU_SIZE_WD     ];
        assign neu_rd_dat_o[(cu_idx + 1) * NEU_WIDTH - 1 
                           : cu_idx      * NEU_WIDTH    ] = neu_rd_val_i ? neuron_state[addr_per_cu]
                                                                         : 'd0                      ;
      end
    endgenerate

    genvar k;
    generate
      for (k = 0; k < CU_NUM; k = k + 1) begin : gen_cu
        assign cu_addr[k] = neu_wr_addr_i[(k + 1)*NEU_SIZE_WD - 1 : k*NEU_SIZE_WD];
        assign cu_data[k] = neu_wr_dat_i [(k + 1)*NEU_WIDTH   - 1 : k*NEU_WIDTH  ];
      end
    endgenerate

    integer i;
    always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
        for (i = 0; i < NEU_SIZE; i = i + 1) begin
          neuron_state[i] <= 'd0;
        end
      end else if (sta_clr_i)begin
       for (i = 0; i < NEU_SIZE; i = i + 1) begin
          neuron_state[i] <= 'd0;
        end
      end else if (neu_wr_val_i) begin
        for (i = 0; i < CU_NUM; i = i + 1) begin
          neuron_state[cu_addr[i]] <= cu_data[i];
        end
      end
    end
  //`endif
  //===== density weight (input layer weight) 64*24 *16 bank =  192 Bytes * 16 bank = 3KB

  genvar j;  
  generate
    for (j= 0; j< DEN_BANK_NUM; j = j + 1) begin : u_sram_bank
      
      assign wr_en_i_per_bank[j]  = den_wr_val_i && (den_bank_sel_i == j);
      assign rd_val_i_per_bank[j] = den_rd_val_i                         ;
      `ifdef ASIC_UMC
      // TODO should generate ram block or register based
        wire den_wgt_ce   ;
        wire den_wgt_we   ;
        wire den_wgt_clk  ;

        ICG_cell u_icg_den_wgt (
          .clk                  ( clk                 ),
          .en                   ( den_wgt_ce          ),
          .clk_gated            ( den_wgt_clk         )
        );

        assign  den_wgt_ce =  wr_en_i_per_bank[j] | rd_val_i_per_bank[j] ;
        assign  den_wgt_we =  wr_en_i_per_bank[j] ; 
        if (CU_NUM == 4) begin
            // empty
        end else if (CU_NUM == 8)begin:genblk1
          `ifdef UMC28
            // empty
          `elsif UMC40
            // UMC40 density weight RF, 48b data, 5b addr
            den_wgt_rf_8_umc40 u_density_weight (
              // ---- Address (A0 is LSB) ----
              .A0 (den_addr_i[0]),
              .A1 (den_addr_i[1]),
              .A2 (den_addr_i[2]),
              .A3 (den_addr_i[3]),
              .A4 (den_addr_i[4]),
              // ---- Data outputs (SRAM -> core) ----
              .DO0 (rd_dat_o_per_bank[j][0]),
              .DO1 (rd_dat_o_per_bank[j][1]),
              .DO2 (rd_dat_o_per_bank[j][2]),
              .DO3 (rd_dat_o_per_bank[j][3]),
              .DO4 (rd_dat_o_per_bank[j][4]),
              .DO5 (rd_dat_o_per_bank[j][5]),
              .DO6 (rd_dat_o_per_bank[j][6]),
              .DO7 (rd_dat_o_per_bank[j][7]),
              .DO8 (rd_dat_o_per_bank[j][8]),
              .DO9 (rd_dat_o_per_bank[j][9]),
              .DO10(rd_dat_o_per_bank[j][10]),
              .DO11(rd_dat_o_per_bank[j][11]),
              .DO12(rd_dat_o_per_bank[j][12]),
              .DO13(rd_dat_o_per_bank[j][13]),
              .DO14(rd_dat_o_per_bank[j][14]),
              .DO15(rd_dat_o_per_bank[j][15]),
              .DO16(rd_dat_o_per_bank[j][16]),
              .DO17(rd_dat_o_per_bank[j][17]),
              .DO18(rd_dat_o_per_bank[j][18]),
              .DO19(rd_dat_o_per_bank[j][19]),
              .DO20(rd_dat_o_per_bank[j][20]),
              .DO21(rd_dat_o_per_bank[j][21]),
              .DO22(rd_dat_o_per_bank[j][22]),
              .DO23(rd_dat_o_per_bank[j][23]),
              .DO24(rd_dat_o_per_bank[j][24]),
              .DO25(rd_dat_o_per_bank[j][25]),
              .DO26(rd_dat_o_per_bank[j][26]),
              .DO27(rd_dat_o_per_bank[j][27]),
              .DO28(rd_dat_o_per_bank[j][28]),
              .DO29(rd_dat_o_per_bank[j][29]),
              .DO30(rd_dat_o_per_bank[j][30]),
              .DO31(rd_dat_o_per_bank[j][31]),
              .DO32(rd_dat_o_per_bank[j][32]),
              .DO33(rd_dat_o_per_bank[j][33]),
              .DO34(rd_dat_o_per_bank[j][34]),
              .DO35(rd_dat_o_per_bank[j][35]),
              .DO36(rd_dat_o_per_bank[j][36]),
              .DO37(rd_dat_o_per_bank[j][37]),
              .DO38(rd_dat_o_per_bank[j][38]),
              .DO39(rd_dat_o_per_bank[j][39]),
              .DO40(rd_dat_o_per_bank[j][40]),
              .DO41(rd_dat_o_per_bank[j][41]),
              .DO42(rd_dat_o_per_bank[j][42]),
              .DO43(rd_dat_o_per_bank[j][43]),
              .DO44(rd_dat_o_per_bank[j][44]),
              .DO45(rd_dat_o_per_bank[j][45]),
              .DO46(rd_dat_o_per_bank[j][46]),
              .DO47(rd_dat_o_per_bank[j][47]),
              // ---- Data inputs (core -> SRAM) ----
              .DI0 (den_wr_dat_i[0]),
              .DI1 (den_wr_dat_i[1]),
              .DI2 (den_wr_dat_i[2]),
              .DI3 (den_wr_dat_i[3]),
              .DI4 (den_wr_dat_i[4]),
              .DI5 (den_wr_dat_i[5]),
              .DI6 (den_wr_dat_i[6]),
              .DI7 (den_wr_dat_i[7]),
              .DI8 (den_wr_dat_i[8]),
              .DI9 (den_wr_dat_i[9]),
              .DI10(den_wr_dat_i[10]),
              .DI11(den_wr_dat_i[11]),
              .DI12(den_wr_dat_i[12]),
              .DI13(den_wr_dat_i[13]),
              .DI14(den_wr_dat_i[14]),
              .DI15(den_wr_dat_i[15]),
              .DI16(den_wr_dat_i[16]),
              .DI17(den_wr_dat_i[17]),
              .DI18(den_wr_dat_i[18]),
              .DI19(den_wr_dat_i[19]),
              .DI20(den_wr_dat_i[20]),
              .DI21(den_wr_dat_i[21]),
              .DI22(den_wr_dat_i[22]),
              .DI23(den_wr_dat_i[23]),
              .DI24(den_wr_dat_i[24]),
              .DI25(den_wr_dat_i[25]),
              .DI26(den_wr_dat_i[26]),
              .DI27(den_wr_dat_i[27]),
              .DI28(den_wr_dat_i[28]),
              .DI29(den_wr_dat_i[29]),
              .DI30(den_wr_dat_i[30]),
              .DI31(den_wr_dat_i[31]),
              .DI32(den_wr_dat_i[32]),
              .DI33(den_wr_dat_i[33]),
              .DI34(den_wr_dat_i[34]),
              .DI35(den_wr_dat_i[35]),
              .DI36(den_wr_dat_i[36]),
              .DI37(den_wr_dat_i[37]),
              .DI38(den_wr_dat_i[38]),
              .DI39(den_wr_dat_i[39]),
              .DI40(den_wr_dat_i[40]),
              .DI41(den_wr_dat_i[41]),
              .DI42(den_wr_dat_i[42]),
              .DI43(den_wr_dat_i[43]),
              .DI44(den_wr_dat_i[44]),
              .DI45(den_wr_dat_i[45]),
              .DI46(den_wr_dat_i[46]),
              .DI47(den_wr_dat_i[47]),
              // ---- Clk / control ----
              .CK   (den_wgt_clk),
              .NAP  (1'b0),
              .WEB  (~den_wgt_we),
              .DVSE (1'b0),
              .DVS0 (1'b0),
              .DVS1 (1'b0),
              .DVS2 (1'b0),
              .DVS3 (1'b0),
              .CSB  (~den_wgt_ce)
            );
          `endif
          end
        `else
          wire den_wgt_clk  ;
          wire den_wgt_ce   ;
  
          assign den_wgt_ce = wr_en_i_per_bank[j] | rd_val_i_per_bank[j] ;

          ICG_cell u_icg_den_wgt (
            .clk             ( clk                ),
            .en              ( den_wgt_ce         ),
            .clk_gated       ( den_wgt_clk        )
          );

          sram_sp_behave #(
            .SIZE            (DEN_SIZE            ),
            .DATA_WD         (DEN_WIDTH_DTB       )
          ) u_density_weight (
            .clk             (den_wgt_clk         ),
            .adr_i           (den_addr_i          ),
            .wr_val_i        (wr_en_i_per_bank[j] ),
            .wr_dat_i        (den_wr_dat_i        ),
            .rd_val_i        (rd_val_i_per_bank[j]),
            .rd_dat_o        (rd_dat_o_per_bank[j])
          );
        `endif
      end
  endgenerate
  // regroup the dat read port
  genvar bank_idx ; 
  genvar cu_idx2  ;
  generate
    for (bank_idx = 0; bank_idx < DEN_BANK_NUM; bank_idx = bank_idx + 1) begin : per_bank
      for (cu_idx2 = 0; cu_idx2 < CU_NUM; cu_idx2 = cu_idx2 + 1) begin : per_cu
        assign den_rd_dat_o[
            ((DEN_BANK_NUM - 1 - bank_idx) * CU_NUM + cu_idx2) * WGT_WIDTH +: WGT_WIDTH
                           ] = rd_dat_o_per_bank[bank_idx][cu_idx2 * WGT_WIDTH +: WGT_WIDTH];
  
      end
    end
  endgenerate

  //===== sparsity weight (2 banks. 1 for lookup. 1 for weight storage)
  `ifdef ASIC_UMC
      // TODO should generate ram block or register based
        wire spr_wgt_clk      ;
        wire spr_wgt_ce       ;
        wire spr_wgt_we       ;

        // sparsity weight
        assign  spr_wgt_ce  =  spr_wgt_wr_val_i | spr_wgt_rd_val_i    ;
        assign  spr_wgt_we  =  spr_wgt_wr_val_i             ; 

        ICG_cell u_icg_spr_wgt (
          .clk             ( clk                ),
          .en              ( spr_wgt_ce         ),
          .clk_gated       ( spr_wgt_clk        )
        );

        generate
        if (CU_NUM == 4) begin
          // sparsity weight
        end else if (CU_NUM==8)begin:genblk5
        wire dummy;
        `ifdef UMC28
            // sparsity weight
        `elsif UMC40
            spr_wgt_rf_8_umc40 u_sparsity_weight (
              // ---- Address ----
              .A0 (spr_wgt_addr_i[0]),
              .A1 (spr_wgt_addr_i[1]),
              .A2 (spr_wgt_addr_i[2]),
              .A3 (spr_wgt_addr_i[3]),
              .A4 (spr_wgt_addr_i[4]),
              .A5 (spr_wgt_addr_i[5]),
              .A6 (spr_wgt_addr_i[6]),
              .A7 (spr_wgt_addr_i[7]),
            
              // ---- Data Outputs (SRAM -> Core), 96b ----
              .DO0 (spr_wgt_rd_dat_o[0]),
              .DO1 (spr_wgt_rd_dat_o[1]),
              .DO2 (spr_wgt_rd_dat_o[2]),
              .DO3 (spr_wgt_rd_dat_o[3]),
              .DO4 (spr_wgt_rd_dat_o[4]),
              .DO5 (spr_wgt_rd_dat_o[5]),
              .DO6 (spr_wgt_rd_dat_o[6]),
              .DO7 (spr_wgt_rd_dat_o[7]),
              .DO8 (spr_wgt_rd_dat_o[8]),
              .DO9 (spr_wgt_rd_dat_o[9]),
              .DO10(spr_wgt_rd_dat_o[10]),
              .DO11(spr_wgt_rd_dat_o[11]),
              .DO12(spr_wgt_rd_dat_o[12]),
              .DO13(spr_wgt_rd_dat_o[13]),
              .DO14(spr_wgt_rd_dat_o[14]),
              .DO15(spr_wgt_rd_dat_o[15]),
              .DO16(spr_wgt_rd_dat_o[16]),
              .DO17(spr_wgt_rd_dat_o[17]),
              .DO18(spr_wgt_rd_dat_o[18]),
              .DO19(spr_wgt_rd_dat_o[19]),
              .DO20(spr_wgt_rd_dat_o[20]),
              .DO21(spr_wgt_rd_dat_o[21]),
              .DO22(spr_wgt_rd_dat_o[22]),
              .DO23(spr_wgt_rd_dat_o[23]),
              .DO24(spr_wgt_rd_dat_o[24]),
              .DO25(spr_wgt_rd_dat_o[25]),
              .DO26(spr_wgt_rd_dat_o[26]),
              .DO27(spr_wgt_rd_dat_o[27]),
              .DO28(spr_wgt_rd_dat_o[28]),
              .DO29(spr_wgt_rd_dat_o[29]),
              .DO30(spr_wgt_rd_dat_o[30]),
              .DO31(spr_wgt_rd_dat_o[31]),
              .DO32(spr_wgt_rd_dat_o[32]),
              .DO33(spr_wgt_rd_dat_o[33]),
              .DO34(spr_wgt_rd_dat_o[34]),
              .DO35(spr_wgt_rd_dat_o[35]),
              .DO36(spr_wgt_rd_dat_o[36]),
              .DO37(spr_wgt_rd_dat_o[37]),
              .DO38(spr_wgt_rd_dat_o[38]),
              .DO39(spr_wgt_rd_dat_o[39]),
              .DO40(spr_wgt_rd_dat_o[40]),
              .DO41(spr_wgt_rd_dat_o[41]),
              .DO42(spr_wgt_rd_dat_o[42]),
              .DO43(spr_wgt_rd_dat_o[43]),
              .DO44(spr_wgt_rd_dat_o[44]),
              .DO45(spr_wgt_rd_dat_o[45]),
              .DO46(spr_wgt_rd_dat_o[46]),
              .DO47(spr_wgt_rd_dat_o[47]),
              .DO48(spr_wgt_rd_dat_o[48]),
              .DO49(spr_wgt_rd_dat_o[49]),
              .DO50(spr_wgt_rd_dat_o[50]),
              .DO51(spr_wgt_rd_dat_o[51]),
              .DO52(spr_wgt_rd_dat_o[52]),
              .DO53(spr_wgt_rd_dat_o[53]),
              .DO54(spr_wgt_rd_dat_o[54]),
              .DO55(spr_wgt_rd_dat_o[55]),
              .DO56(spr_wgt_rd_dat_o[56]),
              .DO57(spr_wgt_rd_dat_o[57]),
              .DO58(spr_wgt_rd_dat_o[58]),
              .DO59(spr_wgt_rd_dat_o[59]),
              .DO60(spr_wgt_rd_dat_o[60]),
              .DO61(spr_wgt_rd_dat_o[61]),
              .DO62(spr_wgt_rd_dat_o[62]),
              .DO63(spr_wgt_rd_dat_o[63]),
              .DO64(spr_wgt_rd_dat_o[64]),
              .DO65(spr_wgt_rd_dat_o[65]),
              .DO66(spr_wgt_rd_dat_o[66]),
              .DO67(spr_wgt_rd_dat_o[67]),
              .DO68(spr_wgt_rd_dat_o[68]),
              .DO69(spr_wgt_rd_dat_o[69]),
              .DO70(spr_wgt_rd_dat_o[70]),
              .DO71(spr_wgt_rd_dat_o[71]),
              .DO72(spr_wgt_rd_dat_o[72]),
              .DO73(spr_wgt_rd_dat_o[73]),
              .DO74(spr_wgt_rd_dat_o[74]),
              .DO75(spr_wgt_rd_dat_o[75]),
              .DO76(spr_wgt_rd_dat_o[76]),
              .DO77(spr_wgt_rd_dat_o[77]),
              .DO78(spr_wgt_rd_dat_o[78]),
              .DO79(spr_wgt_rd_dat_o[79]),
              .DO80(spr_wgt_rd_dat_o[80]),
              .DO81(spr_wgt_rd_dat_o[81]),
              .DO82(spr_wgt_rd_dat_o[82]),
              .DO83(spr_wgt_rd_dat_o[83]),
              .DO84(spr_wgt_rd_dat_o[84]),
              .DO85(spr_wgt_rd_dat_o[85]),
              .DO86(spr_wgt_rd_dat_o[86]),
              .DO87(spr_wgt_rd_dat_o[87]),
              .DO88(spr_wgt_rd_dat_o[88]),
              .DO89(spr_wgt_rd_dat_o[89]),
              .DO90(spr_wgt_rd_dat_o[90]),
              .DO91(spr_wgt_rd_dat_o[91]),
              .DO92(spr_wgt_rd_dat_o[92]),
              .DO93(spr_wgt_rd_dat_o[93]),
              .DO94(spr_wgt_rd_dat_o[94]),
              .DO95(spr_wgt_rd_dat_o[95]),
              .DO96(spr_wgt_rd_dat_o[96]),
              .DO97(spr_wgt_rd_dat_o[97]),           
              // ---- Data Inputs (Core -> SRAM), 96b ----
              .DI0 (spr_wgt_wr_dat_i[0]),
              .DI1 (spr_wgt_wr_dat_i[1]),
              .DI2 (spr_wgt_wr_dat_i[2]),
              .DI3 (spr_wgt_wr_dat_i[3]),
              .DI4 (spr_wgt_wr_dat_i[4]),
              .DI5 (spr_wgt_wr_dat_i[5]),
              .DI6 (spr_wgt_wr_dat_i[6]),
              .DI7 (spr_wgt_wr_dat_i[7]),
              .DI8 (spr_wgt_wr_dat_i[8]),
              .DI9 (spr_wgt_wr_dat_i[9]),
              .DI10(spr_wgt_wr_dat_i[10]),
              .DI11(spr_wgt_wr_dat_i[11]),
              .DI12(spr_wgt_wr_dat_i[12]),
              .DI13(spr_wgt_wr_dat_i[13]),
              .DI14(spr_wgt_wr_dat_i[14]),
              .DI15(spr_wgt_wr_dat_i[15]),
              .DI16(spr_wgt_wr_dat_i[16]),
              .DI17(spr_wgt_wr_dat_i[17]),
              .DI18(spr_wgt_wr_dat_i[18]),
              .DI19(spr_wgt_wr_dat_i[19]),
              .DI20(spr_wgt_wr_dat_i[20]),
              .DI21(spr_wgt_wr_dat_i[21]),
              .DI22(spr_wgt_wr_dat_i[22]),
              .DI23(spr_wgt_wr_dat_i[23]),
              .DI24(spr_wgt_wr_dat_i[24]),
              .DI25(spr_wgt_wr_dat_i[25]),
              .DI26(spr_wgt_wr_dat_i[26]),
              .DI27(spr_wgt_wr_dat_i[27]),
              .DI28(spr_wgt_wr_dat_i[28]),
              .DI29(spr_wgt_wr_dat_i[29]),
              .DI30(spr_wgt_wr_dat_i[30]),
              .DI31(spr_wgt_wr_dat_i[31]),
              .DI32(spr_wgt_wr_dat_i[32]),
              .DI33(spr_wgt_wr_dat_i[33]),
              .DI34(spr_wgt_wr_dat_i[34]),
              .DI35(spr_wgt_wr_dat_i[35]),
              .DI36(spr_wgt_wr_dat_i[36]),
              .DI37(spr_wgt_wr_dat_i[37]),
              .DI38(spr_wgt_wr_dat_i[38]),
              .DI39(spr_wgt_wr_dat_i[39]),
              .DI40(spr_wgt_wr_dat_i[40]),
              .DI41(spr_wgt_wr_dat_i[41]),
              .DI42(spr_wgt_wr_dat_i[42]),
              .DI43(spr_wgt_wr_dat_i[43]),
              .DI44(spr_wgt_wr_dat_i[44]),
              .DI45(spr_wgt_wr_dat_i[45]),
              .DI46(spr_wgt_wr_dat_i[46]),
              .DI47(spr_wgt_wr_dat_i[47]),
              .DI48(spr_wgt_wr_dat_i[48]),
              .DI49(spr_wgt_wr_dat_i[49]),
              .DI50(spr_wgt_wr_dat_i[50]),
              .DI51(spr_wgt_wr_dat_i[51]),
              .DI52(spr_wgt_wr_dat_i[52]),
              .DI53(spr_wgt_wr_dat_i[53]),
              .DI54(spr_wgt_wr_dat_i[54]),
              .DI55(spr_wgt_wr_dat_i[55]),
              .DI56(spr_wgt_wr_dat_i[56]),
              .DI57(spr_wgt_wr_dat_i[57]),
              .DI58(spr_wgt_wr_dat_i[58]),
              .DI59(spr_wgt_wr_dat_i[59]),
              .DI60(spr_wgt_wr_dat_i[60]),
              .DI61(spr_wgt_wr_dat_i[61]),
              .DI62(spr_wgt_wr_dat_i[62]),
              .DI63(spr_wgt_wr_dat_i[63]),
              .DI64(spr_wgt_wr_dat_i[64]),
              .DI65(spr_wgt_wr_dat_i[65]),
              .DI66(spr_wgt_wr_dat_i[66]),
              .DI67(spr_wgt_wr_dat_i[67]),
              .DI68(spr_wgt_wr_dat_i[68]),
              .DI69(spr_wgt_wr_dat_i[69]),
              .DI70(spr_wgt_wr_dat_i[70]),
              .DI71(spr_wgt_wr_dat_i[71]),
              .DI72(spr_wgt_wr_dat_i[72]),
              .DI73(spr_wgt_wr_dat_i[73]),
              .DI74(spr_wgt_wr_dat_i[74]),
              .DI75(spr_wgt_wr_dat_i[75]),
              .DI76(spr_wgt_wr_dat_i[76]),
              .DI77(spr_wgt_wr_dat_i[77]),
              .DI78(spr_wgt_wr_dat_i[78]),
              .DI79(spr_wgt_wr_dat_i[79]),
              .DI80(spr_wgt_wr_dat_i[80]),
              .DI81(spr_wgt_wr_dat_i[81]),
              .DI82(spr_wgt_wr_dat_i[82]),
              .DI83(spr_wgt_wr_dat_i[83]),
              .DI84(spr_wgt_wr_dat_i[84]),
              .DI85(spr_wgt_wr_dat_i[85]),
              .DI86(spr_wgt_wr_dat_i[86]),
              .DI87(spr_wgt_wr_dat_i[87]),
              .DI88(spr_wgt_wr_dat_i[88]),
              .DI89(spr_wgt_wr_dat_i[89]),
              .DI90(spr_wgt_wr_dat_i[90]),
              .DI91(spr_wgt_wr_dat_i[91]),
              .DI92(spr_wgt_wr_dat_i[92]),
              .DI93(spr_wgt_wr_dat_i[93]),
              .DI94(spr_wgt_wr_dat_i[94]),
              .DI95(spr_wgt_wr_dat_i[95]),
              .DI96(spr_wgt_wr_dat_i[96]),
              .DI97(spr_wgt_wr_dat_i[97]),                 
              // ---- Clk / En ----
              .CK   (spr_wgt_clk),
              .NAP  (1'b0),
              .WEB  (~spr_wgt_we),
              .DVSE (1'b0),
              .DVS0 (1'b0),
              .DVS1 (1'b0),
              .DVS2 (1'b0),
              .DVS3 (1'b0),
              .CSB  (~spr_wgt_ce)
            );
        `endif
        end
        endgenerate
  `else

    wire spr_wgt_clk  ;
    wire spr_wgt_ce   ;

    assign spr_wgt_ce = spr_wgt_wr_val_i  | spr_wgt_rd_val_i  ;

    ICG_cell u_icg_spr_wgt (
      .clk             ( clk               ),
      .en              ( spr_wgt_ce        ),
      .clk_gated       ( spr_wgt_clk       )
    );  
      // sparsity weight sram 512*48 = 3KB
        sram_sp_behave #(
        .SIZE            (WGT_STR_SIZE        ),
        .DATA_WD         (WGT_STR_WIDTH       )
      ) u_sparsity_weight (
        .clk             ( spr_wgt_clk        ),
        .adr_i           ( spr_wgt_addr_i     ),
        .wr_val_i        ( spr_wgt_wr_val_i   ),
        .wr_dat_i        ( spr_wgt_wr_dat_i   ),
        .rd_val_i        ( spr_wgt_rd_val_i   ),
        .rd_dat_o        ( spr_wgt_rd_dat_o   )
      );
  `endif

endmodule
