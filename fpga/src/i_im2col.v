`default_nettype none

module i_im2col #(
    parameter 
        AXI_HP_BIT = 64,       //HP port width
        DATA_WIDTH = 16,       //fixed point(Q7.9)
        ROW_WIDTH  = 4,        //matrix 4x4
        ADDR_WIDTH = 14        //BRAM address width
)(
    input wire                             clk,
    input wire                             reset,
    input wire                             conv_en,
    input wire                             in_rd_clear,
    input wire                             sudo_reset,
    
    //OPCODE data
    input wire  [9:0]                      in_row,          //input row size    : 640
    input wire  [9:0]                      in_column,       //input colunm size : 32
    input wire  [2:0]                      kernel,          //kernel size       : 6
    input wire  [1:0]                      stride,          // padding size     : 2
    input wire  [1:0]                      padding,         // stride size      : 2
    input wire  [1:0]                      slice_cnt,       // tile count       : 0 - first tile, 1 - middle tile, 2 - last tile
    input wire  [11:0]                     input_channel,   //input channel     ; 1 layer - 3
    input wire  [11:0]                     output_channel,  //output channel    : 1 layer - 80

    //INPUT DATA IN
    output reg                             i_rd_start,    
    input wire                             in_rd_en,
    input wire [AXI_HP_BIT - 1:0]          in_rd_data,         

    //IM2COL related signal
    input wire                             image_pause,      //stop im2col       1: stop  0: keep going
    output reg                             last_im2col,      //send last data   to debug
    output reg                             im2col_valid,     //can send im2col 
    
    //IM2COL DATA OUT
    output reg [DATA_WIDTH * 9 - 1:0]      in3_im2col_data,  //3 kernel OUTPUT 
    output reg [DATA_WIDTH * 36- 1:0]      in6_im2col_data   // 16bit x 6kernel x 6kernel x RGB
);

    localparam IDLE       = 0,
               DECIDE     = 1,
               KERNEL6    = 2,
               KERNEL3    = 3,
               K6_IM2COL  = 4,
               K3_IM2COL  = 5,
               SEND       = 6, 
               DONE       = 7;
                              
    reg [3:0] state, n_state;   

    reg [1:0]  padd; 
    
    always @(*)begin   
        case(slice_cnt)
            2'b00: begin padd <= 0; end
            2'b01: begin padd <= 2; end
            2'b10: begin padd <= 0; end
            2'b11: begin padd <= 2; end
            default: begin padd <= 0; end
        endcase
    end   
    
    wire [ADDR_WIDTH - 1:0] row_slicing, col_slicing, total_slicing, weight_slicing;  //convolution slicing
    //to count convolution matrix slicing
    assign row_slicing = (in_row + 2*padding - kernel)/2 + 1;         //640 x 32  ---> 320
    assign col_slicing = (in_column + padd - kernel)/2 + 1;        //640 x 32      ---> 15 (first tile)
    assign total_slicing = row_slicing * col_slicing;               //  4800 one channel
               
    reg [63:0] buffer [0:119];    
    reg [7:0] buf_cnt, addr_cnt;
    reg buf_active;
    reg [8:0] in_column_cnt, in_row_cnt; 
    reg [3:0] send_cnt;
    reg ready_im2col, done_im2col, r_done_im2col;     //                    
    reg [11:0] chennal_cnt;
    
    wire [15:0] pad;
    assign pad = 16'd0;
              
    always @(posedge clk or negedge reset) begin                                                               
        if (!reset) begin                                                                                      
            state <= IDLE;                                                                                   
        end 
        else if(sudo_reset)begin 
            state <= IDLE;   
        end
        else if(in_rd_clear)begin                                                                                       
            state <= DECIDE;                                                                                
        end else begin
            state <= n_state;  
        end                                                                                                 
    end   
    
    always@(*)begin
        n_state    = state;   
        i_rd_start = 0;
        
        case(state)
            IDLE: begin
                if(conv_en)begin
                    n_state = DECIDE;
                end
            end
            DECIDE: begin
                case(kernel)
                    3'b110: begin n_state = KERNEL6; i_rd_start = 1;  end   //   Kernel:6  Stride:2  Padding:2
                    3'b011: begin n_state = KERNEL3; i_rd_start = 1;  end   //   Kernel:3  Stride:2  Padding:1
                    default: n_state = DECIDE;
                endcase
            end
            
            KERNEL6: begin
            
                if(ready_im2col)begin
                    n_state = K6_IM2COL;
                end
            end

            K6_IM2COL: begin
            
                if(done_im2col)begin
                    n_state    = KERNEL6;
                    i_rd_start = 1;
                end
            end     
                   
            KERNEL3: begin
            
                if(ready_im2col)begin
                    n_state = K3_IM2COL;
                end
            end

            K3_IM2COL: begin
            
                if(done_im2col)begin
                    n_state    = KERNEL3;
                    i_rd_start = 1;
                end
            end     
            DONE:begin
                n_state = IDLE;
            end
        endcase
    end  

    always@(posedge clk or negedge reset)begin
        if(!reset)begin
        
            im2col_valid      <= 0;
            in3_im2col_data   <= 0;
            in6_im2col_data   <= 0;
            
            ready_im2col      <= 0;
            done_im2col       <= 0;
            r_done_im2col     <= 0;
              
            buffer[0]  <= 0;  buffer[1]  <= 0;  buffer[2]  <= 0;  buffer[3]  <= 0;  buffer[4]  <= 0;  buffer[5]  <= 0;  buffer[6]  <= 0;  buffer[7]  <= 0;  buffer[8]  <= 0;  buffer[9]  <= 0;
            buffer[10] <= 0;  buffer[11] <= 0;  buffer[12] <= 0;  buffer[13] <= 0;  buffer[14] <= 0;  buffer[15] <= 0;  buffer[16] <= 0;  buffer[17] <= 0;  buffer[18] <= 0;  buffer[19] <= 0;
            buffer[20] <= 0;  buffer[21] <= 0;  buffer[22] <= 0;  buffer[23] <= 0;  buffer[24] <= 0;  buffer[25] <= 0;  buffer[26] <= 0;  buffer[27] <= 0;  buffer[28] <= 0;  buffer[29] <= 0;
            buffer[30] <= 0;  buffer[31] <= 0;  buffer[32] <= 0;  buffer[33] <= 0;  buffer[34] <= 0;  buffer[35] <= 0;  buffer[36] <= 0;  buffer[37] <= 0;  buffer[38] <= 0;  buffer[39] <= 0;
            buffer[40] <= 0;  buffer[41] <= 0;  buffer[42] <= 0;  buffer[43] <= 0;  buffer[44] <= 0;  buffer[45] <= 0;  buffer[46] <= 0;  buffer[47] <= 0;  buffer[48] <= 0;  buffer[49] <= 0;
            buffer[50] <= 0;  buffer[51] <= 0;  buffer[52] <= 0;  buffer[53] <= 0;  buffer[54] <= 0;  buffer[55] <= 0;  buffer[56] <= 0;  buffer[57] <= 0;  buffer[58] <= 0;  buffer[59] <= 0;
            buffer[60] <= 0;  buffer[61] <= 0;  buffer[62] <= 0;  buffer[63] <= 0;  buffer[64] <= 0;  buffer[65] <= 0;  buffer[66] <= 0;  buffer[67] <= 0;  buffer[68] <= 0;  buffer[69] <= 0;
            buffer[70] <= 0;  buffer[71] <= 0;  buffer[72] <= 0;  buffer[73] <= 0;  buffer[74] <= 0;  buffer[75] <= 0;  buffer[76] <= 0;  buffer[77] <= 0;  buffer[78] <= 0;  buffer[79] <= 0;
            buffer[80] <= 0;  buffer[81] <= 0;  buffer[82] <= 0;  buffer[83] <= 0;  buffer[84] <= 0;  buffer[85] <= 0;  buffer[86] <= 0;  buffer[87] <= 0;  buffer[88] <= 0;  buffer[89] <= 0;
            buffer[90] <= 0;  buffer[91] <= 0;  buffer[92] <= 0;  buffer[93] <= 0;  buffer[94] <= 0;  buffer[95] <= 0;  buffer[96] <= 0;  buffer[97] <= 0;  buffer[98] <= 0;  buffer[99] <= 0;
            buffer[100] <= 0; buffer[101] <= 0; buffer[102] <= 0; buffer[103] <= 0; buffer[104] <= 0; buffer[105] <= 0; buffer[106] <= 0; buffer[107] <= 0; buffer[108] <= 0; buffer[109] <= 0;
            buffer[110] <= 0; buffer[111] <= 0; buffer[112] <= 0; buffer[113] <= 0; buffer[114] <= 0; buffer[115] <= 0; buffer[116] <= 0; buffer[117] <= 0; buffer[118] <= 0; buffer[119] <= 0;
   
            buf_cnt           <= 0;  
            buf_active        <= 0;  
            in_column_cnt     <= 0; 
            in_row_cnt        <= 0; 
            addr_cnt          <= 0;
            send_cnt          <= 0;
            chennal_cnt       <= 0;
        end 
        else if(sudo_reset||in_rd_clear)begin 
        
        
            im2col_valid      <= 0;
            in3_im2col_data   <= 0;
            in6_im2col_data   <= 0;
            
            ready_im2col      <= 0;
            done_im2col       <= 0;
            r_done_im2col     <= 0;
              
            buffer[0]  <= 0;  buffer[1]  <= 0;  buffer[2]  <= 0;  buffer[3]  <= 0;  buffer[4]  <= 0;  buffer[5]  <= 0;  buffer[6]  <= 0;  buffer[7]  <= 0;  buffer[8]  <= 0;  buffer[9]  <= 0;
            buffer[10] <= 0;  buffer[11] <= 0;  buffer[12] <= 0;  buffer[13] <= 0;  buffer[14] <= 0;  buffer[15] <= 0;  buffer[16] <= 0;  buffer[17] <= 0;  buffer[18] <= 0;  buffer[19] <= 0;
            buffer[20] <= 0;  buffer[21] <= 0;  buffer[22] <= 0;  buffer[23] <= 0;  buffer[24] <= 0;  buffer[25] <= 0;  buffer[26] <= 0;  buffer[27] <= 0;  buffer[28] <= 0;  buffer[29] <= 0;
            buffer[30] <= 0;  buffer[31] <= 0;  buffer[32] <= 0;  buffer[33] <= 0;  buffer[34] <= 0;  buffer[35] <= 0;  buffer[36] <= 0;  buffer[37] <= 0;  buffer[38] <= 0;  buffer[39] <= 0;
            buffer[40] <= 0;  buffer[41] <= 0;  buffer[42] <= 0;  buffer[43] <= 0;  buffer[44] <= 0;  buffer[45] <= 0;  buffer[46] <= 0;  buffer[47] <= 0;  buffer[48] <= 0;  buffer[49] <= 0;
            buffer[50] <= 0;  buffer[51] <= 0;  buffer[52] <= 0;  buffer[53] <= 0;  buffer[54] <= 0;  buffer[55] <= 0;  buffer[56] <= 0;  buffer[57] <= 0;  buffer[58] <= 0;  buffer[59] <= 0;
            buffer[60] <= 0;  buffer[61] <= 0;  buffer[62] <= 0;  buffer[63] <= 0;  buffer[64] <= 0;  buffer[65] <= 0;  buffer[66] <= 0;  buffer[67] <= 0;  buffer[68] <= 0;  buffer[69] <= 0;
            buffer[70] <= 0;  buffer[71] <= 0;  buffer[72] <= 0;  buffer[73] <= 0;  buffer[74] <= 0;  buffer[75] <= 0;  buffer[76] <= 0;  buffer[77] <= 0;  buffer[78] <= 0;  buffer[79] <= 0;
            buffer[80] <= 0;  buffer[81] <= 0;  buffer[82] <= 0;  buffer[83] <= 0;  buffer[84] <= 0;  buffer[85] <= 0;  buffer[86] <= 0;  buffer[87] <= 0;  buffer[88] <= 0;  buffer[89] <= 0;
            buffer[90] <= 0;  buffer[91] <= 0;  buffer[92] <= 0;  buffer[93] <= 0;  buffer[94] <= 0;  buffer[95] <= 0;  buffer[96] <= 0;  buffer[97] <= 0;  buffer[98] <= 0;  buffer[99] <= 0;
            buffer[100] <= 0; buffer[101] <= 0; buffer[102] <= 0; buffer[103] <= 0; buffer[104] <= 0; buffer[105] <= 0; buffer[106] <= 0; buffer[107] <= 0; buffer[108] <= 0; buffer[109] <= 0;
            buffer[110] <= 0; buffer[111] <= 0; buffer[112] <= 0; buffer[113] <= 0; buffer[114] <= 0; buffer[115] <= 0; buffer[116] <= 0; buffer[117] <= 0; buffer[118] <= 0; buffer[119] <= 0;
   
            buf_cnt           <= 0;  
            buf_active        <= 0;  
            in_column_cnt     <= 0; 
            in_row_cnt        <= 0; 
            addr_cnt          <= 0;
            send_cnt          <= 0;
            chennal_cnt       <= 0;
        
        end       
        else if(state == IDLE)begin
        
            im2col_valid      <= 0;
            in3_im2col_data   <= 0;
            in6_im2col_data   <= 0;
            
            ready_im2col      <= 0;
            done_im2col       <= 0;
            r_done_im2col     <= 0;
              
            buffer[0]  <= 0;  buffer[1]  <= 0;  buffer[2]  <= 0;  buffer[3]  <= 0;  buffer[4]  <= 0;  buffer[5]  <= 0;  buffer[6]  <= 0;  buffer[7]  <= 0;  buffer[8]  <= 0;  buffer[9]  <= 0;
            buffer[10] <= 0;  buffer[11] <= 0;  buffer[12] <= 0;  buffer[13] <= 0;  buffer[14] <= 0;  buffer[15] <= 0;  buffer[16] <= 0;  buffer[17] <= 0;  buffer[18] <= 0;  buffer[19] <= 0;
            buffer[20] <= 0;  buffer[21] <= 0;  buffer[22] <= 0;  buffer[23] <= 0;  buffer[24] <= 0;  buffer[25] <= 0;  buffer[26] <= 0;  buffer[27] <= 0;  buffer[28] <= 0;  buffer[29] <= 0;
            buffer[30] <= 0;  buffer[31] <= 0;  buffer[32] <= 0;  buffer[33] <= 0;  buffer[34] <= 0;  buffer[35] <= 0;  buffer[36] <= 0;  buffer[37] <= 0;  buffer[38] <= 0;  buffer[39] <= 0;
            buffer[40] <= 0;  buffer[41] <= 0;  buffer[42] <= 0;  buffer[43] <= 0;  buffer[44] <= 0;  buffer[45] <= 0;  buffer[46] <= 0;  buffer[47] <= 0;  buffer[48] <= 0;  buffer[49] <= 0;
            buffer[50] <= 0;  buffer[51] <= 0;  buffer[52] <= 0;  buffer[53] <= 0;  buffer[54] <= 0;  buffer[55] <= 0;  buffer[56] <= 0;  buffer[57] <= 0;  buffer[58] <= 0;  buffer[59] <= 0;
            buffer[60] <= 0;  buffer[61] <= 0;  buffer[62] <= 0;  buffer[63] <= 0;  buffer[64] <= 0;  buffer[65] <= 0;  buffer[66] <= 0;  buffer[67] <= 0;  buffer[68] <= 0;  buffer[69] <= 0;
            buffer[70] <= 0;  buffer[71] <= 0;  buffer[72] <= 0;  buffer[73] <= 0;  buffer[74] <= 0;  buffer[75] <= 0;  buffer[76] <= 0;  buffer[77] <= 0;  buffer[78] <= 0;  buffer[79] <= 0;
            buffer[80] <= 0;  buffer[81] <= 0;  buffer[82] <= 0;  buffer[83] <= 0;  buffer[84] <= 0;  buffer[85] <= 0;  buffer[86] <= 0;  buffer[87] <= 0;  buffer[88] <= 0;  buffer[89] <= 0;
            buffer[90] <= 0;  buffer[91] <= 0;  buffer[92] <= 0;  buffer[93] <= 0;  buffer[94] <= 0;  buffer[95] <= 0;  buffer[96] <= 0;  buffer[97] <= 0;  buffer[98] <= 0;  buffer[99] <= 0;
            buffer[100] <= 0; buffer[101] <= 0; buffer[102] <= 0; buffer[103] <= 0; buffer[104] <= 0; buffer[105] <= 0; buffer[106] <= 0; buffer[107] <= 0; buffer[108] <= 0; buffer[109] <= 0;
            buffer[110] <= 0; buffer[111] <= 0; buffer[112] <= 0; buffer[113] <= 0; buffer[114] <= 0; buffer[115] <= 0; buffer[116] <= 0; buffer[117] <= 0; buffer[118] <= 0; buffer[119] <= 0;
   
            buf_cnt           <= 0;  
            buf_active        <= 0;  
            in_column_cnt     <= 0; 
            in_row_cnt        <= 0; 
            addr_cnt          <= 0;
            send_cnt          <= 0;
            chennal_cnt       <= 0;
        end
            
        else if(state == DECIDE)begin
        
        end 
        else if(state == KERNEL6)begin
            send_cnt       <= 0;
            done_im2col    <= 0;
            im2col_valid   <= 0;
            if(slice_cnt == 1)begin
                if(in_column_cnt == 0)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 77)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 77)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 81)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 81)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 77)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 77)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                end
                /////////////////////second column
                else if(in_column_cnt < col_slicing)begin
                    if(in_row_cnt==0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 121)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 121)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                end
                //last column
                else if(in_column_cnt == col_slicing)begin
                    if(in_row_cnt==0)begin

                    end
                    else if(in_row_cnt < 31)begin

                    end
                    else if(in_row_cnt == 31)begin
                    end
                end
            end
            
            else if(slice_cnt == 2)begin
                if(in_column_cnt < col_slicing)begin
                    if(in_row_cnt==0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 121)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 121)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                end
            end
             
            else if(slice_cnt == 3)begin
                if(in_column_cnt < col_slicing - 1)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 121)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 121)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 115)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 115)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                end
                //last column
                else if(in_column_cnt == col_slicing - 1)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 77)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 77)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 81)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 81)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == 31)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 77)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 77)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                end
            end
        end 
        
        else if(state == K6_IM2COL)begin
            ready_im2col   <= 0;
            buf_cnt        <= 0;
            buf_active     <= 0;
            addr_cnt       <= 0;
            
            if(!image_pause)begin
                if(slice_cnt == 1)begin
                    if(in_column_cnt == 0)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [3], pad, pad, 
                                    buffer [2], pad, pad, 
                                    buffer [1], pad, pad, 
                                    buffer [0], pad, pad, 
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                              // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [11][31:0],buffer[10],   // (0,0,0,1,2,3)
                                    buffer [9][31:0],buffer [8],  // (0,0,640,641,642,643)   
                                    buffer [7][31:0],buffer [6],  // (0,0,1280,1281,1282,1283) 
                                    buffer [5][31:0],buffer [4],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [17], buffer [18][63:32], // (0,0,0,1,2,3)
                                    buffer [16], buffer [16][63:32],// (0,0,640,641,642,643)   
                                    buffer [15], buffer [14][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [13], buffer [12][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [27][31:0],buffer[26],   // (0,0,0,1,2,3)
                                    buffer [25][31:0],buffer [24],  // (0,0,640,641,642,643)   
                                    buffer [23][31:0],buffer [22],  // (0,0,1280,1281,1282,1283) 
                                    buffer [21][31:0],buffer [20],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [43][31:0],buffer[42],   // (0,0,0,1,2,3)
                                    buffer [41][31:0],buffer [40],  // (0,0,640,641,642,643)   
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [51], buffer [50][63:32], // (0,0,0,1,2,3)
                                    buffer [49], buffer [48][63:32],// (0,0,640,641,642,643)   
                                    buffer [47], buffer [46][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [45], buffer [44][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [59][31:0],buffer[58],   // (0,0,0,1,2,3)
                                    buffer [57][31:0],buffer [56],  // (0,0,640,641,642,643)   
                                    buffer [55][31:0],buffer [54],  // (0,0,1280,1281,1282,1283) 
                                    buffer [53][31:0],buffer [52],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [67], buffer [66][63:32], // (0,0,0,1,2,3)
                                    buffer [65], buffer [64][63:32],// (0,0,640,641,642,643)   
                                    buffer [63], buffer [62][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [61], buffer [60][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [75][31:0],buffer[74],   // (0,0,0,1,2,3)
                                    buffer [73][31:0],buffer [72],  // (0,0,640,641,642,643)   
                                    buffer [71][31:0],buffer [70],  // (0,0,1280,1281,1282,1283) 
                                    buffer [69][31:0],buffer [68],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [7], buffer [6][63:32], // (0,0,0,1,2,3)
                                    buffer [5], buffer [4][63:32],// (0,0,640,641,642,643)   
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                             // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [15][31:0],buffer[14],   // (0,0,0,1,2,3)
                                    buffer [13][31:0],buffer [12],  // (0,0,640,641,642,643)   
                                    buffer [11][31:0],buffer [10],  // (0,0,1280,1281,1282,1283) 
                                    buffer [9][31:0],buffer [8],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [23], buffer [22][63:32], // (0,0,0,1,2,3)
                                    buffer [21], buffer [20][63:32],// (0,0,640,641,642,643)   
                                    buffer [19], buffer [18][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [17], buffer [16][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [31][31:0],buffer[30],   // (0,0,0,1,2,3)
                                    buffer [29][31:0],buffer [28],  // (0,0,640,641,642,643)   
                                    buffer [27][31:0],buffer [26],  // (0,0,1280,1281,1282,1283) 
                                    buffer [25][31:0],buffer [24],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [39], buffer [38][63:32], // (0,0,0,1,2,3)
                                    buffer [37], buffer [36][63:32],// (0,0,640,641,642,643)   
                                    buffer [35], buffer [34][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [33], buffer [32][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer[46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [55], buffer [54][63:32], // (0,0,0,1,2,3)
                                    buffer [53], buffer [52][63:32],// (0,0,640,641,642,643)   
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [63][31:0],buffer[62],   // (0,0,0,1,2,3)
                                    buffer [61][31:0],buffer [60],  // (0,0,640,641,642,643)   
                                    buffer [59][31:0],buffer [58],  // (0,0,1280,1281,1282,1283) 
                                    buffer [57][31:0],buffer [56],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [71], buffer [70][63:32], // (0,0,0,1,2,3)
                                    buffer [69], buffer [68][63:32],// (0,0,640,641,642,643)   
                                    buffer [67], buffer [66][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [65], buffer [64][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [79][31:0],buffer[78],   // (0,0,0,1,2,3)
                                    buffer [77][31:0],buffer [76],  // (0,0,640,641,642,643)   
                                    buffer [75][31:0],buffer [74],  // (0,0,1280,1281,1282,1283) 
                                    buffer [73][31:0],buffer [72],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [7], buffer [6][63:32], // (0,0,0,1,2,3)
                                    buffer [5], buffer [4][63:32],// (0,0,640,641,642,643)   
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                             // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [15][31:0],buffer[14],   // (0,0,0,1,2,3)
                                    buffer [13][31:0],buffer [12],  // (0,0,640,641,642,643)   
                                    buffer [11][31:0],buffer [10],  // (0,0,1280,1281,1282,1283) 
                                    buffer [9][31:0],buffer [8],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [23], buffer [22][63:32], // (0,0,0,1,2,3)
                                    buffer [21], buffer [20][63:32],// (0,0,640,641,642,643)   
                                    buffer [19], buffer [18][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [17], buffer [16][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [31][31:0],buffer[30],   // (0,0,0,1,2,3)
                                    buffer [29][31:0],buffer [28],  // (0,0,640,641,642,643)   
                                    buffer [27][31:0],buffer [26],  // (0,0,1280,1281,1282,1283) 
                                    buffer [25][31:0],buffer [24],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [39], buffer [38][63:32], // (0,0,0,1,2,3)
                                    buffer [37], buffer [36][63:32],// (0,0,640,641,642,643)   
                                    buffer [35], buffer [34][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [33], buffer [32][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer[46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [55], buffer [54][63:32], // (0,0,0,1,2,3)
                                    buffer [53], buffer [52][63:32],// (0,0,640,641,642,643)   
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [63][31:0],buffer[62],   // (0,0,0,1,2,3)
                                    buffer [61][31:0],buffer [60],  // (0,0,640,641,642,643)   
                                    buffer [59][31:0],buffer [58],  // (0,0,1280,1281,1282,1283) 
                                    buffer [57][31:0],buffer [56],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [71], buffer [70][63:32], // (0,0,0,1,2,3)
                                    buffer [69], buffer [68][63:32],// (0,0,640,641,642,643)   
                                    buffer [67], buffer [66][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [65], buffer [64][63:32],// (0,0,1920,1921,2922,2923)  
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, buffer[75],   // (0,0,0,1,2,3)
                                    pad, pad, buffer [74],  // (0,0,640,641,642,643)   
                                    pad, pad, buffer [73],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [72],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad                                            // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    /////////////////////second column
                    else if(in_column_cnt < col_slicing)begin
                        if(in_row_cnt==0)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [5], pad, pad, 
                                    buffer [4], pad, pad, 
                                    buffer [3], pad, pad, 
                                    buffer [2], pad, pad, 
                                    buffer [1], pad, pad,                                              // (0,0,0,0,0,0)
                                    buffer [0], pad, pad                                              // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [17][31:0],buffer[16],   // (0,0,0,1,2,3)
                                    buffer [15][31:0],buffer [14],  // (0,0,640,641,642,643)   
                                    buffer [13][31:0],buffer [12],  // (0,0,1280,1281,1282,1283) 
                                    buffer [11][31:0],buffer [10],  // (0,0,1920,1921,2922,2923)
                                    buffer [9][31:0],buffer [8],  // (0,0,1280,1281,1282,1283) 
                                    buffer [7][31:0],buffer [6]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [27], buffer [28][63:32], // (0,0,0,1,2,3)
                                    buffer [26], buffer [26][63:32],// (0,0,640,641,642,643)   
                                    buffer [25], buffer [24][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [23], buffer [22][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [21], buffer [20][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [19], buffer [18][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [41][31:0],buffer [40],   // (0,0,0,1,2,3)
                                    buffer [39][31:0],buffer [38],  // (0,0,640,641,642,643)   
                                    buffer [37][31:0],buffer [36],  // (0,0,1280,1281,1282,1283) 
                                    buffer [35][31:0],buffer [34],  // (0,0,1920,1921,2922,2923)
                                    buffer [33][31:0],buffer [32],  // (0,0,1280,1281,1282,1283) 
                                    buffer [31][31:0],buffer [30]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [53], buffer [52][63:32], // (0,0,0,1,2,3)
                                    buffer [51], buffer [50][63:32],// (0,0,640,641,642,643)   
                                    buffer [49], buffer [48][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [47], buffer [46][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [45], buffer [44][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [43], buffer [42][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [65][31:0],buffer [64],   // (0,0,0,1,2,3)
                                    buffer [63][31:0],buffer [62],  // (0,0,640,641,642,643)   
                                    buffer [61][31:0],buffer [60],  // (0,0,1280,1281,1282,1283) 
                                    buffer [59][31:0],buffer [58],  // (0,0,1920,1921,2922,2923)
                                    buffer [57][31:0],buffer [56],  // (0,0,1280,1281,1282,1283) 
                                    buffer [55][31:0],buffer [54]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [77], buffer [76][63:32], // (0,0,0,1,2,3)
                                    buffer [75], buffer [74][63:32],// (0,0,640,641,642,643)   
                                    buffer [73], buffer [72][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [71], buffer [70][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [69], buffer [68][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [67], buffer [66][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [87][31:0],buffer [88],   // (0,0,0,1,2,3)
                                    buffer [85][31:0],buffer [86],  // (0,0,640,641,642,643)   
                                    buffer [83][31:0],buffer [84],  // (0,0,1280,1281,1282,1283) 
                                    buffer [81][31:0],buffer [82],  // (0,0,1920,1921,2922,2923)
                                    buffer [79][31:0],buffer [80],  // (0,0,1280,1281,1282,1283) 
                                    buffer [77][31:0],buffer [78]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [101], buffer [100][63:32], // (0,0,0,1,2,3)
                                    buffer [99], buffer [98][63:32],// (0,0,640,641,642,643)   
                                    buffer [97], buffer [96][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [95], buffer [94][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [93], buffer [92][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [91], buffer [90][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [113][31:0],buffer [112],   // (0,0,0,1,2,3)
                                    buffer [111][31:0],buffer [110],  // (0,0,640,641,642,643)   
                                    buffer [109][31:0],buffer [108],  // (0,0,1280,1281,1282,1283) 
                                    buffer [107][31:0],buffer [106],  // (0,0,1920,1921,2922,2923)
                                    buffer [105][31:0],buffer [104],  // (0,0,1280,1281,1282,1283) 
                                    buffer [103][31:0],buffer [102]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [119][31:0],buffer [118],   // (0,0,0,1,2,3)
                                    buffer [117][31:0],buffer [116],  // (0,0,640,641,642,643)   
                                    buffer [115][31:0],buffer [114],  // (0,0,1280,1281,1282,1283) 
                                    buffer [113][31:0],buffer [112],  // (0,0,1920,1921,2922,2923)
                                    buffer [111][31:0],buffer [110],  // (0,0,1280,1281,1282,1283) 
                                    buffer [109][31:0],buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, buffer [113],   // (0,0,0,1,2,3)
                                    pad, pad, buffer [112],  // (0,0,640,641,642,643)   
                                    pad, pad, buffer [111],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [110],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, buffer [109],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    //last column
                    else if(in_column_cnt == col_slicing)begin
                        if(in_row_cnt==0)begin

                        end
                        else if(in_row_cnt < 31)begin

                        end
                        else if(in_row_cnt == 31)begin
                        end
                    end
                end
                
                else if(slice_cnt == 2)begin
                
                    if(in_column_cnt < col_slicing)begin
                        if(in_row_cnt==0)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [5], pad, pad, 
                                    buffer [4], pad, pad, 
                                    buffer [3], pad, pad, 
                                    buffer [2], pad, pad, 
                                    buffer [1], pad, pad,                                              // (0,0,0,0,0,0)
                                    buffer [0], pad, pad                                              // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [17][31:0],buffer[16],   // (0,0,0,1,2,3)
                                    buffer [15][31:0],buffer [14],  // (0,0,640,641,642,643)   
                                    buffer [13][31:0],buffer [12],  // (0,0,1280,1281,1282,1283) 
                                    buffer [11][31:0],buffer [10],  // (0,0,1920,1921,2922,2923)
                                    buffer [9][31:0],buffer [8],  // (0,0,1280,1281,1282,1283) 
                                    buffer [7][31:0],buffer [6]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [27], buffer [28][63:32], // (0,0,0,1,2,3)
                                    buffer [26], buffer [26][63:32],// (0,0,640,641,642,643)   
                                    buffer [25], buffer [24][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [23], buffer [22][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [21], buffer [20][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [19], buffer [18][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [41][31:0],buffer [40],   // (0,0,0,1,2,3)
                                    buffer [39][31:0],buffer [38],  // (0,0,640,641,642,643)   
                                    buffer [37][31:0],buffer [36],  // (0,0,1280,1281,1282,1283) 
                                    buffer [35][31:0],buffer [34],  // (0,0,1920,1921,2922,2923)
                                    buffer [33][31:0],buffer [32],  // (0,0,1280,1281,1282,1283) 
                                    buffer [31][31:0],buffer [30]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [53], buffer [52][63:32], // (0,0,0,1,2,3)
                                    buffer [51], buffer [50][63:32],// (0,0,640,641,642,643)   
                                    buffer [49], buffer [48][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [47], buffer [46][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [45], buffer [44][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [43], buffer [42][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [65][31:0],buffer [64],   // (0,0,0,1,2,3)
                                    buffer [63][31:0],buffer [62],  // (0,0,640,641,642,643)   
                                    buffer [61][31:0],buffer [60],  // (0,0,1280,1281,1282,1283) 
                                    buffer [59][31:0],buffer [58],  // (0,0,1920,1921,2922,2923)
                                    buffer [57][31:0],buffer [56],  // (0,0,1280,1281,1282,1283) 
                                    buffer [55][31:0],buffer [54]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [77], buffer [76][63:32], // (0,0,0,1,2,3)
                                    buffer [75], buffer [74][63:32],// (0,0,640,641,642,643)   
                                    buffer [73], buffer [72][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [71], buffer [70][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [69], buffer [68][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [67], buffer [66][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [87][31:0],buffer [88],   // (0,0,0,1,2,3)
                                    buffer [85][31:0],buffer [86],  // (0,0,640,641,642,643)   
                                    buffer [83][31:0],buffer [84],  // (0,0,1280,1281,1282,1283) 
                                    buffer [81][31:0],buffer [82],  // (0,0,1920,1921,2922,2923)
                                    buffer [79][31:0],buffer [80],  // (0,0,1280,1281,1282,1283) 
                                    buffer [77][31:0],buffer [78]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [101], buffer [100][63:32], // (0,0,0,1,2,3)
                                    buffer [99], buffer [98][63:32],// (0,0,640,641,642,643)   
                                    buffer [97], buffer [96][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [95], buffer [94][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [93], buffer [92][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [91], buffer [90][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [113][31:0],buffer [112],   // (0,0,0,1,2,3)
                                    buffer [111][31:0],buffer [110],  // (0,0,640,641,642,643)   
                                    buffer [109][31:0],buffer [108],  // (0,0,1280,1281,1282,1283) 
                                    buffer [107][31:0],buffer [106],  // (0,0,1920,1921,2922,2923)
                                    buffer [105][31:0],buffer [104],  // (0,0,1280,1281,1282,1283) 
                                    buffer [103][31:0],buffer [102]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [119][31:0],buffer [118],   // (0,0,0,1,2,3)
                                    buffer [117][31:0],buffer [116],  // (0,0,640,641,642,643)   
                                    buffer [115][31:0],buffer [114],  // (0,0,1280,1281,1282,1283) 
                                    buffer [113][31:0],buffer [112],  // (0,0,1920,1921,2922,2923)
                                    buffer [111][31:0],buffer [110],  // (0,0,1280,1281,1282,1283) 
                                    buffer [109][31:0],buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, buffer [113],   // (0,0,0,1,2,3)
                                    pad, pad, buffer [112],  // (0,0,640,641,642,643)   
                                    pad, pad, buffer [111],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [110],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, buffer [109],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end

                end
                else if(slice_cnt == 3)begin
                    if(in_column_cnt < col_slicing - 1)begin
                        if(in_row_cnt==0)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [5], pad, pad, 
                                    buffer [4], pad, pad, 
                                    buffer [3], pad, pad, 
                                    buffer [2], pad, pad, 
                                    buffer [1], pad, pad,                                              // (0,0,0,0,0,0)
                                    buffer [0], pad, pad                                              // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [17][31:0],buffer[16],   // (0,0,0,1,2,3)
                                    buffer [15][31:0],buffer [14],  // (0,0,640,641,642,643)   
                                    buffer [13][31:0],buffer [12],  // (0,0,1280,1281,1282,1283) 
                                    buffer [11][31:0],buffer [10],  // (0,0,1920,1921,2922,2923)
                                    buffer [9][31:0],buffer [8],  // (0,0,1280,1281,1282,1283) 
                                    buffer [7][31:0],buffer [6]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [27], buffer [28][63:32], // (0,0,0,1,2,3)
                                    buffer [26], buffer [26][63:32],// (0,0,640,641,642,643)   
                                    buffer [25], buffer [24][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [23], buffer [22][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [21], buffer [20][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [19], buffer [18][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [41][31:0],buffer [40],   // (0,0,0,1,2,3)
                                    buffer [39][31:0],buffer [38],  // (0,0,640,641,642,643)   
                                    buffer [37][31:0],buffer [36],  // (0,0,1280,1281,1282,1283) 
                                    buffer [35][31:0],buffer [34],  // (0,0,1920,1921,2922,2923)
                                    buffer [33][31:0],buffer [32],  // (0,0,1280,1281,1282,1283) 
                                    buffer [31][31:0],buffer [30]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [53], buffer [52][63:32], // (0,0,0,1,2,3)
                                    buffer [51], buffer [50][63:32],// (0,0,640,641,642,643)   
                                    buffer [49], buffer [48][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [47], buffer [46][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [45], buffer [44][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [43], buffer [42][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [65][31:0],buffer [64],   // (0,0,0,1,2,3)
                                    buffer [63][31:0],buffer [62],  // (0,0,640,641,642,643)   
                                    buffer [61][31:0],buffer [60],  // (0,0,1280,1281,1282,1283) 
                                    buffer [59][31:0],buffer [58],  // (0,0,1920,1921,2922,2923)
                                    buffer [57][31:0],buffer [56],  // (0,0,1280,1281,1282,1283) 
                                    buffer [55][31:0],buffer [54]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [77], buffer [76][63:32], // (0,0,0,1,2,3)
                                    buffer [75], buffer [74][63:32],// (0,0,640,641,642,643)   
                                    buffer [73], buffer [72][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [71], buffer [70][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [69], buffer [68][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [67], buffer [66][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [87][31:0],buffer [88],   // (0,0,0,1,2,3)
                                    buffer [85][31:0],buffer [86],  // (0,0,640,641,642,643)   
                                    buffer [83][31:0],buffer [84],  // (0,0,1280,1281,1282,1283) 
                                    buffer [81][31:0],buffer [82],  // (0,0,1920,1921,2922,2923)
                                    buffer [79][31:0],buffer [80],  // (0,0,1280,1281,1282,1283) 
                                    buffer [77][31:0],buffer [78]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [101], buffer [100][63:32], // (0,0,0,1,2,3)
                                    buffer [99], buffer [98][63:32],// (0,0,640,641,642,643)   
                                    buffer [97], buffer [96][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [95], buffer [94][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [93], buffer [92][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [91], buffer [90][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [113][31:0],buffer [112],   // (0,0,0,1,2,3)
                                    buffer [111][31:0],buffer [110],  // (0,0,640,641,642,643)   
                                    buffer [109][31:0],buffer [108],  // (0,0,1280,1281,1282,1283) 
                                    buffer [107][31:0],buffer [106],  // (0,0,1920,1921,2922,2923)
                                    buffer [105][31:0],buffer [104],  // (0,0,1280,1281,1282,1283) 
                                    buffer [103][31:0],buffer [102]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    buffer [119][31:0],buffer [118],   // (0,0,0,1,2,3)
                                    buffer [117][31:0],buffer [116],  // (0,0,640,641,642,643)   
                                    buffer [115][31:0],buffer [114],  // (0,0,1280,1281,1282,1283) 
                                    buffer [113][31:0],buffer [112],  // (0,0,1920,1921,2922,2923)
                                    buffer [111][31:0],buffer [110],  // (0,0,1280,1281,1282,1283) 
                                    buffer [109][31:0],buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    buffer [11], buffer [10][63:32], // (0,0,0,1,2,3)
                                    buffer [9], buffer [8][63:32],// (0,0,640,641,642,643)   
                                    buffer [7], buffer [6][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [5], buffer [4][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    buffer [23][31:0],buffer[22],   // (0,0,0,1,2,3)
                                    buffer [21][31:0],buffer [20],  // (0,0,640,641,642,643)   
                                    buffer [19][31:0],buffer [18],  // (0,0,1280,1281,1282,1283) 
                                    buffer [17][31:0],buffer [16],  // (0,0,1920,1921,2922,2923)
                                    buffer [15][31:0],buffer [14],  // (0,0,1280,1281,1282,1283) 
                                    buffer [13][31:0],buffer [12]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [27], buffer [26][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [25], buffer [24][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    buffer [47][31:0],buffer [46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40],  // (0,0,1920,1921,2922,2923)
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    buffer [59], buffer [58][63:32], // (0,0,0,1,2,3)
                                    buffer [57], buffer [56][63:32],// (0,0,640,641,642,643)   
                                    buffer [55], buffer [54][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [53], buffer [52][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    buffer [71][31:0],buffer [70],   // (0,0,0,1,2,3)
                                    buffer [69][31:0],buffer [68],  // (0,0,640,641,642,643)   
                                    buffer [67][31:0],buffer [66],  // (0,0,1280,1281,1282,1283) 
                                    buffer [65][31:0],buffer [64],  // (0,0,1920,1921,2922,2923)
                                    buffer [63][31:0],buffer [62],  // (0,0,1280,1281,1282,1283) 
                                    buffer [61][31:0],buffer [60]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    buffer [83], buffer [82][63:32], // (0,0,0,1,2,3)
                                    buffer [81], buffer [80][63:32],// (0,0,640,641,642,643)   
                                    buffer [79], buffer [78][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [77], buffer [76][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [75], buffer [74][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [73], buffer [72][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    buffer [95][31:0],buffer [94],   // (0,0,0,1,2,3)
                                    buffer [93][31:0],buffer [92],  // (0,0,640,641,642,643)   
                                    buffer [91][31:0],buffer [90],  // (0,0,1280,1281,1282,1283) 
                                    buffer [89][31:0],buffer [88],  // (0,0,1920,1921,2922,2923)
                                    buffer [87][31:0],buffer [86],  // (0,0,1280,1281,1282,1283) 
                                    buffer [85][31:0],buffer [84]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    buffer [107], buffer [106][63:32], // (0,0,0,1,2,3)
                                    buffer [105], buffer [104][63:32],// (0,0,640,641,642,643)   
                                    buffer [103], buffer [102][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [101], buffer [100][63:32],// (0,0,1920,1921,2922,2923)  
                                    buffer [99], buffer [98][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [97], buffer [96][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, buffer [113],   // (0,0,0,1,2,3)
                                    pad, pad, buffer [112],  // (0,0,640,641,642,643)   
                                    pad, pad, buffer [111],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [110],  // (0,0,1920,1921,2922,2923)
                                    pad, pad, buffer [109],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [108]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    else if(in_column_cnt == col_slicing - 1)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,   
                                    buffer [3], pad, pad, 
                                    buffer [2], pad, pad, 
                                    buffer [1], pad, pad, 
                                    buffer [0], pad, pad                                           // (0,0,0,0,0,0)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [11][31:0],buffer[10],   // (0,0,0,1,2,3)
                                    buffer [9][31:0],buffer [8],  // (0,0,640,641,642,643)   
                                    buffer [7][31:0],buffer [6],  // (0,0,1280,1281,1282,1283) 
                                    buffer [5][31:0],buffer [4]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,
                                    buffer [17], buffer [18][63:32], // (0,0,0,1,2,3)
                                    buffer [16], buffer [16][63:32],// (0,0,640,641,642,643)   
                                    buffer [15], buffer [14][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [13], buffer [12][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [27][31:0],buffer [26],   // (0,0,0,1,2,3)
                                    buffer [25][31:0],buffer [24],  // (0,0,640,641,642,643)   
                                    buffer [23][31:0],buffer [22],  // (0,0,1280,1281,1282,1283) 
                                    buffer [21][31:0],buffer [20]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [35], buffer [34][63:32], // (0,0,0,1,2,3)
                                    buffer [33], buffer [32][63:32],// (0,0,640,641,642,643)   
                                    buffer [31], buffer [30][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [29], buffer [28][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [43][31:0],buffer[42],   // (0,0,0,1,2,3)
                                    buffer [41][31:0],buffer [40],  // (0,0,640,641,642,643)   
                                    buffer [39][31:0],buffer [38],  // (0,0,1280,1281,1282,1283) 
                                    buffer [37][31:0],buffer [36]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [51], buffer [50][63:32], // (0,0,0,1,2,3)
                                    buffer [49], buffer [48][63:32],// (0,0,640,641,642,643)   
                                    buffer [47], buffer [46][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [45], buffer [44][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [59][31:0],buffer[58],   // (0,0,0,1,2,3)
                                    buffer [57][31:0],buffer [56],  // (0,0,640,641,642,643)   
                                    buffer [55][31:0],buffer [54],  // (0,0,1280,1281,1282,1283) 
                                    buffer [53][31:0],buffer [52]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [67], buffer [66][63:32], // (0,0,0,1,2,3)
                                    buffer [65], buffer [64][63:32],// (0,0,640,641,642,643)   
                                    buffer [63], buffer [62][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [61], buffer [60][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [75][31:0],buffer[74],   // (0,0,0,1,2,3)
                                    buffer [73][31:0],buffer [72],  // (0,0,640,641,642,643)   
                                    buffer [71][31:0],buffer [70],  // (0,0,1280,1281,1282,1283) 
                                    buffer [69][31:0],buffer [68]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                             // (0,0,0,0,0,0)
                                    buffer [7], buffer [6][63:32], // (0,0,0,1,2,3)
                                    buffer [5], buffer [4][63:32],// (0,0,640,641,642,643)   
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [15][31:0],buffer[14],   // (0,0,0,1,2,3)
                                    buffer [13][31:0],buffer [12],  // (0,0,640,641,642,643)   
                                    buffer [11][31:0],buffer [10],  // (0,0,1280,1281,1282,1283) 
                                    buffer [9][31:0],buffer [8]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [23], buffer [22][63:32], // (0,0,0,1,2,3)
                                    buffer [21], buffer [20][63:32],// (0,0,640,641,642,643)   
                                    buffer [19], buffer [18][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [17], buffer [16][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [31][31:0],buffer[30],   // (0,0,0,1,2,3)
                                    buffer [29][31:0],buffer [28],  // (0,0,640,641,642,643)   
                                    buffer [27][31:0],buffer [26],  // (0,0,1280,1281,1282,1283) 
                                    buffer [25][31:0],buffer [24]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [39], buffer [38][63:32], // (0,0,0,1,2,3)
                                    buffer [37], buffer [36][63:32],// (0,0,640,641,642,643)   
                                    buffer [35], buffer [34][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [33], buffer [32][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [47][31:0],buffer[46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [55], buffer [54][63:32], // (0,0,0,1,2,3)
                                    buffer [53], buffer [52][63:32],// (0,0,640,641,642,643)   
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [63][31:0],buffer[62],   // (0,0,0,1,2,3)
                                    buffer [61][31:0],buffer [60],  // (0,0,640,641,642,643)   
                                    buffer [59][31:0],buffer [58],  // (0,0,1280,1281,1282,1283) 
                                    buffer [57][31:0],buffer [56]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [71], buffer [70][63:32], // (0,0,0,1,2,3)
                                    buffer [69], buffer [68][63:32],// (0,0,640,641,642,643)   
                                    buffer [67], buffer [66][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [65], buffer [64][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [79][31:0],buffer[78],   // (0,0,0,1,2,3)
                                    buffer [77][31:0],buffer [76],  // (0,0,640,641,642,643)   
                                    buffer [75][31:0],buffer [74],  // (0,0,1280,1281,1282,1283) 
                                    buffer [73][31:0],buffer [72]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                             // (0,0,0,0,0,0)
                                    buffer [7], buffer [6][63:32], // (0,0,0,1,2,3)
                                    buffer [5], buffer [4][63:32],// (0,0,640,641,642,643)   
                                    buffer [3], buffer [2][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [1], buffer [0][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [15][31:0],buffer[14],   // (0,0,0,1,2,3)
                                    buffer [13][31:0],buffer [12],  // (0,0,640,641,642,643)   
                                    buffer [11][31:0],buffer [10],  // (0,0,1280,1281,1282,1283) 
                                    buffer [9][31:0],buffer [8]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [23], buffer [22][63:32], // (0,0,0,1,2,3)
                                    buffer [21], buffer [20][63:32],// (0,0,640,641,642,643)   
                                    buffer [19], buffer [18][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [17], buffer [16][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [31][31:0],buffer[30],   // (0,0,0,1,2,3)
                                    buffer [29][31:0],buffer [28],  // (0,0,640,641,642,643)   
                                    buffer [27][31:0],buffer [26],  // (0,0,1280,1281,1282,1283) 
                                    buffer [25][31:0],buffer [24]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [39], buffer [38][63:32], // (0,0,0,1,2,3)
                                    buffer [37], buffer [36][63:32],// (0,0,640,641,642,643)   
                                    buffer [35], buffer [34][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [33], buffer [32][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [47][31:0],buffer[46],   // (0,0,0,1,2,3)
                                    buffer [45][31:0],buffer [44],  // (0,0,640,641,642,643)   
                                    buffer [43][31:0],buffer [42],  // (0,0,1280,1281,1282,1283) 
                                    buffer [41][31:0],buffer [40]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad, 
                                    buffer [55], buffer [54][63:32], // (0,0,0,1,2,3)
                                    buffer [53], buffer [52][63:32],// (0,0,640,641,642,643)   
                                    buffer [51], buffer [50][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [49], buffer [48][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    buffer [63][31:0],buffer[62],   // (0,0,0,1,2,3)
                                    buffer [61][31:0],buffer [60],  // (0,0,640,641,642,643)   
                                    buffer [59][31:0],buffer [58],  // (0,0,1280,1281,1282,1283) 
                                    buffer [57][31:0],buffer [56]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,  
                                    buffer [71], buffer [70][63:32], // (0,0,0,1,2,3)
                                    buffer [69], buffer [68][63:32],// (0,0,640,641,642,643)   
                                    buffer [67], buffer [66][63:32],// (0,0,1280,1281,1282,1283) 
                                    buffer [65], buffer [64][63:32]// (0,0,1920,1921,2922,2923)  
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in6_im2col_data <= {
                                    pad, pad, pad, pad, pad, pad,                                              // (0,0,0,0,0,0)
                                    pad, pad, pad, pad, pad, pad,                                            // (0,0,0,0,0,0) 
                                    pad, pad, buffer[75],   // (0,0,0,1,2,3)
                                    pad, pad, buffer [74],  // (0,0,640,641,642,643)   
                                    pad, pad, buffer [73],  // (0,0,1280,1281,1282,1283) 
                                    pad, pad, buffer [72]  // (0,0,1920,1921,2922,2923)
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                end
            end
        end 
        /////////////////////////////////////////////////kernel 3
        else if(state == KERNEL3)begin
            send_cnt       <= 0;
            done_im2col    <= 0;
            im2col_valid   <= 0;
            if(slice_cnt == 1)begin
                if(in_column_cnt == 0)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 29)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 29)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < row_slicing)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 31)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 31)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == row_slicing)begin

                    end
                end
                /////////////////////second column
                else if(in_column_cnt < col_slicing)begin
                    if(in_row_cnt==0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 43)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 43)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < row_slicing)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 46)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 46)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == row_slicing)begin

                    end
                end
                //last column
                else if(in_column_cnt == col_slicing)begin
                    if(in_row_cnt==0)begin

                    end
                    else if(in_row_cnt < 31)begin

                    end
                    else if(in_row_cnt == 31)begin
                    end
                end
            end
            
            else if(slice_cnt == 2)begin
                if(in_column_cnt < col_slicing)begin
                    if(in_row_cnt==0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 43)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 43)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < row_slicing)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 46)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 46)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == row_slicing)begin

                    end
                end
            end
             
            else if(slice_cnt == 3)begin
                if(in_column_cnt < col_slicing - 1)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 43)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 43)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < row_slicing)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 46)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 46)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == row_slicing)begin
    
                    end
                end
                //last column
                else if(in_column_cnt == col_slicing - 1)begin
                    if(in_row_cnt == 0)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 29)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 29)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt < row_slicing)begin
                        if(in_rd_en)begin
                            buf_active <= 1;
                        end
                        if(buf_active)begin
                            if(buf_cnt < 31)begin
                                buffer[addr_cnt] <= in_rd_data;
                                addr_cnt         <= addr_cnt + 1;
                                buf_cnt          <= buf_cnt + 1;
                            end
                            else if(buf_cnt == 31)begin
                                ready_im2col     <= 1;
                            end
                        end
                    end
                    else if(in_row_cnt == row_slicing)begin

                    end
                end
            end
        end 
        else if(state == K3_IM2COL)begin
            ready_im2col   <= 0;
            buf_cnt        <= 0;
            buf_active     <= 0;
            addr_cnt       <= 0;
            
            if(!image_pause)begin
                if(slice_cnt == 1)begin
                    if(in_column_cnt == 0)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [1][31:0], pad, 
                                    buffer [0][31:0], pad, 
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [3][31:16],   // (0,0,1280,1281,1282,1283) 
                                    buffer [2][31:16],   // (0,0,1920,1921,2922,2923)
                                    pad, pad, pad                                  // (0,0,0,0,0,0) 
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [7][31:0], buffer [6][63:48], // (0,0,0,1,2,3)
                                    buffer [5][31:0], buffer [4][63:48],// (0,0,640,641,642,643)   
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [9][63:16],
                                    buffer [8][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [13][31:0], buffer [12][63:48], // (0,0,0,1,2,3)
                                    buffer [11][31:0], buffer [10][63:48],// (0,0,640,641,642,643)   
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [15][63:16],
                                    buffer [14][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [19][31:0], buffer [18][63:48], // (0,0,0,1,2,3)
                                    buffer [17][31:0], buffer [16][63:48],// (0,0,640,641,642,643)   
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [21][63:16],
                                    buffer [20][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [25][31:0], buffer [24][63:48], // (0,0,0,1,2,3)
                                    buffer [23][31:0], buffer [22][63:48],// (0,0,640,641,642,643)   
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [27][63:16],
                                    buffer [26][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [3][31:0], buffer [2][63:48], // (0,0,0,1,2,3)
                                    buffer [1][31:0], buffer [0][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][63:16],
                                    buffer [4][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [9][31:0], buffer [8][63:48], // (0,0,0,1,2,3)
                                    buffer [7][31:0], buffer [6][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [11][63:16],
                                    buffer [10][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [15][31:0], buffer [14][63:48], // (0,0,0,1,2,3)
                                    buffer [13][31:0], buffer [12][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [21][31:0], buffer [20][63:48], // (0,0,0,1,2,3)
                                    buffer [19][31:0], buffer [18][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [27][31:0], buffer [26][63:48], // (0,0,0,1,2,3)
                                    buffer [25][31:0], buffer [24][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [29][63:16],
                                    buffer [28][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [3][31:0], buffer [2][63:48], // (0,0,0,1,2,3)
                                    buffer [1][31:0], buffer [0][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][63:16],
                                    buffer [4][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [9][31:0], buffer [8][63:48], // (0,0,0,1,2,3)
                                    buffer [7][31:0], buffer [6][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [11][63:16],
                                    buffer [10][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [15][31:0], buffer [14][63:48], // (0,0,0,1,2,3)
                                    buffer [13][31:0], buffer [12][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [21][31:0], buffer [20][63:48], // (0,0,0,1,2,3)
                                    buffer [19][31:0], buffer [18][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [27][31:0], buffer [26][63:48], // (0,0,0,1,2,3)
                                    buffer [25][31:0], buffer [24][63:48],
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [29][63:16],
                                    buffer [28][63:16],    
                                    pad, pad, pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    else if(in_column_cnt < col_slicing)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [2][31:0], pad, 
                                    buffer [1][31:0], pad, 
                                    buffer [0][31:0], pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][31:16],   // (0,0,1280,1281,1282,1283) 
                                    buffer [4][31:16],   // (0,0,1920,1921,2922,2923)
                                    buffer [3][31:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [11][31:0], buffer [10][63:48], // (0,0,0,1,2,3)
                                    buffer [9][31:0], buffer [8][63:48],// (0,0,640,641,642,643)   
                                    buffer [7][31:0], buffer [6][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [14][63:16],
                                    buffer [13][63:16],    
                                    buffer [12][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [20][31:0], buffer [19][63:48], // (0,0,0,1,2,3)
                                    buffer [18][31:0], buffer [17][63:48],// (0,0,640,641,642,643)   
                                    buffer [16][31:0], buffer [15][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    buffer [21][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [29][31:0], buffer [28][63:48], // (0,0,0,1,2,3)
                                    buffer [27][31:0], buffer [26][63:48],// (0,0,640,641,642,643)   
                                    buffer [25][31:0], buffer [24][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [32][63:16],
                                    buffer [31][63:16],    
                                    buffer [30][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [38][31:0], buffer [37][63:48], // (0,0,0,1,2,3)
                                    buffer [36][31:0], buffer [35][63:48],// (0,0,640,641,642,643)   
                                    buffer [34][31:0], buffer [33][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [41][63:16],
                                    buffer [40][63:16],    
                                    buffer [39][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    
                end
                else if(slice_cnt == 2)begin
                    if(in_column_cnt == 0)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [2][31:0], pad, 
                                    buffer [1][31:0], pad, 
                                    buffer [0][31:0], pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][31:16],   // (0,0,1280,1281,1282,1283) 
                                    buffer [4][31:16],   // (0,0,1920,1921,2922,2923)
                                    buffer [3][31:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [11][31:0], buffer [10][63:48], // (0,0,0,1,2,3)
                                    buffer [9][31:0], buffer [8][63:48],// (0,0,640,641,642,643)   
                                    buffer [7][31:0], buffer [6][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [14][63:16],
                                    buffer [13][63:16],    
                                    buffer [12][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [20][31:0], buffer [19][63:48], // (0,0,0,1,2,3)
                                    buffer [18][31:0], buffer [17][63:48],// (0,0,640,641,642,643)   
                                    buffer [16][31:0], buffer [15][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    buffer [21][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [29][31:0], buffer [28][63:48], // (0,0,0,1,2,3)
                                    buffer [27][31:0], buffer [26][63:48],// (0,0,640,641,642,643)   
                                    buffer [25][31:0], buffer [24][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [32][63:16],
                                    buffer [31][63:16],    
                                    buffer [30][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [38][31:0], buffer [37][63:48], // (0,0,0,1,2,3)
                                    buffer [36][31:0], buffer [35][63:48],// (0,0,640,641,642,643)   
                                    buffer [34][31:0], buffer [33][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [41][63:16],
                                    buffer [40][63:16],    
                                    buffer [39][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    else if(in_column_cnt < col_slicing)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [2][31:0], pad, 
                                    buffer [1][31:0], pad, 
                                    buffer [0][31:0], pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][31:16],   // (0,0,1280,1281,1282,1283) 
                                    buffer [4][31:16],   // (0,0,1920,1921,2922,2923)
                                    buffer [3][31:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [11][31:0], buffer [10][63:48], // (0,0,0,1,2,3)
                                    buffer [9][31:0], buffer [8][63:48],// (0,0,640,641,642,643)   
                                    buffer [7][31:0], buffer [6][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [14][63:16],
                                    buffer [13][63:16],    
                                    buffer [12][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [20][31:0], buffer [19][63:48], // (0,0,0,1,2,3)
                                    buffer [18][31:0], buffer [17][63:48],// (0,0,640,641,642,643)   
                                    buffer [16][31:0], buffer [15][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    buffer [21][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [29][31:0], buffer [28][63:48], // (0,0,0,1,2,3)
                                    buffer [27][31:0], buffer [26][63:48],// (0,0,640,641,642,643)   
                                    buffer [25][31:0], buffer [24][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [32][63:16],
                                    buffer [31][63:16],    
                                    buffer [30][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [38][31:0], buffer [37][63:48], // (0,0,0,1,2,3)
                                    buffer [36][31:0], buffer [35][63:48],// (0,0,640,641,642,643)   
                                    buffer [34][31:0], buffer [33][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [41][63:16],
                                    buffer [40][63:16],    
                                    buffer [39][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                end
                else if(slice_cnt ==3 )begin
                    if(in_column_cnt < col_slicing)begin
                        if(in_row_cnt == 0)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [2][31:0], pad, 
                                    buffer [1][31:0], pad, 
                                    buffer [0][31:0], pad
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [5][31:16],   // (0,0,1280,1281,1282,1283) 
                                    buffer [4][31:16],   // (0,0,1920,1921,2922,2923)
                                    buffer [3][31:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [11][31:0], buffer [10][63:48], // (0,0,0,1,2,3)
                                    buffer [9][31:0], buffer [8][63:48],// (0,0,640,641,642,643)   
                                    buffer [7][31:0], buffer [6][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [14][63:16],
                                    buffer [13][63:16],    
                                    buffer [12][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [20][31:0], buffer [19][63:48], // (0,0,0,1,2,3)
                                    buffer [18][31:0], buffer [17][63:48],// (0,0,640,641,642,643)   
                                    buffer [16][31:0], buffer [15][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [23][63:16],
                                    buffer [22][63:16],    
                                    buffer [21][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [29][31:0], buffer [28][63:48], // (0,0,0,1,2,3)
                                    buffer [27][31:0], buffer [26][63:48],// (0,0,640,641,642,643)   
                                    buffer [25][31:0], buffer [24][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [32][63:16],
                                    buffer [31][63:16],    
                                    buffer [30][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [38][31:0], buffer [37][63:48], // (0,0,0,1,2,3)
                                    buffer [36][31:0], buffer [35][63:48],// (0,0,640,641,642,643)   
                                    buffer [34][31:0], buffer [33][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [41][63:16],
                                    buffer [40][63:16],    
                                    buffer [39][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end
                        else if(in_row_cnt < 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= in_row_cnt + 1;
                                    chennal_cnt  <= 0;
                                end
                            end
                        end 
                        else if(in_row_cnt == 31)begin
                            if(send_cnt < 1)begin
                                in3_im2col_data <= {
                                    buffer [5][31:0], buffer [4][63:48], // (0,0,0,1,2,3)
                                    buffer [3][31:0], buffer [2][63:48],
                                    buffer [1][31:0], buffer [0][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 2)begin
                                in3_im2col_data <= {
                                    buffer [8][63:16],
                                    buffer [7][63:16],    
                                    buffer [6][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 3)begin
                                in3_im2col_data <= {
                                    buffer [14][31:0], buffer [13][63:48], // (0,0,0,1,2,3)
                                    buffer [12][31:0], buffer [11][63:48],
                                    buffer [10][31:0], buffer [9][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 4)begin
                                in3_im2col_data <= {
                                    buffer [17][63:16],
                                    buffer [16][63:16],    
                                    buffer [15][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 5)begin
                                in3_im2col_data <= {
                                    buffer [23][31:0], buffer [22][63:48], // (0,0,0,1,2,3)
                                    buffer [21][31:0], buffer [20][63:48],
                                    buffer [19][31:0], buffer [18][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 6)begin
                                in3_im2col_data <= {
                                    buffer [26][63:16],
                                    buffer [25][63:16],    
                                    buffer [24][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 7)begin
                                in3_im2col_data <= {
                                    buffer [32][31:0], buffer [31][63:48], // (0,0,0,1,2,3)
                                    buffer [30][31:0], buffer [29][63:48],
                                    buffer [28][31:0], buffer [27][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 8)begin
                                in3_im2col_data <= {
                                    buffer [35][63:16],
                                    buffer [34][63:16],    
                                    buffer [33][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt < 9)begin
                                in3_im2col_data <= {
                                    buffer [41][31:0], buffer [40][63:48], // (0,0,0,1,2,3)
                                    buffer [39][31:0], buffer [38][63:48],
                                    buffer [37][31:0], buffer [36][63:48]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;
                            end
                            else if(send_cnt == 9)begin
                                in3_im2col_data <= {
                                    buffer [44][63:16],
                                    buffer [43][63:16],    
                                    buffer [42][63:16]
                                };
                                im2col_valid    <= 1;
                                send_cnt  <= send_cnt + 1;

                            end
                            else if(send_cnt == 10)begin
                                im2col_valid <= 0;
                                done_im2col  <= 1;
                                chennal_cnt  <= chennal_cnt + 1;
                                if(chennal_cnt == input_channel - 1)begin
                                    in_row_cnt   <= 0;
                                    chennal_cnt  <= 0;
                                    in_column_cnt <= in_column_cnt + 1;
                                end
                            end
                        end
                    end
                    else if(in_column_cnt == col_slicing)begin
                        
                    end
                end
            end       
        end 
    end
endmodule