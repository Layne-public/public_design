//------------------------------------------------------------------------------
  //
  //  Filename       : result_storage.v
  //  Status         : draft
  //  Created        : 2025-06-11
  //  Description    : two simple registers and a leading 1 detection module
  //                 
//------------------------------------------------------------------------------
`include "defines.vh"

module result_storage(
  // global
  clk             ,
  rstn            ,
  // res spk register
  res_neu_cfg	  ,
  res_spk_i       , //!! 注意输入的顺序要颠倒
  res_spk_val_i   ,
  spk_buf_clr_i   ,
  res_spk_lod_o   ,

  res_calc_val    ,
  res_fetch_lo_val,

  // out spk register
  out_spk_i       ,
  out_spk_val_i   ,

  out_calc_val    , // 输入累加  
  comp_val_i      , // 开始比较输出结果
  result_o        ,
  result_val_o   

);
//*** PARAMETER ****************************************************************
  // CU number
  parameter    CU_NUM              =  'd4      ;
  localparam   CU_WD               = `FUNC_LOG2( CU_NUM )     ;
  // RES
  localparam   RES_NEU_CYCLE       =  'd6 - CU_WD;
  parameter    RES_SPK_SIZE        =  'd64     ;
  parameter    OUT_SPK_SIZE        =  'd8      ;
  localparam   OUT_SPK_SIZE_B      =  'd9      ;

  localparam   OUT_SPK_SIZE_WD     = `FUNC_LOG2( OUT_SPK_SIZE )  ;
  parameter    TIM_STP_WIDTH       =  'd5      ;

  localparam   LEAD_NUM_WD         = `FUNC_LOG2( RES_SPK_SIZE )  ;
//*** INPUT/OUTPUT *************************************************************
  // DIGITAL
  input                             clk              ;
  input                             rstn             ;

  input      [RES_NEU_CYCLE -1:0]  res_neu_cfg       ;
  input      [CU_NUM        -1:0]  res_spk_i         ;
  input                            res_spk_val_i     ;
  input                            spk_buf_clr_i     ;
  output     [LEAD_NUM_WD     :0]  res_spk_lod_o     ;

  input                            res_calc_val      ;
  input                            res_fetch_lo_val  ;

  input      [CU_NUM        -1:0]  out_spk_i         ;
  input                            out_spk_val_i     ;


  
  input                            out_calc_val      ;
  input                            comp_val_i        ; 

  output reg [OUT_SPK_SIZE_WD-1:0] result_o          ;
  output reg                       result_val_o      ;


//*** WIRE/REG *****************************************************************
  reg       [RES_SPK_SIZE-1    :0] res_spk_buf_bkup    ;  // for store one time step
  reg       [RES_SPK_SIZE-1    :0] res_spk_buf_calc    ;  // for calcu
  //wire      [RES_SPK_SIZE-1    :0] res_spk_lod_i       ;  

  reg       [OUT_SPK_SIZE_B-1  :0] out_spk_buf         ;
  reg       [TIM_STP_WIDTH-1   :0] out_acc [OUT_SPK_SIZE-1:0] ;
  reg       [OUT_SPK_SIZE_WD-1 :0] cnt       	       ;
  reg       [TIM_STP_WIDTH -1  :0] max_value 	       ;
  wire      [RES_NEU_CYCLE +1  :0] res_neu_cfg_ext     ;
//*** MAIN BODY ****************************************************************
 
// spk result save register
  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      res_spk_buf_bkup <= 'd0 ;
    end
    else begin
      if( res_spk_val_i )begin
        res_spk_buf_bkup <= {res_spk_buf_bkup[RES_SPK_SIZE-1-CU_NUM:0],res_spk_i} ;
      end
      else if (spk_buf_clr_i | result_val_o) begin  // todo 一次计算完就清零一次
        res_spk_buf_bkup <= 'd0 ;
      end
    end
  end

//  assign res_spk_lod_i = res_spk_buf_calc  << (~res_neu_cfg) << 2 ;
  wire  [RES_NEU_CYCLE +2:0]  res_neu_sft ;
  assign res_neu_sft     = (~res_neu_cfg) << CU_WD ;
  assign res_neu_cfg_ext = res_neu_sft[RES_NEU_CYCLE +1  :0];
// spk result save register
  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      res_spk_buf_calc <= 'd0 ;
    end
    else begin
      if( res_calc_val )begin
        res_spk_buf_calc <= res_spk_val_i ? {res_spk_buf_bkup[RES_SPK_SIZE-1-CU_NUM:0],res_spk_i} << res_neu_cfg_ext
					  :  res_spk_buf_bkup << res_neu_cfg_ext;
      end
      else if (res_fetch_lo_val) begin
        res_spk_buf_calc[~res_spk_lod_o [LEAD_NUM_WD-1 :0]] <= 1'd0 ;
      end
    end
  end
// Portable MSB-first leading-one detector.  An all-ones encoded result marks
// an empty spike vector, matching the sentinel expected by lsm_ctl.
  leading_one_detector #(
    .WIDTH                 ( RES_SPK_SIZE    )
  ) u_lzd (
    .data_i                ( res_spk_buf_calc),
    .leading_zero_count_o  ( res_spk_lod_o   )
  );

// sum spiking out for result
  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      out_spk_buf <= 'd0 ;
    end
    else begin
      if( out_spk_val_i )begin
        out_spk_buf <= {out_spk_buf[OUT_SPK_SIZE_B-1-CU_NUM:0],out_spk_i} ;
      end
      else if (out_calc_val)begin
        out_spk_buf <= 'd0  ; 
      end
    end
  end

  integer i;
  always @(posedge clk or negedge rstn ) begin
    if (!rstn ) begin
      for (i = 0; i < OUT_SPK_SIZE; i = i + 1)
        out_acc[i] <= 'd0;
    end else if (out_calc_val) begin
      for (i = 0; i < OUT_SPK_SIZE; i = i + 1) begin
        if (out_spk_buf[i])
          out_acc[OUT_SPK_SIZE-1-i] <= out_acc[OUT_SPK_SIZE-1-i] + 1;
      end
    end else if (result_val_o) begin
      for (i = 0; i < OUT_SPK_SIZE; i = i + 1)
        out_acc[i] <= 'd0;
      end
  end

  
  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      result_o  <= 'd0 ;
      cnt       <= 'd0 ;
      max_value <= 'd0 ;
    end
    else begin
      if( comp_val_i | cnt != 'd0 )begin
        result_o  <=  out_acc[cnt] > max_value  ?  cnt          : result_o          ;
        max_value <=  out_acc[cnt] > max_value  ?  out_acc[cnt] : max_value         ;
        cnt       <=  cnt == (OUT_SPK_SIZE-'d1) ? 'd0           : cnt + 'd1         ;
      end
      else if(result_val_o) begin
        result_o  <= 'd0 ;
        cnt       <= 'd0 ;
        max_value <= 'd0 ;
      end
    end
  end

  always@(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      result_val_o <=  'd0 ;
    end
    else begin
      if (cnt == (OUT_SPK_SIZE -'d1) )begin
        result_val_o <= 'd1 ;
      end
      else if (result_val_o == 'd1)begin
        result_val_o <= 'd0 ;
      end
    end
  end 

endmodule
