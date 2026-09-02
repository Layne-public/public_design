 /*                                                                      
 Copyright 2020 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */
//------------------------------------------------------------------------------
  //
  //  Filename       : jtag dm.v
  //  Status         : draft
  //  Created        : 2025-08-20
  //  Description    : only reserved register access logic
  //                   
//------------------------------------------------------------------------------
`define DM_RESP_VALID     1'b1
`define DM_RESP_INVALID   1'b0
`define DTM_REQ_VALID     1'b1
`define DTM_REQ_INVALID   1'b0

`define DTM_OP_NOP        2'b00
`define DTM_OP_READ       2'b01
`define DTM_OP_WRITE      2'b10


module jtag_dm #(
    parameter DMI_ADDR_BITS = 6,
    parameter DMI_DATA_BITS = 32,
    parameter DMI_OP_BITS = 2)(

    clk,
    rst_n,

    // rx
    dm_ack_o,
    dtm_req_valid_i,
    dtm_req_data_i,

    // tx
    dtm_ack_i,
    dm_resp_data_o,
    dm_resp_valid_o,

    dm_reg_we_o,
    dm_reg_addr_o,
    dm_reg_wdata_o,
    dm_reg_rdata_i,

    dm_op_req_o

    );

    parameter DM_RESP_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    localparam DTM_REQ_BITS = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS;
    localparam OP_SUCC = 2'b00;

    // 输入输出信号
    input   wire clk;
    input   wire rst_n;

    output  wire                        dm_ack_o        ;
    input   wire                        dtm_req_valid_i ;
    input   wire [DTM_REQ_BITS-1:0]     dtm_req_data_i  ;

    input   wire                        dtm_ack_i       ;
    output  wire [DM_RESP_BITS-1:0]     dm_resp_data_o  ;
    output  wire                        dm_resp_valid_o ;

    output  wire                        dm_reg_we_o     ;
    output  wire [5       :0]           dm_reg_addr_o   ;
    output  wire [31      :0]           dm_reg_wdata_o  ;
    input   wire [31      :0]           dm_reg_rdata_i  ;
    output  wire                        dm_op_req_o     ;



    wire                    rx_valid;
    wire [DTM_REQ_BITS-1:0] rx_data ;
    wire [31            :0] read_data;
    reg                     need_resp;


    wire [1 :0]  op      = rx_data[1 :0] ;
    wire [31:0]  data    = rx_data[33:2] ;
    wire [5 :0]  address = rx_data[39:34];
    reg  [1 :0]  op_1_r ;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            need_resp <= 'd0;
            op_1_r    <= 'd0;
        end else begin
            need_resp <= rx_valid ? 'd1 : 'd0 ;
            op_1_r    <= rx_valid ?  op : 'd0 ;
        end
    end
    
    assign read_data        = (need_resp & (op_1_r == 'b01))? dm_reg_rdata_i  : 'd0  ;
    assign dm_reg_we_o      = rx_valid  && (op     == 'b10)           ;
    assign dm_reg_addr_o    = address[5:0]                       ;
    assign dm_reg_wdata_o   = data                               ;
    assign dm_op_req_o      = rx_valid     &&   (^op)            ;


    full_handshake_rx #(
      .DW(DTM_REQ_BITS)
      ) rx_inst (
      .clk(clk),
      .rst_n(rst_n),
      .req_i(dtm_req_valid_i),
      .req_data_i(dtm_req_data_i),
      .ack_o(dm_ack_o),
      .recv_data_o(rx_data),
      .recv_rdy_o(rx_valid)
      );


    full_handshake_tx #(
      .DW(DM_RESP_BITS)
      ) tx_inst (
      .clk(clk),
      .rst_n(rst_n),
      .ack_i(dtm_ack_i),
      .req_i(need_resp),
      .req_data_i({address, read_data, OP_SUCC}),
      .idle_o(),
      .req_o(dm_resp_valid_o),
      .req_data_o(dm_resp_data_o)
      );


endmodule
