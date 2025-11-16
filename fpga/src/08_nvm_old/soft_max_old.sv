`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ifm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    This is pipelined soft_max module in NPE, with a 16 elements 16-bit vector 
//    input and the same sized output.
//    x_i is Q16_9,  y is Q16_14. 
//    The input data transfer is done by set pkg done signal. 
//    The vector length should be N*16.
//    The NUM_ELEMS is the number of fixed-points handled per cycle,
//    MAX_PKG_LEN is the maximum number of row buffers can be used. 
//     is the intermediate results where  = x - x_max,
//    [i] is the results from linear approximation module, 
//    sum_y is the sum of [i]. 
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2020-11-06  Yiheng Jian   Initial version
// 1.1            2022-04-04  Chen Wu       Align definition, change stype
// -----------------------------------------------------------------------------


module soft_max_old #(
  parameter     DATA_WIDTH    = 16                                , 
  parameter     NUM_ELEMS     = 32                                , 
  parameter     MAX_PKG_LEN   = 2   
) (
  input                                           clk             ,
  input                                           rst             ,
  input                                           enable          ,
  input                        [6:0]              nvm_rstep       ,
  input                                           sf_din_vld      ,
  input                                           sf_din_done     ,
  input   signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0]  sf_din          , // all are Q16_9
  output  reg    [NUM_ELEMS-1:0][DATA_WIDTH-1:0]  sf_dout      =0 , // Q16_14 because   could be 1.
  output  reg                                     sf_dout_vld  =0 ,
  output  reg                                     sf_dout_done =0       
);

  localparam BUFFER_DEEP =64;
  reg  signed   [NUM_ELEMS-1:0][DATA_WIDTH-1:0] BUFFER1     [BUFFER_DEEP]; // buffering the input  
  reg  signed   [NUM_ELEMS-1:0][DATA_WIDTH-1:0] BUFFER2     [BUFFER_DEEP]; // Q16_14
  reg                                           BUFFER2_vld [BUFFER_DEEP];
  reg                                           BUFFER2_done[BUFFER_DEEP];

  reg [5:0] len_in  =0  ;
  reg [5:0] len_cur =0  ;
  reg [5:0] len_sub =0  ;
  reg [5:0] len_exp =0  ;
  reg [5:0] len_sum =0  ;
  reg [5:0] len_div =0  ;

  //------------------------------------------------------
  // one cycle
  //------------------------------------------------------
  wire signed   [DATA_WIDTH-1:0] max_current     ;
  wire                           max_current_vld ;
  wire                           max_current_done;
  sf_max_old #(
      .DATA_WIDTH       (DATA_WIDTH              ), 
      .NUM_ELEMS        (NUM_ELEMS               )
  )U_MAX_old(
      .in               (sf_din                  ),
      .max              (max_current             ),
      .clk              (clk                     )
  );

  dly_cell #(
    .DLY                (3                       ),
    .DW                 (2                       )
  ) U_dly_mc(
    .dout               ({max_current_vld,
                          max_current_done      }),
    .din                ({sf_din_vld,sf_din_done}),
    .clk                (clk                     ),
    .reset              (rst                     )
  );

  //------------------------------------------------------
  // nex cycle
  //------------------------------------------------------
  reg  signed   [DATA_WIDTH-1:0] max_result      =0;
  reg                            max_result_vld  =0;
  reg                            max_result_done =0;

  //------------------------------------------------------
  // sub out
  //------------------------------------------------------
  reg                                           sub_enable  =0 ;
  reg                                           sub_in_vld  =0 ;
  reg                                           sub_in_done =0 ;
  reg signed    [NUM_ELEMS-1:0][DATA_WIDTH-1:0] sub_in_data =0 ; // all are Q16_9
  wire signed                                   sub_result_vld ;
  wire signed                                   sub_result_done;
  wire signed   [NUM_ELEMS-1:0][DATA_WIDTH:0]   sub_result     ; // Q17_9
  sf_sub_old #(
      .DATA_WIDTH       (DATA_WIDTH     ), 
      .NUM_ELEMS        (NUM_ELEMS      )
  )U_SUB(
      .clk              (clk            ),
      .rst              (rst            ),
      .ina_vld          (sub_in_vld     ),
      .ina_done         (sub_in_done    ),
      .ina_data         (sub_in_data    ),
      .inb_vld          (sub_in_vld     ),
      .inb_done         (sub_in_done    ),
      .inb_data         (max_result     ),
      .out_vld          (sub_result_vld ),
      .out_done         (sub_result_done),
      .out_data         (sub_result     )

  );

 
  //---------------------------------------------------------------
  // the validation of subtraction outcome enables the exp_func
  //---------------------------------------------------------------
  wire                                          exp_result_vld  ;
  wire                                          exp_result_done ;
  wire signed   [NUM_ELEMS-1:0][DATA_WIDTH-1:0] exp_result      ; // Q16_14
  sf_exp_old #(
      .NUM_ELEMS        (NUM_ELEMS      ), 
      .DATA_WIDTH       (DATA_WIDTH     )
  ) U_EXP (
      .clk              (clk            ), 
      .rst              (rst            ), 
      .in_data          (sub_result     ),
      .in_vld           (sub_result_vld ),
      .in_done          (sub_result_done),
      .out_data         (exp_result     ),
      .out_vld          (exp_result_vld ),
      .out_done         (exp_result_done)
  );



  //------------------------------------------------------------
  // one cycle sum
  //------------------------------------------------------------
  wire signed   [2*DATA_WIDTH-1:0]  sum_current     ;
  wire                              sum_current_vld ;
  wire                              sum_current_done;
  sf_sum_old #(
      .IN_WIDTH         (DATA_WIDTH              ), 
      .OUT_WIDTH        (2*DATA_WIDTH            ), 
      .NUM_ELEMS        (NUM_ELEMS               )
  )U_SUM (
      .clk              (clk                     ), 
      .in_data          (exp_result              ),
      .out_data         (sum_current             )
  );
  dly_cell #(
    .DLY                (3                       ),
    .DW                 (2                       )
  ) U_dly_sc(
    .dout               ({sum_current_vld,
                          sum_current_done      }),
    .din                ({exp_result_vld,
                          exp_result_done       }),
    .clk                (clk                     ),
    .reset              (rst                     )
  );

  //-------------------------------------------------
  // sum out
  //--------------------------------------------------
  reg  signed   [2*DATA_WIDTH-1:0]  sum_result      =0;
  reg                               sum_result_vld  =0;
  reg                               sum_result_done =0;



 //--------------------------------------------------------------
 // division result Q32_16  
 //--------------------------------------------------------------
  reg                                           div_enable      =0  ;
  reg signed    [NUM_ELEMS-1:0][DATA_WIDTH-1:0] dividend_data   =0  ;
  reg                                           dividend_vld    =0  ;
  reg                                           dividend_done   =0  ;
  reg signed    [DATA_WIDTH*2-1:0]              divisor_data    =0  ;
  reg                                           divisor_vld     =0  ;
  wire signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0]   div_result_data     ;
  wire                                          div_result_vld      ;
  wire                                          div_result_done     ;
  
  localparam SF_DIV_DLY =16;
  sf_div_old #(
      .NUM_ELEMS            (NUM_ELEMS      ),
      .DATA_WIDTH           (DATA_WIDTH     ),
      .SF_DIV_DLY           (SF_DIV_DLY     )
  )U_DIV(
      .clk                  (clk            ), 
      .divisor_vld          (divisor_vld    ), 
      .divisor_data         (divisor_data   ), 
      .dividend_vld         (dividend_vld   ),
      .dividend_done        (dividend_done  ),
      .dividend_data        (dividend_data  ),
      .div_result_vld       (div_result_vld ),
      .div_result_done      (div_result_done),
      .div_result_data      (div_result_data)
  ); 
  



//-------------------------------------------------------------------------------
// store the data package length
// if (cur_len == 5'b0)
// len <= in_len;
// buffering the input data
// keep tracking the current data package length
// find the maximum in all data package
// input buffering done in the next cycle, enable the subtracter first
// if (cur_len == len-1 && !) begin          
// transmit vector data from buffer to 
// transmition done in next cycle
// for each data package
// all data package are fed into subtracters.
// add all sum_y of each data package and buffer all exps
// reset the   value for next time
//   <= 16'sh8000;
// keep tracking the sum_y is from which data package          
// buffering the exp_func results
//  buffering done in the next cycle, enable the divider first
// reset the   value for next time   
// transmit data from buffer to , to prepare the inputs of dividers
// fetch a data package as dividends from 
// transimition done in the next cycle
// all data package are fed into dividers. Just invalid all input signals
//-------------------------------------------------------------------------------




always @(posedge clk)
if (rst)
begin  
          div_enable    <= 0;
          sum_result    <= 0;
          max_result    <= 0;
          sub_enable    <= 0;
          sub_in_vld    <= 0;
          divisor_data   <= 0;
          divisor_vld   <= 0;
          dividend_vld  <= 0;
          for (int i = 0; i < NUM_ELEMS; i++) begin
              dividend_data[i]  <= 0;
              sub_in_data[i]    <= 0;
          end

          for (int i = 0; i < BUFFER_DEEP; i++) begin
              for (int j = 0; j < NUM_ELEMS; j++) begin
                  BUFFER1[i][j]        <= 0;
                  BUFFER2[i][j]        <= 0;
              end
                  BUFFER2_vld [i]      <= 0;
                  BUFFER2_done[i]      <= 0;
          end
end 
else if(enable)
begin
          //------------------------------------------------------
          if (sf_din_vld)
          begin
              len_in           <= len_in + 1    ;
              BUFFER1[len_in]  <= sf_din        ;
              if (sf_din_done) len_in<= 0       ;
          end 


          //------------------------------------------------------
          if (max_current_vld)
          begin
              len_cur           <= len_cur + 1;
              max_result_vld    <= 1;
              max_result_done   <= len_cur == nvm_rstep-1 ;
              if ($signed(max_result) > $signed(max_current))
                          max_result  <=        max_result ;
              else        max_result  <=        max_current;

              if (max_current_done && !sub_in_vld)
                begin
                  len_cur         <= 0 ;
                  sub_enable      <= 1 ;
                end 
          end else begin
          //max_result      <= 0 ;
            max_result_vld  <= 0 ;
            max_result_done <= 0 ;
          end



          //------------------------------------------------------
          if (sub_enable) begin
              len_sub           <= len_sub + 1  ;
              sub_in_vld        <= 1            ;
              sub_in_done       <= len_sub == nvm_rstep-1;
              sub_in_data       <= BUFFER1[len_sub];
              if (len_sub == nvm_rstep-1)
              begin
                    len_sub     <=0;
                    sub_enable  <=0;
              end
          end else 
          begin
                sub_in_vld  <= 0;
                sub_in_done <= 0;
                sub_in_data <= 0;
          end

          //-------------------------------------------------------
          if (sub_result_done)max_result  <= 0 ;


          //-------------------------------------------------------
          if (exp_result_vld)
          begin
              len_exp   <= len_exp + 1;
              BUFFER2      [len_exp] <= exp_result      ;
              BUFFER2_vld  [len_exp] <= exp_result_vld  ;
              BUFFER2_done [len_exp] <= exp_result_done ;
              if(exp_result_done)    len_exp<=0         ;
          end


          //-------------------------------------------------------
          if (sum_current_vld)
          begin
              len_sum        <= len_sum + 1;
              sum_result     <= sum_result + sum_current; 
              sum_result_vld <= 1                       ;
              sum_result_done<= len_sum == nvm_rstep-1  ;
              
                  if (len_sum == nvm_rstep-1 && !div_enable)
                  begin
                      div_enable    <= 1'b1;
                      len_sum       <= 0;
                  end
          end
          else begin
              sum_result_vld <=0;
              sum_result_done<=0;
            //sum_result     <=0;
          end

         
         //---------------------------------------------------
          if (div_enable)
          begin
              len_div       <= len_div + 1;
              dividend_data<= BUFFER2     [len_div];
              dividend_vld  <= BUFFER2_vld [len_div];
              dividend_done <= BUFFER2_done[len_div];
              divisor_data  <= sum_result;
              divisor_vld   <= 1;


              if (len_div == nvm_rstep-1)
              begin
                  len_div     <=  0   ;
                  div_enable  <=  0   ;
                  sum_result  <=  0   ;
              end
          end else
          begin
              dividend_data   <=  0  ;
              dividend_vld    <=  0  ;
              dividend_done   <=  0  ;
              divisor_data    <=  0  ;
              divisor_vld     <=  0  ;
          end
end




  //-----------------------------------------------
  // choose output,if not enable, set x as output
  //----------------------------------------------
  always @(posedge clk)
  if(enable)begin
      sf_dout       <= div_result_vld?div_result_data:0;
      sf_dout_vld   <= div_result_vld ;
      sf_dout_done  <= div_result_done;
  end
  else begin
      sf_dout       <= sf_din_vld?sf_din:0;
      sf_dout_vld   <= sf_din_vld   ;
      sf_dout_done  <= sf_din_done  ;
  end


endmodule
