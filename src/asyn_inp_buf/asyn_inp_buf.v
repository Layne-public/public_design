//------------------------------------------------------------------------------
  //
  //  Filename       : asyn_inp_buf.v
  //  Status         : draft
  //  Created        : 2025-06-03
  //  Description    : ad buffer and reshape module
  //                 : AN_CLK 360Hz  slowest clk is 0.2M
//------------------------------------------------------------------------------
`include "defines.vh"
//------------------ SDADC TO CORE interface--------------------------

module asyn_inp_buf( 
  // ANALOG
  AN_CLK            ,
  AN_DAT            ,
  AN_VAL            ,
  AN_RSTN           ,
  BUF_FUL           ,
  // == BUF_MODE          ,
  // DIGITAL                    
  // global
  clk               ,
  rstn              ,
  // control signal input
  window_trigger_an_i,
  lsm_start_ctl_i   ,
  lsm_step_ovr_i    ,
  lsm_done_ctl_i    ,
  dat_grp_len_cfg_i ,
  dat_grp_num_cfg_i ,
  dat_grp_ful_cfg_i ,
  //dat_o
  dat_o             , 
  dat_val_o
);
//*** PARAMETER ****************************************************************

  // global
  parameter    BUF_DEPTH                =  'd512               ;
  parameter    OUT_DEPTH                =  'd32                ;
  parameter    PRE_WORD_NUM             =  'd10                ;
  // derived
  localparam   BUF_WIDTH            = `FUNC_LOG2( BUF_DEPTH
                                        )                      ;
  localparam   OUT_WIDTH            = `FUNC_LOG2( OUT_DEPTH
                                        )                      ;
  localparam   FSM_WD               = 'd3            ;
  parameter    IDLE                 = 3'd0           ;
  parameter    START_SYNC           = 3'd1           ;
  parameter    BUF_RD               = 3'd2           ;
  parameter    BUF_RD_PRE           = 3'd3           ;
  parameter    DONE_SYNC            = 3'd4           ;  

//*** INPUT/OUTPUT *************************************************************
  // ANALOG
  input                            AN_CLK        ;
  input                            AN_DAT        ;
  input                            AN_VAL        ;
  input                            AN_RSTN       ;
//  input                            BUF_MODE      ;   // '1' for backpressure '0' for BP-free
  output                           BUF_FUL       ;
  // DIGITAL
  input                            clk              ;
  input                            rstn             ;
  input                            window_trigger_an_i;
  input                            lsm_start_ctl_i  ;
  input                            lsm_step_ovr_i   ;
  input                            lsm_done_ctl_i   ;
  input      [BUF_WIDTH-2 :0]      dat_grp_len_cfg_i;
  input      [BUF_WIDTH-2 :0]      dat_grp_num_cfg_i;
  input      [BUF_WIDTH-1 :0]      dat_grp_ful_cfg_i;

  output reg [OUT_DEPTH-1 :0]      dat_o            ;
  output reg                       dat_val_o        ;

//*** WIRE/REG *****************************************************************
  // ANALOG LOGIC
  reg [BUF_DEPTH-1 :0] BUF_0        ;
  reg [BUF_DEPTH-1 :0] BUF_1        ;
  reg [BUF_WIDTH-1 :0] BUF_WR_ADDR  ;
  reg                  BUF_SEL_WR   ; // current writing buffer
  wire                 DAT_WR_EN    ;  // buffer not full and write valid
  reg                  BUF_SEL_RD   ; // current reading buffer

  reg                  BUF_0_FUL    ;
  reg                  BUF_1_FUL    ;
  wire                 LSM_DONE     ;
  wire                 BUF_MODE     ;
  reg [BUF_WIDTH-1 :0] BUF_0_START  ;
  reg [BUF_WIDTH-1 :0] BUF_1_START  ;
  reg                  capture_active;
  reg [BUF_WIDTH   :0] post_sample_count;
  // DIGITAL LOGIC
  // fsm
  reg        [FSM_WD   -1 :0]    cur_state_r ;
  reg        [FSM_WD   -1 :0]    nxt_state_w ;

  // buf pointer
  reg        [BUF_WIDTH-1 :0]    buf_rd_addr ;
  reg        [BUF_WIDTH-2 :0]    buf_grp_cnt ;
  reg        [BUF_WIDTH-2 :0]    buf_rd_cnt  ;
  reg                            buf_cnt_done;

//*** MAIN BODY ***************************************************************  


  // Each lead keeps a circular history of ten 10-bit words.  A synchronized
  // R-peak trigger freezes the logical start of that history, after which
  // twenty more words are collected.  The stored window is still exposed as
  // thirty 10-bit words, so the existing T2S reader is unchanged.
  assign BUF_FUL = BUF_0_FUL & BUF_1_FUL;

  wire lsm_done_an_ack;

  pulse_async u_done_async2AN (
    .clk_src_i      ( clk            ),
    .rst_src_ni     ( rstn           ),
    .src_pulse_i    ( lsm_done_ctl_i ),
    .src_pulse_en_o ( /*UNUSED */    ),
    .src_busy_o     ( /*UNUSED */    ),
    .clk_dst_i      ( AN_CLK         ),
    .rst_dst_ni     ( AN_RSTN        ),
    .dst_pulse_o    ( LSM_DONE       )
  );

  pulse_async u_DONE_async2dig (
    .clk_src_i      ( AN_CLK          ),
    .rst_src_ni     ( AN_RSTN         ),
    .src_pulse_i    ( LSM_DONE        ),
    .src_pulse_en_o ( /*UNUSED */     ),
    .src_busy_o     ( /*UNUSED */     ),
    .clk_dst_i      ( clk             ),
    .rst_dst_ni     ( rstn            ),
    .dst_pulse_o    ( lsm_done_an_ack )
  );

  wire [BUF_WIDTH:0] window_sample_count;
  wire [BUF_WIDTH:0] pre_sample_count;
  wire [BUF_WIDTH:0] post_sample_target;
  wire [BUF_WIDTH:0] window_start_sum;
  wire [BUF_WIDTH-1:0] window_start_next;
  wire selected_buffer_full;
  wire capture_finishes;

  assign window_sample_count = {1'b0, dat_grp_ful_cfg_i} + 1'b1;
  assign pre_sample_count    = dat_grp_len_cfg_i * PRE_WORD_NUM;
  assign post_sample_target  = window_sample_count - pre_sample_count;
  assign window_start_sum    = {1'b0, BUF_WR_ADDR} + window_sample_count
                             - pre_sample_count;
  assign window_start_next   = (BUF_WR_ADDR >= pre_sample_count[BUF_WIDTH-1:0])
                             ? BUF_WR_ADDR - pre_sample_count[BUF_WIDTH-1:0]
                             : window_start_sum[BUF_WIDTH-1:0];
  assign selected_buffer_full = BUF_SEL_WR ? BUF_1_FUL : BUF_0_FUL;
  assign DAT_WR_EN = AN_VAL & !BUF_FUL & !selected_buffer_full;
  assign capture_finishes = DAT_WR_EN
                          & (capture_active | window_trigger_an_i)
                          & ((capture_active
                              ? post_sample_count
                              : {BUF_WIDTH+1{1'b0}})
                             == post_sample_target - 1'b1);

  always @(posedge AN_CLK or negedge AN_RSTN) begin
    if (!AN_RSTN) begin
      BUF_0_FUL        <= 1'b0;
      BUF_1_FUL        <= 1'b0;
      BUF_SEL_WR       <= 1'b0;
      BUF_SEL_RD       <= 1'b0;
      BUF_WR_ADDR      <= {BUF_WIDTH{1'b0}};
      BUF_0_START      <= {BUF_WIDTH{1'b0}};
      BUF_1_START      <= {BUF_WIDTH{1'b0}};
      capture_active   <= 1'b0;
      post_sample_count<= {(BUF_WIDTH+1){1'b0}};
    end
    else begin
      // Release the window just consumed by the digital core.
      if (LSM_DONE) begin
        if (!BUF_SEL_RD && BUF_0_FUL) begin
          BUF_0_FUL  <= 1'b0;
          BUF_SEL_RD <= 1'b1;
        end
        else if (BUF_SEL_RD && BUF_1_FUL) begin
          BUF_1_FUL  <= 1'b0;
          BUF_SEL_RD <= 1'b0;
        end
      end

      // Latch the oldest pre-trigger sample.  If the trigger arrives between
      // valid DSM samples, capture starts on the next AN_VAL cycle.
      if (window_trigger_an_i && !capture_active && !selected_buffer_full) begin
        if (BUF_SEL_WR)
          BUF_1_START <= window_start_next;
        else
          BUF_0_START <= window_start_next;
        capture_active    <= 1'b1;
        post_sample_count <= {(BUF_WIDTH+1){1'b0}};
      end

      if (DAT_WR_EN) begin
        if (BUF_WR_ADDR == dat_grp_ful_cfg_i)
          BUF_WR_ADDR <= {BUF_WIDTH{1'b0}};
        else
          BUF_WR_ADDR <= BUF_WR_ADDR + 1'b1;

        if (capture_active | window_trigger_an_i) begin
          if (capture_finishes) begin
            if (BUF_SEL_WR)
              BUF_1_FUL <= 1'b1;
            else
              BUF_0_FUL <= 1'b1;
            BUF_SEL_WR        <= ~BUF_SEL_WR;
            BUF_WR_ADDR       <= {BUF_WIDTH{1'b0}};
            capture_active    <= 1'b0;
            post_sample_count <= {(BUF_WIDTH+1){1'b0}};
          end
          else begin
            capture_active    <= 1'b1;
            post_sample_count <= post_sample_count + 1'b1;
          end
        end
      end
    end
  end

  always @(posedge AN_CLK or negedge AN_RSTN) begin
    if (!AN_RSTN) begin
      BUF_0 <= {BUF_DEPTH{1'b0}};
      BUF_1 <= {BUF_DEPTH{1'b0}};
    end
    else if (DAT_WR_EN) begin
      if (BUF_SEL_WR)
        BUF_1[BUF_WR_ADDR] <= AN_DAT;
      else
        BUF_0[BUF_WR_ADDR] <= AN_DAT;
    end
  end
// DIGITAL LOGIC
  // ---------- FSM ---------------
  // sync signal from ANLOG
  wire  buf0_rd_en ;
  wire  buf1_rd_en ;
  sync_stage2 u_BUF0_RD_sync_stage2_dig (
    .clk_dst    ( clk                     ),
    .rst_dst_n  ( rstn                    ),
    .data_i     ( BUF_0_FUL & !BUF_SEL_RD ),
    .data_o     ( buf0_rd_en              )
  );

  sync_stage2 u_BUF1_RD_sync_stage2_dig (
    .clk_dst    ( clk                     ),
    .rst_dst_n  ( rstn                    ),
    .data_i     ( BUF_1_FUL &  BUF_SEL_RD ),
    .data_o     ( buf1_rd_en              )
  );

  // Translate the legacy linear T2S read address into the captured circular
  // window.  The start pointers are stable before the synchronized FULL flag.
  wire [BUF_WIDTH-1:0] active_window_start;
  wire [BUF_WIDTH  :0] circular_read_sum;
  wire [BUF_WIDTH  :0] circular_read_wrapped;
  wire [BUF_WIDTH-1:0] circular_read_addr;

  assign active_window_start = BUF_SEL_RD ? BUF_1_START : BUF_0_START;
  assign circular_read_sum   = {1'b0, active_window_start}
                             + {1'b0, buf_rd_addr};
  assign circular_read_wrapped = (circular_read_sum >= window_sample_count)
                               ? circular_read_sum - window_sample_count
                               : circular_read_sum;
  assign circular_read_addr = circular_read_wrapped[BUF_WIDTH-1:0];

  // cur_state_r
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
                                                       nxt_state_w = IDLE         ;
    case( cur_state_r )
      IDLE        :   if( lsm_start_ctl_i )            nxt_state_w = START_SYNC   ;
                      else                             nxt_state_w = IDLE         ;

      START_SYNC  :   if    ( buf0_rd_en | buf1_rd_en) nxt_state_w = BUF_RD_PRE   ;
                      else                             nxt_state_w = START_SYNC   ;

      BUF_RD_PRE  :                                    nxt_state_w = BUF_RD       ;

      BUF_RD      :   if( lsm_done_ctl_i )             nxt_state_w = DONE_SYNC    ;
                      else if(lsm_step_ovr_i)          nxt_state_w = BUF_RD_PRE   ;
                      else                             nxt_state_w = BUF_RD       ;
      

      DONE_SYNC   :   if( lsm_done_an_ack )            nxt_state_w = IDLE         ;
                      else                             nxt_state_w = DONE_SYNC    ;
    endcase
  end


  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      buf_rd_addr <= 'd0 ;  // BUF的指针
      buf_grp_cnt <= 'd0 ;  // 
      buf_rd_cnt  <= 'd0 ;  // 一个时间步的BUF的指针
      dat_val_o   <= 'd0 ;
      buf_cnt_done<= 'd0 ;
    end
    else begin
      case (cur_state_r)
        START_SYNC :begin
                      buf_rd_addr <= 'd0                ;
                      buf_grp_cnt <= 'd0                ;
                      buf_rd_cnt  <= 'd0                ;
                      dat_val_o   <= 'd0                ;
                      buf_cnt_done<= 'd0                ;
                    end
        BUF_RD_PRE :begin
                      buf_rd_addr <= buf_grp_cnt        ;
                      buf_grp_cnt <= buf_grp_cnt + 'd1  ;
                      buf_rd_cnt  <= 'd0                ;
                      dat_val_o   <= 'd0                ;
                      buf_cnt_done<= 'd0                ;
                    end
        BUF_RD     :begin
                      if(!buf_cnt_done)begin
                        buf_rd_addr <= buf_rd_addr + dat_grp_len_cfg_i ;
                        buf_rd_cnt  <= buf_rd_cnt + 1                  ;
                      end
                      if(buf_rd_cnt == dat_grp_num_cfg_i-1 )begin  // 默认进入这个状态开始的每一个cycle都会存一个数
                        dat_val_o    <= 'd1 ;
                        buf_cnt_done <= 'd1 ;
                      end
		      else if(dat_val_o) begin
		      	dat_val_o <= 'd0 ;
		      end
                    end
        DONE_SYNC  :begin
		      if(lsm_done_an_ack)begin
                        buf_rd_addr <= 'd0              ;
                        buf_grp_cnt <= 'd0              ;
                        buf_rd_cnt  <= 'd0              ;
                        dat_val_o   <= 'd0              ;		      	
                        buf_cnt_done<= 'd0              ;		      	
		      end
		    end
      endcase
    end
  end
  // generate data out
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dat_o   <= 'd0 ;  
    end
    else if((cur_state_r==BUF_RD) && !buf_cnt_done) begin
      dat_o[buf_rd_cnt] <= buf0_rd_en ? BUF_0[circular_read_addr] :
                           buf1_rd_en ? BUF_1[circular_read_addr] : 'd0 ;
    end
    else if (cur_state_r==IDLE && nxt_state_w== START_SYNC)begin 
      dat_o   <= 'd0 ;
    end
  end

endmodule
