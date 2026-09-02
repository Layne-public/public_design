//------------------------------------------------------------------------------
  //
  //  Filename       : pulse_async.v
  //  Status         : draft
  //  Created        : 2025-06-04
  //  Description    : pulse_async_handshake
  //                 
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module pulse_async (

  // Source Clock Domain
  input                     clk_src_i,
  input                     rst_src_ni,
  input                     src_pulse_i,
  output                    src_pulse_en_o,
  output                    src_busy_o,
  // Destination Clock Domain
  input                     clk_dst_i,
  input                     rst_dst_ni,
  output                    dst_pulse_o
);

//*** WIRE/REG *****************************************************************

wire                        rst_src_n;
wire                        rst_dst_da_n;

wire                        rst_dst_n;
wire                        rst_src_da_n;

reg                         src_pulse_d;
reg                         src_req;
wire                        dst_req;
reg                         dst_req_d;
wire                        src_ack;

//*** MAIN BODY ****************************************************************

//--- Reset Synchronization ---

// Sync rst_dst_ni to clk_src_i domain
// always @(posedge clk_src_i or negedge rst_dst_ni) begin
//   if (!rst_dst_ni) begin
//     rst_dst_da_n <= 1'b0;
//   end else begin
//     rst_dst_da_n <= 1'b1;
//   end
// end
  dff_sync  rst_dst_da_n_reg(
    .clk  (clk_src_i    ),
    .rstn (rst_dst_ni   ),
    .D    (1'b1         ),
    .Q    (rst_dst_da_n )
  );

// Sync rst_src_ni to clk_dst_i domain
// always @(posedge clk_dst_i or negedge rst_src_ni) begin
//   if (!rst_src_ni) begin
//     rst_src_da_n <= 1'b0;
//   end else begin
//     rst_src_da_n <= 1'b1;
//   end
// end
  dff_sync  rst_src_da_n_reg(
    .clk  (clk_dst_i    ),
    .rstn (rst_src_ni   ),
    .D    (1'b1         ),
    .Q    (rst_src_da_n )
  );


assign rst_src_n = rst_src_ni & rst_dst_da_n;
assign rst_dst_n = rst_dst_ni & rst_src_da_n;


//--- Pulse Edge Detection in Source Domain ---
always @(posedge clk_src_i or negedge rst_src_n) begin
  if (!rst_src_n) begin
    src_pulse_d <= 1'b0;
  end else begin
    src_pulse_d <= src_pulse_i;
  end
end

assign src_pulse_en_o = src_pulse_i & !src_pulse_d & !src_busy_o;  // busy 防止上一个同步脉冲没结束


//--- Pulse Transformation: Pulse -> Level Toggle ---
always @(posedge clk_src_i or negedge rst_src_n) begin
  if (!rst_src_n) begin
    src_req <= 1'b0;
  end else if (src_pulse_en_o) begin
    src_req <= ~src_req;
  end
end


//--- Synchronize src_req to Destination Domain ---
sync_stage2 u_src_sync_stage2_dst (
  .clk_dst    ( clk_dst_i  ),
  .rst_dst_n  ( rst_dst_n  ),
  .data_i     ( src_req    ),
  .data_o     ( dst_req    )
);

//--- Synchronize dst_req back to Source Domain for ACK ---
sync_stage2 u_dst_sync_stage2_src (
  .clk_dst    ( clk_src_i  ),
  .rst_dst_n  ( rst_src_n  ),
  .data_i     ( dst_req    ),
  .data_o     ( src_ack    )
);
assign src_busy_o = (src_req ^ src_ack);


//--- Reconstruct Pulse in Destination Domain ---
always @(posedge clk_dst_i or negedge rst_dst_n) begin
  if (!rst_dst_n) begin
    dst_req_d <= 1'b0;
  end else begin
    dst_req_d <= dst_req;
  end
end

assign dst_pulse_o = (dst_req ^ dst_req_d);  // rising edge detection via XOR

endmodule
