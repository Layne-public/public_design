//------------------------------------------------------------------------------
 //
 //  Filename       : rst_sync.v
 //  Status         : draft
 //  Created        : 2025-08-23
 //  Description    : Generic reset synchronizer.
 //                   - Asynchronous assert, synchronous de-assert.
 //                   - Parameterized stages (2~3 typical).
 //                   - Polarity selectable for input/output.
 //                   - Designed for easy constrain in Design Compiler.
 //
 //  Notes          :
 //    * For DC constraints (example):
 //        set_false_path -from [get_ports rst_async_i] \
 //                       -to   [get_pins u_rst_sync/sft_reg[*]/D]
 //    * Use ungated clock of the target domain for clk.
 //    * STAGES=2 for common use; STAGES=3 for extra MTBF margin.
 //
//------------------------------------------------------------------------------

module rstn_sync(
  input        clk    ,
  input        rstn_i ,
  output       rstn_o 
);
//*** PARAMETER ****************************************************************

  parameter SYN_STG =  'd2   ;

//*** WIRE/REG  *****************************************************************
  reg  [SYN_STG -1: 0] sft_reg  ;

//*** MAIN BODY ****************************************************************
  // Asynchronous assert
  always @(posedge clk or negedge rstn_i) begin
    if (!rstn_i) begin
      sft_reg <= 'd0;
    end else begin
      sft_reg <= {sft_reg[SYN_STG -2: 0], 1'b1 };
    end
  end

  // Output polarity selection
  assign rstn_o = sft_reg[SYN_STG -1];

endmodule
