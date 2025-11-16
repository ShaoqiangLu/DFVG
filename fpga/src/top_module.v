`default_nettype none

module top_module #(
    parameter 
        AXI_HP_BIT   = 64,             //HP port width
        DATA_WIDTH   = 16,             //fixed point(Q7.9)
        ROW_WIDTH    = 10,              //matrix 9x8
        COLUMN_WIDTH = 9,
        ADDR_WIDTH   = 14,              //BRAM address width
        MAC_WIDTH    = 32,
        OUT_WIDTH    = 36
)(
    input  wire                    clk,
    input  wire                    reset,

    // AXI4-Stream Slave (input)_INPUT img
    input  wire [AXI_HP_BIT-1:0]   S_AXIS_TDATA_0,
    input  wire                    S_AXIS_TVALID_0,
    input  wire                    S_AXIS_TLAST_0,
    output wire                    S_AXIS_TREADY_0,

    // AXI4-Stream Master (output)_INPUT img 
    output wire [AXI_HP_BIT-1:0]   M_AXIS_TDATA_0,
    output wire                    M_AXIS_TVALID_0,
    output wire                    M_AXIS_TLAST_0,
    input  wire                    M_AXIS_TREADY_0,
    
    // AXI4-Stream Slave (input)_WEIGHT
    input  wire [AXI_HP_BIT-1:0]   S_AXIS_TDATA_1,
    input  wire                    S_AXIS_TVALID_1,
    input  wire                    S_AXIS_TLAST_1,
    output wire                    S_AXIS_TREADY_1,

    // AXI4-Stream Master (output)_WEIGHT
    output wire [AXI_HP_BIT-1:0]   M_AXIS_TDATA_1,
    output wire                    M_AXIS_TVALID_1,
    output wire                    M_AXIS_TLAST_1,
    input  wire                    M_AXIS_TREADY_1,
    
    // BRAM B Port interface (only read)
    output wire [31:0]             bram_addrb,
    output wire [63:0]             bram_dinb,     //don't use
    input  wire [63:0]             bram_doutb,
    output wire                    bram_enb,
    output wire [7:0]              bram_web      //don't use
//    output wire                bram_rstb

//    output wire [AXI_HP_BIT-1:0] C_wr_data
//    output wire [DATA_WIDTH*6*6-1:0] in6_im2col_data,
//    output wire im2col_valid_in
);

// ========================================
// ------- Local Wires and Regs -----------
// ========================================
 
//============= Master_control ==============
    //strong clear
    wire clear;
    
    //input data
    wire in_wr_en;
    wire [ADDR_WIDTH:0] in_wr_addr;
    wire [AXI_HP_BIT-1:0] in_wr_data;
    wire [AXI_HP_BIT-1:0] in_rd_data;

    //weight data
    wire we_wr_en;
    wire [ADDR_WIDTH-1:0] we_wr_addr;
    wire [AXI_HP_BIT-1:0] we_wr_data;
    wire [AXI_HP_BIT-1:0] we_rd_data;   
    
    //output data
    wire out_rd_en;
    wire [ADDR_WIDTH-1:0] out_rd_addr; 
       
//============= Convolution ==============
    //output bram
    wire C_wr_en;
    wire [ADDR_WIDTH-1:0] C_wr_addr;
    wire [AXI_HP_BIT-1:0] C_wr_data; 
    //conv start/done/wait signal
    wire conv_en, conv_done;
    wire conv_WAIT, conv_GO;
    wire last_im2col;         //im2col to debug
    
//============ conv1_control =============    
    wire conv1_en,conv1_done;
    //input, weight bram
    wire C1_in_rd_en;  
    wire C1_we_rd_en;
    wire [ADDR_WIDTH:0] C1_in_rd_addr;
    wire [ADDR_WIDTH-1:0] C1_we_rd_addr;
    //output bram
    wire C1_wr_en;
    wire [ADDR_WIDTH-1:0] C1_wr_addr;
    wire [AXI_HP_BIT-1:0] C1_wr_data; 
    
//=============== im2col ================
    //input_rd_control
    wire i_rd_start;
    //input, weight bram
    wire C_in_rd_en;  
    wire C_we_rd_en;
    wire [ADDR_WIDTH:0] C_in_rd_addr;
    wire [ADDR_WIDTH-1:0] C_we_rd_addr;
    //start to send im2ol data
    wire im2col_valid_in, im2col_valid_we; //to announce im2col data valid
    wire [DATA_WIDTH*6*6-1:0] in6_im2col_data, we6_im2col_data; //1x36 im2col data
//    wire im2col_valid_we; //to announce im2col data valid
//    wire [DATA_WIDTH*6*6-1:0] we6_im2col_data; //1x36 im2col data



    wire [DATA_WIDTH*3*3-1:0] in3_im2col_data, we3_im2col_data; //1x36 im2col data
    // clear input_rd_control
    wire in_rd_clear, we_rd_clear; 
    //stop signal to im2col module
    wire image_pause, weight_pause; //stop im2col
    
//============= slice matrix ==============
    //start to read matrix data
    wire image_read, weight_read; 
    wire [COLUMN_WIDTH*DATA_WIDTH-1:0] image_data;
    wire [ROW_WIDTH*COLUMN_WIDTH*DATA_WIDTH-1:0] weight_data;
    wire image_valid;
    wire weight_valid;
    //delete im2col buffer
    wire im_valid_del, we_valid_del; 

//=============== Maxpooling ================
    //maxpooling start/done signal
    wire maxpooling_en, maxpooling_done;
    //input bram
    wire M_in_rd_en;
    wire [ADDR_WIDTH:0] M_in_rd_addr;
    //output bram
    wire M_wr_en;
    wire [ADDR_WIDTH-1:0] M_wr_addr;
    wire [AXI_HP_BIT-1:0] M_wr_data;
    
    
    
// ========================================
// ------------ Master control ------------
// ========================================

    master_control #(
        .AXI_HP_BIT        (AXI_HP_BIT),                                  
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH)
    ) control (
        .clk                 (clk),
        .reset               (reset),
        .clear               (clear),
        
        //INPUT img
        .S_AXIS_TDATA_0      (S_AXIS_TDATA_0),
        .S_AXIS_TVALID_0     (S_AXIS_TVALID_0),
        .S_AXIS_TLAST_0      (S_AXIS_TLAST_0), 
        .S_AXIS_TREADY_0     (S_AXIS_TREADY_0),
      
        .M_AXIS_TVALID_0     (M_AXIS_TVALID_0),        
        .M_AXIS_TLAST_0      (M_AXIS_TLAST_0),         
        .M_AXIS_TREADY_0     (M_AXIS_TREADY_0),
      
        //WEIGT
        .S_AXIS_TDATA_1      (S_AXIS_TDATA_1),
        .S_AXIS_TVALID_1     (S_AXIS_TVALID_1),
        .S_AXIS_TLAST_1      (S_AXIS_TLAST_1), 
        .S_AXIS_TREADY_1     (S_AXIS_TREADY_1),
      
//        .M_AXIS_TVALID_1   (),        
//        .M_AXIS_TLAST_1    (),         
//        .M_AXIS_TREADY_1   (),
        
        //MMIO BRAM READ
        .BRAM_ADDRB          (bram_addrb),
        .BRAM_DOUTB          (bram_doutb),
        .BRAM_ENB            (bram_enb),
        
        //OPCODE DATA  (CONV)
        .in_row              (bram_doutb[60:51]),  // data row length              
        .in_column           (bram_doutb[50:41]),  // data column length               
        .kernel              (bram_doutb[40:38]),  // kernel size                 
        .stride              (bram_doutb[37:36]),  // padding               
        .padding             (bram_doutb[35:34]),  // stride       
        .slice_cnt           (bram_doutb[33:32]),  // matrix tile count  
        .input_channel       (bram_doutb[31:20]),  // weight channel   
        .output_channel      (bram_doutb[19: 8]),  // weight channel 
              
        //INPUT BRAM WRITE 
        .in_wr_en            (in_wr_en),
        .in_wr_addr          (in_wr_addr),
        .in_wr_data          (in_wr_data),
        
        //WEIGHT BRAM WRITE 
        .we_wr_en            (we_wr_en),
        .we_wr_addr          (we_wr_addr),
        .we_wr_data          (we_wr_data),
        
        //CONVOLUTION(KERNEL1)
        .conv1_en            (conv1_en),
        .conv1_done          (conv1_done),
        
        //CONVOLUTION
        .conv_en             (conv_en),
        .conv_done           (conv_done),
        
        .conv_WAIT           (conv_WAIT),
        .conv_GO             (conv_GO),
        
        //MAXPOOLING
        .maxpooling_en       (maxpooling_en),
        .maxpooling_done     (maxpooling_done),
        
        //OUTPUT BRAM READ 
        .out_rd_en           (out_rd_en),
        .out_rd_addr         (out_rd_addr)
    );

// =========================================
// ----------- BRAM DATA(INPUT) ------------
// =========================================

    in_Mem #(                                     // input data memory     
        .AXI_HP_BIT          (AXI_HP_BIT),                                  
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH)
    ) input_Mem (
        .clk                 (clk),           
        
        .OPCODE              (bram_doutb[63:61]),  // data row length      
             
        .wr_en               (in_wr_en),               
        .wr_addr             (in_wr_addr),       
        .wr_data             (in_wr_data),   
           
        //convolution   
        .C_rd_en             (C_in_rd_en),  
        .C_rd_addr           (C_in_rd_addr), 
        
        //convolution(kernel1)   
        .C1_rd_en            (C1_in_rd_en),  
        .C1_rd_addr          (C1_in_rd_addr),
         
        //maxpooling
        .M_rd_en             (M_in_rd_en),  
        .M_rd_addr           (M_in_rd_addr), 
        
        .rd_data             (in_rd_data) 
    );
    
    we_Mem #(                               // weight data memory     
        .AXI_HP_BIT          (AXI_HP_BIT),
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH)         
    ) weight_Mem (
        .clk                 (clk),           
        
        .OPCODE              (bram_doutb[63:61]),  // data row length      
             
        .wr_en               (we_wr_en),               
        .wr_addr             (we_wr_addr),       
        .wr_data             (we_wr_data),   
           
        //convolution   
        .C_rd_en             (C_we_rd_en),  
        .C_rd_addr           (C_we_rd_addr), 
        
        //convolution(kernel1)
        .C1_rd_en            (C1_we_rd_en),  
        .C1_rd_addr          (C1_we_rd_addr), 
        
        .rd_data             (we_rd_data) 
    );

// =========================================
// ------------- CONVOLUTION ---------------
// =========================================
    
    conv_control #(
        .AXI_HP_BIT          (AXI_HP_BIT),                                  
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ROW_WIDTH           (ROW_WIDTH),
        .COLUMN_WIDTH        (COLUMN_WIDTH),
        .MAC_WIDTH           (MAC_WIDTH),
        .OUT_WIDTH           (OUT_WIDTH)
    ) conv_control (
        .clk                 (clk),
        .reset               (reset),
        .sudo_reset          (clear),
    
        .conv_en             (conv_en),
        .conv_done           (conv_done),
        .conv_wait           (conv_WAIT),
        .conv_go             (conv_GO),

        //OPCODE DATA  (CONV)
        .in_row              (bram_doutb[60:51]),  // data row length              
        .in_column           (bram_doutb[50:41]),  // data column length               
        .kernel              (bram_doutb[40:38]),  // kernel size                 
        .stride              (bram_doutb[37:36]),  // padding               
        .padding             (bram_doutb[35:34]),  // stride       
        .slice_cnt           (bram_doutb[33:32]),  // matrix tile count  
        .input_channel       (bram_doutb[31:20]),  // weight channel   
        .output_channel      (bram_doutb[19: 8]),  // weight channel 
        
        //control im2col module
        .image_pause         (image_pause),    //stop im2col
        .weight_pause        (weight_pause),
        .im2col_valid_in     (im2col_valid_in), //to know im2col data valid
        .im2col_valid_we     (im2col_valid_we),
        .in_rd_clear         (in_rd_clear), 
        .we_rd_clear         (we_rd_clear), 
        .im_valid_del        (im_valid_del),
        .we_valid_del        (we_valid_del),
        
        
//        start to slicing 4x4 matrix
        .image_read          (image_read),
        .weight_read         (weight_read),
        
//        data fome slice matrix
        .image_data          (image_data),
        .weight_data         (weight_data),
        .image_valid         (image_valid),
        .weight_valid        (weight_valid),
        
        //OUTPUT BRAM WRITE
        .out_wr_en           (C_wr_en),
        .out_wr_addr         (C_wr_addr),
        .out_wr_data         (C_wr_data)
    );

    conv_1_control #(
        .AXI_HP_BIT          (AXI_HP_BIT),                                  
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ROW_WIDTH           (ROW_WIDTH),
        .COLUMN_WIDTH        (COLUMN_WIDTH),
        .MAC_WIDTH           (MAC_WIDTH),
        .OUT_WIDTH           (OUT_WIDTH)
    ) conv_1_control (
        .clk                 (clk),
        .reset               (reset),
        .sudo_reset          (clear),
        
        .conv1_en             (conv1_en),
        .conv1_done           (conv1_done),

        //OPCODE DATA  (CONV)
        .in_row              (bram_doutb[60:51]),  // data row length              
        .in_column           (bram_doutb[50:41]),  // data column length                           
        .input_channel       (bram_doutb[31:20]),  // weight channel   
        .output_channel      (bram_doutb[19: 8]),  // weight channel 
        
        //INPUT BRAM READ
        .in_rd_en            (C1_in_rd_en),
        .in_rd_addr          (C1_in_rd_addr),
        .in_rd_data          (in_rd_data),
        
        //WEIGHT BRAM READ
        .we_rd_en            (C1_we_rd_en),
        .we_rd_addr          (C1_we_rd_addr),
        .we_rd_data          (we_rd_data),
        
        //OUTPUT BRAM WRITE
        .out_wr_en           (C1_wr_en),
        .out_wr_addr         (C1_wr_addr),
        .out_wr_data         (C1_wr_data)
    );


    i_slice #(                               
        .DATA_WIDTH          (DATA_WIDTH),
        .ROW_WIDTH           (ROW_WIDTH),
        .COLUMN_WIDTH        (COLUMN_WIDTH)
    ) i_slice (
        .clk                 (clk),
        .reset               (reset),
        .clear               (in_rd_clear),
        .sudo_reset          (clear),
        
        .conv_en             (conv_en),
        
        .kernel              (bram_doutb[40:38]),  // kernel size 
        
        //bring im2col data
        .im2col_valid        (im2col_valid_in),
        .in3_im2col_data     (in3_im2col_data),
        .in6_im2col_data     (in6_im2col_data),
        
//        start to slicing
        .image_read          (image_read),
        .image_data          (image_data),
        .image_valid         (image_valid),
        
        .im_done             (),
        .im_valid_del        (im_valid_del)
    );
    
    w_slice #(                                 
        .DATA_WIDTH          (DATA_WIDTH),
        .ROW_WIDTH           (ROW_WIDTH),
        .COLUMN_WIDTH        (COLUMN_WIDTH)
    ) w_slice (
        .clk                 (clk),
        .reset               (reset),
        .sudo_reset          (clear),
        .conv_en             (conv_en),
        
        .kernel              (bram_doutb[40:38]),  // kernel size 
        
        //bring im2col data  
        .we_im2col_valid     (im2col_valid_we),
        .we3_im2col_data     (we3_im2col_data),
        .we6_im2col_data     (we6_im2col_data),
        
//        start to slicing
        .weight_read         (weight_read),
        .weight_data         (weight_data),
        .weight_valid        (weight_valid),
        
        .we_done             (),
        .we_valid_del        (we_valid_del)
    );



    i_read_control U1(
        .clk                 (clk),
        .reset               (reset),
        .clear               (in_rd_clear),
        .sudo_reset          (clear),   
        .i_valid             (conv_en),
        
        //OPCODE DATA  (CONV)
        .in_row_size         (bram_doutb[60:51]),  // data row length              
        .in_column_size      (bram_doutb[50:41]),  // data column length               
        .kernel              (bram_doutb[40:38]),  // kernel size                 
        .stride              (bram_doutb[37:36]),  // padding               
        .padding             (bram_doutb[35:34]),  // stride       
        .case_N              (bram_doutb[33:32]),  // matrix tile count  
        .channel             (bram_doutb[31:20]),  // weight channel   
//        .output_channel      (bram_doutb[19: 8]),  // weight channel 
        
        .o_final             (),  //last data
        .o_stage             (),   //location 
        
        //input_rd_control <---> im2col    
        .i_start             (i_rd_start),            // im2col send ready signal to rd_input_control         
        .o_valid             (C_in_rd_en),           // output address enable signal      
        .o_addr              (C_in_rd_addr)          // output address            
    );
    
    
    i_im2col #(
        .AXI_HP_BIT        (AXI_HP_BIT),                                  
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH)
    ) i_im2col (
        .clk                 (clk),
        .reset               (reset),
        .conv_en             (conv_en),
        .in_rd_clear         (in_rd_clear),
        .sudo_reset          (clear),
        
        //OPCODE DATA  (CONV)
        .in_row              (bram_doutb[60:51]),  // data row length              
        .in_column           (bram_doutb[50:41]),  // data column length               
        .kernel              (bram_doutb[40:38]),  // kernel size                 
        .stride              (bram_doutb[37:36]),  // padding               
        .padding             (bram_doutb[35:34]),  // stride       
        .slice_cnt           (bram_doutb[33:32]),  // matrix tile count  
        .input_channel       (bram_doutb[31:20]),  // weight channel   
        .output_channel      (bram_doutb[19: 8]),  // weight channel 
    
        //INPUT DATA IN
        .i_rd_start          (i_rd_start),
        .in_rd_en            (C_in_rd_en), 
        .in_rd_data          (in_rd_data),         
    
        //data inout enable signal im2col <---> data slice
        .last_im2col         (last_im2col),
        .image_pause         (image_pause),      //stop im2col
        .im2col_valid        (im2col_valid_in),     //can send im2col -------------- testbench B
        
        //IM2COL INPUT DATA OUT
        .in3_im2col_data     (),      //1, 3, 6 kernel OUTPUT  -------------- testbench A
        .in6_im2col_data     (in6_im2col_data)      //1, 3, 6 kernel OUTPUT  -------------- testbench A
    );
  
    
    w_im2col #(
        .AXI_HP_BIT          (AXI_HP_BIT),                                  
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH)
    ) w_im2col (
        .clk                 (clk),
        .reset               (reset),
        .conv_en             (conv_en),
        .sudo_reset          (clear),
        
        //OPCODE DATA  (CONV)
        .in_row              (bram_doutb[60:51]),  // data row length              
        .in_column           (bram_doutb[50:41]),  // data column length               
        .kernel              (bram_doutb[40:38]),  // kernel size                 
        .stride              (bram_doutb[37:36]),  // padding               
        .padding             (bram_doutb[35:34]),  // stride       
        .slice_cnt           (bram_doutb[33:32]),  // matrix tile count  
        .input_channel       (bram_doutb[31:20]),  // weight channel   
        .output_channel      (bram_doutb[19: 8]),  // weight channel 
    
        //WEIGHT DATA IN
        .we_rd_en            (C_we_rd_en),             //give valid input data to im2col
        .we_rd_addr          (C_we_rd_addr),           //get ready to recieve input data
        .we_rd_data          (we_rd_data),         
    
        //data inout enable signal im2col <---> data slice
        .weight_pause        (weight_pause),      //stop im2col
        .we_im2col_valid     (im2col_valid_we),     //can send im2col -------------- testbench B
        
        //IM2COL WEIGHT DATA OUT
        .we3_im2col_data     (),      //1, 3, 6 kernel OUTPUT  -------------- testbench A
        .we6_im2col_data     (we6_im2col_data)      //1, 3, 6 kernel OUTPUT  -------------- testbench A
    );
    
     



// =========================================
// -------------- MAXPOOLING ---------------
// =========================================
    
    
    
    
// =========================================
// ---------- BRAM DATA(OUTPUT) ------------
// =========================================
 
    out_Mem #(                             // output data memory     
        .AXI_HP_BIT          (AXI_HP_BIT),
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH)         
    ) output_Mem (
        .clk                 (clk),            
        .OPCODE              (bram_doutb[63:61]),  // data row length      
       
        .out_rd_en           (out_rd_en),         
        .out_rd_addr         (out_rd_addr),
        
        //CONVOLUTION
        .C_wr_en             (C_wr_en),  
        .C_wr_addr           (C_wr_addr),  
        .C_wr_data           (C_wr_data),  
        
        //CONVOLUTION
        .C1_wr_en            (C1_wr_en),  
        .C1_wr_addr          (C1_wr_addr),  
        .C1_wr_data          (C1_wr_data),  
        //MAXPOOL data
        .M_wr_en             (M_wr_en),
        .M_wr_addr           (M_wr_addr),
        .M_wr_data           (M_wr_data),  
        
        .rd_data             (M_AXIS_TDATA_0) 
    );



endmodule