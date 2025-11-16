`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : pe_tb
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for pe 
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-14  Chen Wu       Initial version
// -----------------------------------------------------------------------------

module tb_pe();
  // please change the directory when you run it.
  localparam      FILE_XIN    ="E:/workspace/00_github/01_ucla/bert_opu_verification/test_chen/x_in.txt"      ;
  localparam      FILE_YIN    ="E:/workspace/00_github/01_ucla/bert_opu_verification/test_chen/y_in.txt"      ;
  localparam      FILE_TRUOUT ="E:/workspace/00_github/01_ucla/bert_opu_verification/test_chen/trunc_out.txt" ;

  // parameters for pe
  localparam      PRECISION   =   3'b001                                        ;
  localparam      MUL_NUM     =   512                                           ;
  localparam      DIN_NUM     =   32                                            ;
  localparam      DOUT_NUM    =   32                                            ;

  localparam      XDW         =   PRECISION == 3'b000 ?  8 * MUL_NUM :
                                  PRECISION == 3'b001 ? 16 * MUL_NUM :
                                  PRECISION == 3'b010 ?  8 * MUL_NUM :
                                                        18 * MUL_NUM            ;

  localparam      YDW         =   PRECISION == 3'b000 ?  4 * MUL_NUM :
                                  PRECISION == 3'b001 ? 16 * MUL_NUM :
                                  PRECISION == 3'b010 ?  4 * MUL_NUM :
                                                        18 * MUL_NUM            ;

  localparam      PDW         =   PRECISION == 3'b000 ? 16 :
                                  PRECISION == 3'b001 ? 32 :
                                  PRECISION == 3'b010 ? 16 : 36                 ;
  
  localparam      ADD_STAGE   =   $clog2(DIN_NUM)                               ;
  localparam      TREE_NUM    =   MUL_NUM / DIN_NUM                             ;

  localparam      ADD_DW      =   PRECISION == 3'b010 ? 9 : PDW                 ;
  localparam      ADD_ODW     =   PRECISION == 3'b010 ? ADD_DW*2+ADD_STAGE-3 :
                                                        ADD_DW+ADD_STAGE        ;  

  localparam      ODW         =   PRECISION == 3'b000 ? 26 : 
                                  PRECISION == 3'b001 ? ADD_ODW :
                                  PRECISION == 3'b010 ? 16 : ADD_ODW            ; 

  
  // general parameters
  localparam      MODE        =   0                                             ;
  localparam      OUT_N       =   3'b101                                        ;
  localparam      TRUNC       =   3'b000                                        ;
  localparam      DELAY1       =  PRECISION == 3'b010 ? 2+ADD_STAGE :  
                                  OUT_N     == 3'b100 ? 1+ADD_STAGE :
                                  OUT_N     == 3'b101 ? ADD_STAGE   :
                                  OUT_N     == 3'b011 ? 2+ADD_STAGE : 
                                                        2+ADD_STAGE             ;
  
  localparam      TEST_NUM    =   PRECISION == 3'b000 ?  27 :
                                  PRECISION == 3'b001 ?  9  :
                                       MODE == 1'b0   ?  27 :
                                                         243                    ;
  localparam      CYCLE       =   4.0                                           ;

  wire            [  ODW*64-1 : 0]      dout                                    ;

  reg             [     XDW-1 : 0]      din_x = 0                               ;
  reg             [     YDW-1 : 0]      din_y = 0                               ;
  reg                                   mode = 0                                ;
  reg             [         2 : 0]      output_num = 0                          ;
  reg             [         2 : 0]      trunc_pos = 0                           ;

  reg                                   clk                                     ;
  reg                                   reset = 1                               ;

  //for test
  reg             [    XDW-1 : 0]       x_mem[TEST_NUM-1:0]                     ;
  reg             [    YDW-1 : 0]       y_mem[TEST_NUM-1:0]                     ;
  reg             [       19 : 0]       addr                                    ;
  reg                                   in_valid                                ;
  wire                                  mul_valid                               ;
  wire                                  add_valid                               ;
  wire                                  trunc_valid                             ;
  integer                               handle                                  ;

  initial begin
    clk           =     1'b1                                ;
    forever #(CYCLE / 2)
      clk         =     ~clk                                ;
  end

  initial begin
    handle        =     $fopen(FILE_TRUOUT)                 ;
    $readmemb(FILE_XIN, x_mem)                              ;
    $readmemb(FILE_YIN, y_mem)                              ;

    repeat (20) @(posedge clk)                              ;
    reset         <=    1'b0                                ;
    repeat (20) @(posedge clk)                              ;

    @(posedge clk)                                          ;
    mode          <=    MODE                                ;
    output_num    <=    OUT_N                               ;
    trunc_pos     <=    TRUNC                               ;

    repeat ( (TEST_NUM*2+100) / CYCLE ) @(posedge clk)      ;
    $display("Finish running.")                             ;
    $fclose(handle)                                         ;
    $finish                                                 ;
  end

always@(posedge clk)begin
    if(reset)begin
        addr<=0;
        in_valid<=1'b0;
    end
    else begin
        if(addr<TEST_NUM)begin
            din_x<=$signed(x_mem[addr][XDW-1 : 0]);
            din_y<=$signed(y_mem[addr][YDW-1 : 0]);
            addr<=addr+1'b1;
            in_valid<=1'b1;
        end
        else begin
            din_x<=din_x;
            din_y<=din_y;
            addr<=TEST_NUM;
            in_valid<=1'b0;
        end
    end
  end

  dly_cell #(
    .DW           ( 1                       ), 
    .DLY          ( 5                       )
  ) u0_dly_cell (
    .dout         ( mul_valid               ),

    .din          ( in_valid                ),

    .clk          ( clk                     ),
    .reset        ( reset                   )
  );
  
  dly_cell #(
    .DW           ( 1                       ), 
    .DLY          ( DELAY1                   )
  ) u1_dly_cell (
    .dout         ( add_valid               ),

    .din          ( mul_valid               ),

    .clk          ( clk                     ),
    .reset        ( reset                   )
  );
  
 dly_cell #(
    .DW           ( 1                       ), 
    .DLY          ( 1                       )
  ) u1_dly_cel2 (
    .dout         ( trunc_valid             ),

    .din          ( add_valid               ),

    .clk          ( clk                     ),
    .reset        ( reset                   )
  ); 

  always@(posedge clk)begin
    if(trunc_valid)begin
      $fdisplay(handle,"%b",dout);
    end
  end

  pe #(
    .PRECISION      ( PRECISION             ),
    .MUL_NUM        ( MUL_NUM               ) 
  ) u0_pe (
    .dout           ( dout                  ),

    .din_x          ( din_x                 ),
    .din_y          ( din_y                 ),
    .mode           ( mode                  ),
    .output_num     ( output_num            ),
    .trunc_pos      ( trunc_pos             ),

    .clk            ( clk                   ),
    .reset          ( reset                 )
  );

endmodule