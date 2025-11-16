`default_nettype none

module master_control #(
    parameter 
        AXI_HP_BIT = 64,        //HP port width
        DATA_WIDTH = 16,        //fixed point(Q7.9)
        ADDR_WIDTH = 14         //BRAM address width
)(
    input  wire                  clk,
    input  wire                  reset,
    output reg                   clear,

    // AXI4-Stream Slave (INPUT)_INPUT img
    input  wire [AXI_HP_BIT-1:0] S_AXIS_TDATA_0,
    input  wire                  S_AXIS_TVALID_0,
    input  wire                  S_AXIS_TLAST_0,
    output reg                   S_AXIS_TREADY_0,

    // AXI4-Stream Master (OUTPUT)_INPUT img
    output reg                   M_AXIS_TVALID_0,
    output reg                   M_AXIS_TLAST_0,
    input  wire                  M_AXIS_TREADY_0,
    
    // AXI4-Stream Slave (INPUT)_WEIGHT
    input  wire [AXI_HP_BIT-1:0] S_AXIS_TDATA_1,
    input  wire                  S_AXIS_TVALID_1,
    input  wire                  S_AXIS_TLAST_1,
    output reg                   S_AXIS_TREADY_1,

    // AXI4-Stream Master (OUTPUT)_WEIGHT
//    output reg                   M_AXIS_TVALID_1,
//    output reg                   M_AXIS_TLAST_1,
//    input  wire                  M_AXIS_TREADY_1,
    
    
    // MMIO BRAM READ
    output reg  [31:0]           BRAM_ADDRB,
    input  wire [63:0]           BRAM_DOUTB,
    output reg                   BRAM_ENB,
    
    //OPCODE data
    input wire  [9:0]            in_row,          //input row size
    input wire  [9:0]            in_column,       //input colunm size
    input wire  [2:0]            kernel,          //kernel size
    input wire  [1:0]            stride,          // padding size
    input wire  [1:0]            padding,         // stride size
    input wire  [1:0]            slice_cnt,       // tile count
    input wire  [11:0]           input_channel,  // input channel
    input wire  [11:0]           output_channel,  // input channel
    
    // INPUT BRAM WRITE
    output reg                   in_wr_en,  
    output reg  [ADDR_WIDTH:0] in_wr_addr,
    output reg  [AXI_HP_BIT-1:0] in_wr_data,          


    // WEIGHT BRAM WRITE
    output reg                   we_wr_en,  
    output reg  [ADDR_WIDTH-1:0] we_wr_addr,
    output reg  [AXI_HP_BIT-1:0] we_wr_data,
    
    
    //CONV (kernel 1) start/done
    output reg                   conv1_en,
    input  wire                  conv1_done,
       
    //CONV start/done
    output reg                   conv_en,
    input  wire                  conv_done,
    input  wire                  conv_WAIT,
    output reg                   conv_GO,
    
    //BN_RELU start/done
//    output reg                   BN_RELU_en,
//    input wire                   BN_RELU_done,
    
    
    //MAXPOOLING start/done
    output reg                   maxpooling_en,
    input  wire                  maxpooling_done,
    
    // OUTPUT BRAM READ
    output reg                   out_rd_en,  
    output reg  [ADDR_WIDTH-1:0] out_rd_addr
        
);


    localparam IDLE         = 0,
               STORE        = 1,    //store INPUT, WEIGHT data
               OPCODE       = 2,    //read bram data from MMIO
               DECIDE       = 3,    //choose where to go
               CONV1        = 4,    //not defined
               CONV         = 5,    
               BN_RELU      = 6,
               MAXPOOLING   = 8,
               UPSAMPLING   = 9,
               BIAS_CONV    = 10,
               SEND         = 11,
               LAST_SEND    = 12,
               SEND_WAIT    = 13,
               DONE         = 14;
               
    reg [4:0] state, n_state; 
    reg in_last_reg, we_last_reg;   //to control 2 DMA data timing
    reg [15:0] in_cnt, we_cnt;      //to write bram
    reg [15:0] op_cnt, out_cnt;     //to read MMIO/OUTPUT bram

    reg [1:0]  pad; 
    
    always @(*)begin   
        case(slice_cnt)
            2'b00: begin pad <= 0; end
            2'b01: begin pad <= 2; end
            2'b10: begin pad <= 0; end
            2'b11: begin pad <= 2; end
            default: begin pad <= 0; end
        endcase
    end   
                    
    
    wire [ADDR_WIDTH - 1:0] row_slicing, col_slicing, total_slicing, weight_slicing;  //convolution slicing
    //to count convolution matrix slicing
    assign row_slicing = (in_row + 2*padding - kernel)/2 + 1;         //640 x 32  ---> 320
    assign col_slicing = (in_column + pad - kernel)/2 + 1;        //640 x 32      ---> 15 (first tile)
    assign total_slicing = row_slicing * col_slicing;               //  4800 one channel
    
    always@(posedge clk, negedge reset)begin
        if(!reset) begin
            state <= IDLE;
        end else begin
            state <= n_state;
        end
    end
    
    always@(*)begin
        n_state = state;
        S_AXIS_TREADY_0 = 0;
        S_AXIS_TREADY_1 = 0;
        
        conv_en         = 0;
        conv_GO         = 0;
        
        maxpooling_en   = 0;

        
        M_AXIS_TVALID_0 = 0;
        M_AXIS_TLAST_0  = 0;

        case(state)
            IDLE: begin
                S_AXIS_TREADY_0 = 1;     //ready to recieve data  (INPUT)
                S_AXIS_TREADY_1 = 1;     //ready to recieve data  (WEIGHT)
                M_AXIS_TVALID_0 = 0;     //not ready to send data (OUTPUT)
                M_AXIS_TLAST_0  = 0;
                n_state = STORE;
                
                conv1_en        = 0;
                
                conv_en         = 0;
                conv_GO         = 0;
                
                maxpooling_en   = 0;

                
                M_AXIS_TVALID_0 = 0;
                M_AXIS_TLAST_0  = 0;
            end
            
            STORE: begin
                S_AXIS_TREADY_0 = 1;
                S_AXIS_TREADY_1 = 1;
                M_AXIS_TVALID_0 = 0;
                if(we_last_reg && in_last_reg)begin   //get tlast(INPUT, WEIGHT)
                    n_state = OPCODE;
                end
            end
            
            OPCODE: begin
                S_AXIS_TREADY_0 = 0;
                S_AXIS_TREADY_1 = 0;
                M_AXIS_TVALID_0 = 0;
                n_state = DECIDE;                          
            end
            
            DECIDE: begin
                case(BRAM_DOUTB[63:61])
                    3'b000: begin n_state = CONV1;      conv1_en = 1;      end
                    3'b001: begin n_state = CONV;       conv_en = 1;       end
                    3'b010: begin n_state = MAXPOOLING; maxpooling_en = 1; end
                    3'b011: begin                         end
                    3'b100: begin n_state = UPSAMPLING;   end
                    3'b101: begin n_state = BIAS_CONV;    end
                    default: n_state = DECIDE;
                endcase
            end
            
            CONV1:begin
                if (conv1_done)begin
                    n_state = LAST_SEND;
                end
            end
            
            CONV: begin
                S_AXIS_TREADY_0 = 0;
                S_AXIS_TREADY_1 = 0;
                conv_en         = 0; 
                conv_GO         = 0;
                maxpooling_en   = 1;    
                M_AXIS_TVALID_0 = 0;
                M_AXIS_TLAST_0  = 0;
            
                if(conv_WAIT)begin           //CONV done
                    n_state = SEND;
                end else if (conv_done)begin
                    n_state = LAST_SEND;
                end
            end
            

            
            MAXPOOLING: begin
                S_AXIS_TREADY_0 = 0;
                S_AXIS_TREADY_1 = 0;
                conv_en         = 0; 
                conv_GO         = 0;
                maxpooling_en   = 1;      
                M_AXIS_TVALID_0 = 0;
                M_AXIS_TLAST_0  = 0;
            
                if (maxpooling_done)begin
                    n_state = DONE;
                end
            end
            
            SEND: begin                           //If can't send all data
                if(kernel == 6)begin
                    if(out_cnt > 2)begin
                        M_AXIS_TVALID_0 = 1;         //ready to send data (OUTPUT)
                    end
                    if(out_cnt == total_slicing/4*10+2)begin
                        n_state = SEND_WAIT;
                        M_AXIS_TLAST_0 = 1;
                    end
                end
            end
            LAST_SEND: begin                     //last send
                if(out_cnt > 2)begin
                    M_AXIS_TVALID_0 = 1;         //ready to send data (OUTPUT)
                end
                if(BRAM_DOUTB[63:61] == 3'b000)begin    //convolution (kernel 1)
                    if(out_cnt == in_row*in_column*output_channel+2)begin
                        n_state = DONE;
                        M_AXIS_TLAST_0 = 1;
                    end
                end 
                else if(BRAM_DOUTB[63:61] == 3'b001)begin    //convolution
                    if(out_cnt == total_slicing/4*10+2)begin
                        n_state = DONE;
                        M_AXIS_TLAST_0 = 1;
                    end
                end
            end
            SEND_WAIT:begin
                M_AXIS_TVALID_0 = 0;
                M_AXIS_TLAST_0 = 0;
                
                conv_GO = 1;              
                n_state = CONV;

//                if(CONV_done)begin
//                    n_state = DONE;
//                end    
            end
              
           
            DONE: begin
                M_AXIS_TVALID_0 = 0;
                M_AXIS_TLAST_0  = 0;
//                CONV_GO = 1;
                n_state = STORE;
            end
            
            default: n_state = IDLE;
        endcase
    end


    always@(posedge clk, negedge reset)begin
        if(!reset)begin
            
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //Send DATA with DMA
//            M_AXIS_TVALID_0 <= 0;
//            M_AXIS_TLAST_0  <= 0;
//            M_AXIS_TVALID_1 <= 0;
//            M_AXIS_TLAST_1  <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
            
            //MMIO BRAM READ
            BRAM_ADDRB      <= 0;
            BRAM_ENB        <= 0;
            op_cnt          <= 0;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
            
            clear           <= 0;
    
        end
        else if(state == IDLE)begin
            
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //Send DATA with DMA
//            M_AXIS_TVALID_0 <= 0;
//            M_AXIS_TLAST_0  <= 0;
//            M_AXIS_TVALID_1 <= 0;
//            M_AXIS_TLAST_1  <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
            
            //MMIO BRAM READ
            BRAM_ADDRB      <= 0;
            BRAM_ENB        <= 0;
            op_cnt          <= 0;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
            
            clear           <= 0;
   
        end
        else if(state == STORE)begin
            //Send DATA with DMA
//            M_AXIS_TVALID_0 <= 0;
//            M_AXIS_TLAST_0  <= 0;
//            M_AXIS_TVALID_1 <= 0;
//            M_AXIS_TLAST_1  <= 0;
            
            //MMIO BRAM READ
            BRAM_ADDRB      <= 0;
            BRAM_ENB        <= 0;
            op_cnt          <= op_cnt;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
            clear           <= 0;
            if(S_AXIS_TVALID_0 && S_AXIS_TREADY_0)begin            //STORE INPUT DATA
                in_wr_en        <=  1;
                in_wr_addr      <=  in_cnt;
                in_wr_data      <=  S_AXIS_TDATA_0;
                in_cnt          <=  in_cnt + 1;
            end 
            if(S_AXIS_TLAST_0 && S_AXIS_TREADY_0)begin    //recieve last data
                in_last_reg     <=  1;
            end
            
            if(S_AXIS_TVALID_1 && S_AXIS_TREADY_1)begin            //STORE WEIGHT DATA
                we_wr_en        <=  1;
                we_wr_addr      <=  we_cnt;
                we_wr_data      <=  S_AXIS_TDATA_1;
                we_cnt          <=  we_cnt + 1;
            end 
            if(S_AXIS_TLAST_1 && S_AXIS_TREADY_1)begin   //recieve last data
                we_last_reg     <=  1;
            end

        end
        else if(state == OPCODE)begin
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
           
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
        
            BRAM_ENB        <=  1;                                //Read OPCODE
            BRAM_ADDRB      <=  op_cnt;      
        end
        else if(state == CONV)begin
                out_rd_en   <= 0;
                out_cnt <= 0;
                out_rd_addr <= 0;
        end
        else if(state == BN_RELU)begin
                out_rd_en   <= 0;
                out_cnt <= 0;
                out_rd_addr <= 0;
        end

        else if(state == SEND)begin
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;

            if(out_cnt == total_slicing/4*10+2)begin
                out_cnt <=  out_cnt;
            end 
            else if(M_AXIS_TREADY_0)begin
                out_rd_en       <=  1;
                out_rd_addr     <=  out_cnt;
                out_cnt         <=  out_cnt + 1;
            end 
        end
        else if(state == LAST_SEND)begin
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
            if(BRAM_DOUTB[63:61] == 3'b000)begin       //CONVOLUTION(kernel1)
                if(out_cnt == in_row*in_column*output_channel+2)begin
                    out_cnt <=  out_cnt;
                end 
                else if(M_AXIS_TREADY_0)begin
                    out_rd_en       <=  1;
                    out_rd_addr     <=  out_cnt;
                    out_cnt         <=  out_cnt + 1;
                end
            end else if(BRAM_DOUTB[63:61] == 3'b001)begin       //CONVOLUTION
                if(out_cnt == total_slicing/4*10+2)begin
                    out_cnt <=  out_cnt;
                end 
                else if(M_AXIS_TREADY_0)begin
                    out_rd_en       <=  1;
                    out_rd_addr     <=  out_cnt;
                    out_cnt         <=  out_cnt + 1;
                end
            end
        end
        else if(state == SEND_WAIT)begin
                
//            TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
            
            //MMIO BRAM READ
            BRAM_ADDRB      <= 0;
            BRAM_ENB        <= 0;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
        end
        else if(state == DONE)begin
          
            //TLAST signal 
            in_last_reg     <= 0;
            we_last_reg     <= 0;
            
            //Send DATA with DMA
//            M_AXIS_TVALID_0 <= 0;
//            M_AXIS_TLAST_0  <= 0;
//            M_AXIS_TVALID_1 <= 0;
//            M_AXIS_TLAST_1  <= 0;
            
            //INPUT bram write
            in_wr_en        <= 0;  
            in_wr_addr      <= 0;
            in_wr_data      <= 0;           
            in_cnt          <= 0;
            
            //WEIGHT bram write   
            we_wr_en        <= 0;  
            we_wr_addr      <= 0;
            we_wr_data      <= 0;
            we_cnt          <= 0;
            
            //MMIO BRAM READ
            BRAM_ADDRB      <= 0;
            BRAM_ENB        <= 0;
            op_cnt          <= op_cnt + 8;
    
            //OUTPUT BRAM read
            out_rd_en       <= 0;
            out_rd_addr     <= 0;
            out_cnt         <= 0;
            
            clear           <= 1;
        end
        
    end
        
    

endmodule