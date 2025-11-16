`default_nettype none

module w_im2col #(
    parameter 
        AXI_HP_BIT = 64,       //HP port width
        DATA_WIDTH = 16,       //fixed point(Q7.9)
        ROW_WIDTH  = 4,        //matrix 4x4
        ADDR_WIDTH = 14        //BRAM address width
)(
    input wire                             clk,
    input wire                             reset,
    input wire                             conv_en,
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

    
    //WEIGHT DATA IN
    output reg                             we_rd_en,
    output reg [ADDR_WIDTH - 1:0]          we_rd_addr,
    input wire [AXI_HP_BIT - 1:0]          we_rd_data,         

    //IM2COL related signal
    input wire                             weight_pause,      //stop im2col       1: stop  0: keep going
    output reg                             last_im2col,      //send last data   to debug
    output reg                             we_im2col_valid,     //can send im2col 
    
    //IM2COL DATA OUT
    output reg [DATA_WIDTH * 9 - 1:0]      we3_im2col_data,  //3 kernel OUTPUT 
    output reg [DATA_WIDTH * 36- 1:0]      we6_im2col_data   // 16bit x 6kernel x 6kernel x RGB
);


    localparam IDLE       = 0,
               DECIDE     = 1,
               READ       = 2,
               KERNEL_6   = 3,
               NEXT_CHA   = 4,
               REPEAT     = 5,
               K_6_im2col = 6,
               
               KERNEL_3   = 7,
               K_3_im2col = 8,
               NEXT_CHA3  = 9,
               REPEAT3    = 10,
               DONE       = 11; 

    reg [3:0] state, n_state;
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
    
    wire [ADDR_WIDTH - 1:0] row_slicing, col_slicing, total_slicing;
    //to count convolution matrix slicing
    assign row_slicing = (in_row + 2*padding - kernel)/2 + 1;         //640 x 32  ---> 320
    assign col_slicing = (in_column + pad - kernel)/2 + 1;        //640 x 32      ---> 15 (first tile)
    assign total_slicing = row_slicing * col_slicing;               //  4800 one channel
    
    
    reg [63:0] buffer [0:8];
    reg [15:0] weight_cnt, store_cnt, next_weight, in_channel_cnt, out_channel_cnt, next_channel;
    reg [15:0] next_ten_weight;
    reg [15:0] repeat_num;
    reg [3:0] add_cnt; // to count one channel weight <--- 10
    reg im2col_done;
    
    reg [2:0] addr_case;   //to kernel3

    always @(posedge clk or negedge reset) begin                                                               
        if (!reset) begin                                                                                      
            state <= IDLE;                                                                                   
        end
        else if(sudo_reset)begin
            state <= IDLE; 
        end 
        else begin                                                                                       
            state <= n_state;                                                                                
        end                                                                                                  
    end                 
         
    always@(*)begin
        n_state = state;
        
        case(state)
            IDLE: begin
                if(conv_en)begin
                    n_state = DECIDE;
                end
            end
            DECIDE: begin
                case(kernel)
                    3'b110: begin n_state = KERNEL_6;   end   //   Kernel:6  Stride:2  Padding:2
                    3'b011: begin n_state = KERNEL_3;   end   //   Kernel:3  Stride:2  Padding:1
                    default: n_state = DECIDE;
                endcase
            end

            KERNEL_6: begin
                if(store_cnt == 11)begin
                    n_state = K_6_im2col;
                end
            end

            
            NEXT_CHA:begin
                if(in_channel_cnt == input_channel)begin
                    n_state = REPEAT;
                end
                else begin
                    n_state = KERNEL_6;
                end
            end
            
            REPEAT:begin
                if(next_ten_weight == output_channel/10*270)begin
                    n_state = DONE;
                end else begin
                    n_state = KERNEL_6;
                end
            end
            
            K_6_im2col: begin
                if(add_cnt == 9 && !weight_pause)begin
                    n_state = NEXT_CHA;
                end
                else if(!weight_pause)begin
                    n_state = KERNEL_6;
                end
            end
            
////////////////////////////////////////////////kernel 3
 
            KERNEL_3: begin
                if(store_cnt == 5)begin
                    n_state = K_3_im2col;
                end
            end
            
            K_3_im2col: begin
                if(add_cnt == 9 && !weight_pause)begin
                    n_state = NEXT_CHA3;
                end
                else if(!weight_pause)begin
                    n_state = KERNEL_3;
                end
            end
            
            
            NEXT_CHA3:begin
                if(in_channel_cnt == input_channel)begin
                    n_state = REPEAT3;
                end
                else begin
                    n_state = KERNEL_3;
                end
            end
            
            REPEAT3:begin
                if(next_ten_weight == output_channel/10*input_channel*10*3*3/4)begin
                    n_state = DONE;
                end else begin
                    n_state = KERNEL_3;
                end
            end
            
            DONE:begin
                n_state = DONE;
            end
            
        endcase
    end  
         
    always@(posedge clk or negedge reset)begin
        if(!reset)begin
            
            buffer[0]   <= 0;    buffer[1]   <= 0;    buffer[2]   <= 0;
            buffer[3]   <= 0;    buffer[4]   <= 0;    buffer[5]   <= 0;
            buffer[6]   <= 0;    buffer[7]   <= 0;    buffer[8]   <= 0;
            
            we_rd_en          <= 0;
            we_rd_addr        <= 0;
            weight_cnt        <= 0;
            
            store_cnt         <= 0;
            next_weight       <= 0;
            in_channel_cnt    <= 0; 
            out_channel_cnt   <= 0;
            next_channel      <= 0;
            add_cnt           <= 0;
            repeat_num        <= 0;
            next_ten_weight   <= 0;
            
            we_im2col_valid   <= 0;
            we3_im2col_data   <= 0;
            we6_im2col_data   <= 0;
            
            im2col_done       <= 0;
            
            addr_case         <= 0;
            
        end 
        else if(sudo_reset)begin 
            buffer[0]   <= 0;    buffer[1]   <= 0;    buffer[2]   <= 0;
            buffer[3]   <= 0;    buffer[4]   <= 0;    buffer[5]   <= 0;
            buffer[6]   <= 0;    buffer[7]   <= 0;    buffer[8]   <= 0;
            
            we_rd_en          <= 0;
            we_rd_addr        <= 0;
            weight_cnt        <= 0;
            
            store_cnt         <= 0;
            next_weight       <= 0;
            in_channel_cnt    <= 0; 
            out_channel_cnt   <= 0;
            next_channel      <= 0;
            add_cnt           <= 0;
            repeat_num        <= 0;
            next_ten_weight   <= 0;
            
            we_im2col_valid   <= 0;
            we3_im2col_data   <= 0;
            we6_im2col_data   <= 0;
            
            im2col_done       <= 0;
            
            addr_case         <= 0;
        end
        else if(state == IDLE)begin
            
            buffer[0]   <= 0;    buffer[1]   <= 0;    buffer[2]   <= 0;
            buffer[3]   <= 0;    buffer[4]   <= 0;    buffer[5]   <= 0;
            buffer[6]   <= 0;    buffer[7]   <= 0;    buffer[8]   <= 0;
            
            we_rd_en          <= 0;
            we_rd_addr        <= 0;
            weight_cnt        <= 0;
            
            store_cnt         <= 0;
            next_weight       <= 0;
            in_channel_cnt    <= 0; 
            out_channel_cnt   <= 0;
            next_channel      <= 0;
            add_cnt           <= 0;
            repeat_num        <= 0;
            next_ten_weight   <= 0;
            
            we_im2col_valid   <= 0;
            we3_im2col_data   <= 0;
            we6_im2col_data   <= 0;
            
            im2col_done       <= 0;
            
        end 
    
        else if(state == KERNEL_6)begin
        
            we_rd_addr        <= weight_cnt + next_weight + next_channel + next_ten_weight;
            weight_cnt        <= weight_cnt;
            
            we_im2col_valid   <= 0;
            im2col_done       <= 0;
            
            if(store_cnt < 1)begin
                store_cnt     <= store_cnt + 1;
                weight_cnt    <= 1;
                we_rd_en      <= 1;
            end 
            else if(store_cnt < 3)begin
                buffer[0]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en      <= 1;
            end  
            else if(store_cnt < 4)begin
                buffer[1] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en      <= 1;
            end 
            else if(store_cnt < 5)begin
                buffer[2]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en      <= 1;
            end  
            else if(store_cnt < 6)begin
                buffer[3] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en      <= 1;
            end 
            else if(store_cnt < 7)begin
                buffer[4]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en      <= 1;
            end  
            else if(store_cnt < 8)begin
                buffer[5] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en      <= 1;
            end 
            else if(store_cnt < 9)begin
                buffer[6]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en      <= 1;
            end  
            else if(store_cnt < 10)begin
                buffer[7] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
            end 
            else if(store_cnt < 11)begin
                buffer[8] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
            end
            else if(store_cnt == 11)begin
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
                store_cnt         <= 0;
                weight_cnt        <= 0;
            end
        end 
        

        
        
        else if(state == NEXT_CHA)begin
            next_channel      <= next_channel + 9;
            next_weight       <= 0;
            we_im2col_valid   <= 0;
            im2col_done       <= 0;
        end     
        
        else if(state == REPEAT)begin
            repeat_num       <= repeat_num + 1;
            next_channel     <= 0;
            in_channel_cnt   <= 0;
            we_im2col_valid   <= 0;
            if(repeat_num == total_slicing/10 - 1)begin
                next_ten_weight <= next_ten_weight + 270;
                next_channel     <= 0;
                in_channel_cnt   <= 0;
                repeat_num <= 0;
            end

        end
          
        else if(state == K_6_im2col)begin
            store_cnt   <= 0;
            
            we_rd_en      <= 0;
            we_rd_addr    <= 0;
            
            if(!weight_pause)begin
                    we_im2col_valid <= 1;
                    we6_im2col_data <= {buffer[8],buffer[7],buffer[6],buffer[5],buffer[4],buffer[3],buffer[2],buffer[1],buffer[0]};
                    im2col_done <= 1;
                if(add_cnt < 9)begin
                    next_weight  <= next_weight + input_channel * 9;
                    weight_cnt   <= 0;
                    add_cnt      <= add_cnt + 1;
                end
                else if(add_cnt == 9)begin
                    in_channel_cnt <= in_channel_cnt + 1;
                    weight_cnt     <= 0;
                    add_cnt        <= 0;
                end
            end
        end 

///////////////////////////////////////////////////kernel 3
        
        else if(state == KERNEL_3)begin
            we_rd_addr        <= weight_cnt + next_weight + next_channel + next_ten_weight;
            weight_cnt        <= weight_cnt;
            
            we_im2col_valid   <= 0;
            im2col_done       <= 0;
        
            if(store_cnt < 1)begin
                store_cnt     <= store_cnt + 1;
                weight_cnt    <= 1;
                we_rd_en          <= 1;
            end 
            else if(store_cnt < 3)begin
                buffer[0]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en          <= 1;
            end  
            else if(store_cnt < 4)begin
                buffer[1] <= we_rd_data;
                weight_cnt        <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt         <= store_cnt + 1;
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
            end 
            else if(store_cnt < 5)begin
                buffer[2]       <= we_rd_data;
                weight_cnt      <= weight_cnt + 1;   //9 = kernel 6 <- 0~8 address
                store_cnt       <= store_cnt + 1;
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
            end  
            else if(store_cnt == 5)begin
                we_rd_en          <= 0;
                we_rd_addr        <= 0;
                store_cnt         <= 0;
                weight_cnt        <= 0;
            end
        end


        else if(state == K_3_im2col)begin
            store_cnt   <= 0;
            
            we_rd_en      <= 0;
            we_rd_addr    <= 0;
            
            if(!weight_pause)begin
                if(addr_case == 0)begin
                    we_im2col_valid <= 1;
                    we3_im2col_data <= {buffer[2][15:0],buffer[1],buffer[0]};
//                    im2col_done <= 1;
                    if(add_cnt < 9)begin
                        next_weight  <= next_weight + 3*3*input_channel/4;
                        weight_cnt   <= 0;
                        add_cnt      <= add_cnt + 1;
                    end
                    else if(add_cnt == 9)begin
                        in_channel_cnt <= in_channel_cnt + 1;
                        weight_cnt     <= 0;
                        add_cnt        <= 0;
                        addr_case      <= addr_case + 1;
                    end
                end
                else if(addr_case == 1)begin
                    we_im2col_valid <= 1;
                    we3_im2col_data <= {buffer[2][31:0],buffer[1],buffer[0][63:15]};
//                    im2col_done <= 1;
                    if(add_cnt < 9)begin
                        next_weight  <= next_weight + 3*3*input_channel/4;
                        weight_cnt   <= 0;
                        add_cnt      <= add_cnt + 1;
                    end
                    else if(add_cnt == 9)begin
                        in_channel_cnt <= in_channel_cnt + 1;
                        weight_cnt     <= 0;
                        add_cnt        <= 0;
                        addr_case      <= addr_case + 1;
                    end
                end
                else if(addr_case == 2)begin
                    we_im2col_valid <= 1;
                    we3_im2col_data <= {buffer[2][47:0],buffer[1],buffer[0][63:31]};
//                    im2col_done <= 1;
                    if(add_cnt < 9)begin
                        next_weight  <= next_weight + 3*3*input_channel/4;
                        weight_cnt   <= 0;
                        add_cnt      <= add_cnt + 1;
                    end
                    else if(add_cnt == 9)begin
                        in_channel_cnt <= in_channel_cnt + 1;
                        weight_cnt     <= 0;
                        add_cnt        <= 0;
                        addr_case      <= addr_case + 1;
                    end
                end
                else if(addr_case == 3)begin
                    we_im2col_valid <= 1;
                    we3_im2col_data <= {buffer[2],buffer[1],buffer[0][63:48]};
//                    im2col_done <= 1;
                    if(add_cnt < 9)begin
                        next_weight  <= next_weight + 3*3*input_channel/4;
                        weight_cnt   <= 0;
                        add_cnt      <= add_cnt + 1;
                    end
                    else if(add_cnt == 9)begin
                        in_channel_cnt <= in_channel_cnt + 1;
                        weight_cnt     <= 0;
                        add_cnt        <= 0;
                        addr_case      <= addr_case + 1;
                    end
                end
            end
        end 
        
        else if(state == NEXT_CHA3)begin
            if(addr_case == 4)begin
                next_channel      <= next_channel + 3;
                next_weight       <= 0;
                we_im2col_valid   <= 0;
                im2col_done       <= 0;
                addr_case         <= 0;
            end else begin 
                next_channel      <= next_channel + 2;
                next_weight       <= 0;
                we_im2col_valid   <= 0;
                im2col_done       <= 0;
            end
        end     
        
        else if(state == REPEAT3)begin
            repeat_num       <= repeat_num + 1;
            next_channel     <= 0;
            in_channel_cnt   <= 0;
            we_im2col_valid   <= 0;

            if(repeat_num == total_slicing/10 - 1)begin
                next_ten_weight <= next_ten_weight + input_channel*10*3*3/4;
                next_channel     <= 0;
                in_channel_cnt   <= 0;
                repeat_num <= 0;
            end
        end
 
        else if(state == DONE)begin
        end
    end
    
    
endmodule