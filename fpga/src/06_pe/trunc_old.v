`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : trunc
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Truncate data into lower bit witdh. Always truncate at lower bits, 
//    controlled by trunc_pos.
//    Constraints:  IDW - ODWH >= trunc_pos
//    Consider saturation.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-14  Chen Wu       Initial version
// -----------------------------------------------------------------------------


module trunc_old #(
  // IDW indicates the data width of input data
  parameter         IDW     =   20                      ,

  // ODWH indicates the data width of output data
  // ODWL indicates the data width with lower precision
  // ODWL only work for mixed precision
  parameter         ODWH    =   16                      ,
  parameter         ODWL    =   8                       ,

  // NUM indicates the number of data
  parameter         NUM     =   64                      
  )(
  output    reg     [ODWH*NUM-1 : 0]    dout = 0        ,

  input             [ IDW*NUM-1 : 0]    din             ,
  input             [         2 : 0]    trunc_pos       ,
  input                                 mode            ,

  input                                 clk             ,
  input                                 reset           
  );

  localparam        UBH     =   {1'b0, {(ODWH-1){1'b1}}};
  localparam        LBH     =   {1'b1, {(ODWH-1){1'b0}}}; 
  localparam        UBL     =   {1'b0, {(ODWL-1){1'b1}}};
  localparam        LBL     =   {1'b1, {(ODWL-1){1'b0}}}; 

  genvar i;
  generate for ( i = 0; i < NUM; i = i + 1 ) begin
    wire    [ODWH-1 : 0]      dout_tmp                              ;
    assign  dout_tmp  =   din[IDW*i +: IDW]   >>  trunc_pos         ;
    always @(posedge clk) begin
      if ( ~mode ) begin
        if ( dout_tmp[ODWH] == din[IDW*i+IDW-1] )
          dout[ODWH*i +: ODWH]  <=  dout_tmp                        ;
        else if ( din[IDW*i+IDW-1] )
          dout[ODWH*i +: ODWH]  <=  LBH                             ;
        else
          dout[ODWH*i +: ODWH]  <=  UBH                             ;
      end else begin
        if ( dout_tmp[ODWH] == din[IDW*i+IDW-1] )
          dout[ODWH*i +: ODWH]  <=  $signed(dout_tmp[0 +: ODWL])    ;
        else if ( din[IDW*i+IDW-1] )
          dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
        else
          dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      end

      // if ( ~mode ) begin
      //   case ( trunc_pos )
      //   3'h0  : begin
      //             if ( (&din[IDW*i+ODWH-1 +: (IDW-ODWH+1)]) || (~(|din[IDW*i+ODWH-1 +: (IDW-ODWH+1)])) )
      //               dout[ODWH*i +: ODWH]  <=  din[IDW*i +: ODWH]      ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  LBH                     ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  UBH                     ;
      //           end 
      //   3'h1  : begin
      //             if ( (&din[IDW*i+ODWH-0 +: (IDW-ODWH+0)]) || (~(|din[IDW*i+ODWH-0 +: (IDW-ODWH+0)])) )
      //               dout[ODWH*i +: ODWH]  <=  din[IDW*i+1 +: ODWH]    ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  LBH                     ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  UBH                     ;
      //           end 
      //   3'h2  : begin
      //             if ( (&din[IDW*i+ODWH+1 +: (IDW-ODWH-1)]) || (~(|din[IDW*i+ODWH+1 +: (IDW-ODWH-1)])) )
      //               dout[ODWH*i +: ODWH]  <=  din[IDW*i+2 +: ODWH]    ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  LBH                     ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  UBH                     ;
      //           end 
      //   3'h3  : begin
      //             if ( (&din[IDW*i+ODWH+2 +: (IDW-ODWH-2)]) || (~(|din[IDW*i+ODWH+2 +: (IDW-ODWH-2)])) )
      //               dout[ODWH*i +: ODWH]  <=  din[IDW*i+3 +: ODWH]    ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  LBH                     ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  UBH                     ;
      //           end 
      //   3'h4  : begin
      //             if ( (&din[IDW*i+ODWH+3 +: (IDW-ODWH-3)]) || (~(|din[IDW*i+ODWH+3 +: (IDW-ODWH-3)])) )
      //               dout[ODWH*i +: ODWH]  <=  din[IDW*i+4 +: ODWH]    ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  LBH                     ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  UBH                     ;
      //           end 
      //   endcase
      // end else begin
      //   case ( trunc_pos )
      //   3'h0  : begin
      //             if ( (&din[IDW*i+ODWL-1 +: (IDW-ODWL+1)]) || (~(|din[IDW*i+ODWL-1 +: (IDW-ODWL+1)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i +: ODWL])     ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   3'h1  : begin
      //             if ( (&din[IDW*i+ODWL-0 +: (IDW-ODWL+0)]) || (~(|din[IDW*i+ODWL-0 +: (IDW-ODWL+0)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i+1 +: ODWL])   ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   3'h2  : begin
      //             if ( (&din[IDW*i+ODWL+1 +: (IDW-ODWL-1)]) || (~(|din[IDW*i+ODWL+1 +: (IDW-ODWL-1)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i+2 +: ODWL])   ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   3'h3  : begin
      //             if ( (&din[IDW*i+ODWL+2 +: (IDW-ODWL-2)]) || (~(|din[IDW*i+ODWL+2 +: (IDW-ODWL-2)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i+3 +: ODWL])   ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   3'h4  : begin
      //             if ( (&din[IDW*i+ODWL+3 +: (IDW-ODWL-3)]) || (~(|din[IDW*i+ODWL+3 +: (IDW-ODWL-3)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i+4 +: ODWL])   ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   3'h5  : begin
      //             if ( (&din[IDW*i+ODWL+4 +: (IDW-ODWL-4)]) || (~(|din[IDW*i+ODWL+4 +: (IDW-ODWL-4)])) )
      //               dout[ODWH*i +: ODWH]  <=  $signed(din[IDW*i+5 +: ODWL])   ;
      //             else if ( din[IDW*i+IDW-1] )
      //               dout[ODWH*i +: ODWH]  <=  $signed(LBL)                    ;
      //             else
      //               dout[ODWH*i +: ODWH]  <=  $signed(UBL)                    ;
      //           end 
      //   endcase
      // end
    end
  end
  endgenerate

endmodule