`default_nettype none

module w_slice#(
    parameter
        ROW_WIDTH      =  10,
        COLUMN_WIDTH   =  9,
        DATA_WIDTH     =  16      
)(
    input  wire                               clk,
    input  wire                               reset,
    input  wire                               sudo_reset,
    input  wire                               conv_en,
    
    input  wire [2:0]                         kernel,
    
    //from im2col module
    input  wire                               we_im2col_valid,
    input  wire [DATA_WIDTH * 9 - 1:0]        we3_im2col_data,  //3 kernel OUTPUT     
    input  wire [DATA_WIDTH * 36- 1:0]        we6_im2col_data,   // 16bit x 6kernel x 6kernel x RGB

//======== conv_control <---> slice =============
    // start ro read slice tile
    input  wire                                         weight_read,
    output reg  [COLUMN_WIDTH*DATA_WIDTH*ROW_WIDTH-1:0] weight_data,
    output reg                                          weight_valid,
    
    // to announce 4*4 slice tile done
    output reg                                we_done,
    
    //delete buffer counter
    input  wire                               we_valid_del
);
    
    localparam TILE_COUNT  = 4,                   //to kernel 6
               IMAGE_COUNT = 10;
    localparam IDLE     = 0, 
               DECIDE   = 1,
               K6_LOAD  = 2,
               K3_LOAD  = 3,
               DONE     = 4;
    
    reg [3:0] state, n_state;
    
    reg [DATA_WIDTH * 36 - 1:0] buffer [0:9];    //to kernel 6
    reg [3:0] write_ptr;
    reg [3:0] tile_idx;
    reg [3:0] weight_idx;
    reg active;
    
    always@(posedge clk or negedge reset)begin
        if(!reset)begin
            state <= IDLE;
        end
        else if(sudo_reset)begin
            state <= IDLE;
        end
        else
            state <= n_state;
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
                    3'd1: begin  n_state = DECIDE;   end
                    3'd3: begin  n_state = K3_LOAD;  end
                    3'd6: begin  n_state = K6_LOAD;  end
                    default: n_state = DECIDE;
                endcase
            end
            
            K3_LOAD: begin
                
            end
                        
            K6_LOAD: begin
                
            end
            
            DONE: begin
            end
            
            default: n_state = IDLE;
        endcase
    end
    
    always@(posedge clk or negedge reset)begin
        if(!reset)begin
            buffer[0]   <= 0;  buffer[1]   <= 0;  buffer[2]   <= 0;
            buffer[3]   <= 0;  buffer[4]   <= 0;  buffer[5]   <= 0;
            buffer[6]   <= 0;  buffer[7]   <= 0;  buffer[8]   <= 0;  buffer[9]   <= 0;
            write_ptr   <= 0;
            tile_idx    <= 0;
            active      <= 0;
            
            weight_data  <= 0;
            weight_valid <= 0;
            weight_idx   <= 0;
        end
        else if(sudo_reset)begin
            buffer[0]   <= 0;  buffer[1]   <= 0;  buffer[2]   <= 0;
            buffer[3]   <= 0;  buffer[4]   <= 0;  buffer[5]   <= 0;
            buffer[6]   <= 0;  buffer[7]   <= 0;  buffer[8]   <= 0;  buffer[9]   <= 0;
            write_ptr   <= 0;
            tile_idx    <= 0;
            active      <= 0;
            
            weight_data  <= 0;
            weight_valid <= 0;
            weight_idx   <= 0;
        end
        else if(state == IDLE)begin
            buffer[0]   <= 0;  buffer[1]   <= 0;  buffer[2]   <= 0;
            buffer[3]   <= 0;  buffer[4]   <= 0;  buffer[5]   <= 0;
            buffer[6]   <= 0;  buffer[7]   <= 0;  buffer[8]   <= 0;  buffer[9]   <= 0;
            write_ptr   <= 0;
            tile_idx    <= 0;
            active      <= 0;
            
            weight_data  <= 0;
            weight_valid <= 0;
            weight_idx   <= 0;
        end
        
        else if(state == DECIDE)begin
        end
        else if(state == K3_LOAD)begin
            if (we_im2col_valid && write_ptr < 10) begin
                buffer[write_ptr][143:0] <= we3_im2col_data;       
                write_ptr <= write_ptr + 1;
            end
            
            if (write_ptr == 10 && !active) begin
                active   <= 1;
            end
            else if (we_valid_del == 1)begin           //buffer delete
                write_ptr <= 0;
            end 
            else if (active && weight_read) begin
                weight_valid <= 1;
                weight_data <= {                              
                    buffer[0][143:0],
                    buffer[1][143:0],
                    buffer[2][143:0],
                    buffer[3][143:0],
                    buffer[4][143:0],
                    buffer[5][143:0],
                    buffer[6][143:0],
                    buffer[7][143:0],
                    buffer[8][143:0],
                    buffer[9][143:0]
                };
            end else begin
                weight_valid <= 0;
            end
        end
        
        
        
        else if(state == K6_LOAD)begin
            if (we_im2col_valid && write_ptr < 10) begin
                buffer[write_ptr] <= we6_im2col_data;       
                write_ptr <= write_ptr + 1;
            end
            
            if (write_ptr == 10 && !active) begin
                active   <= 1;
                tile_idx <= 0;
            end
            else if (we_valid_del == 1)begin           //buffer delete
                write_ptr <= 0;
                tile_idx  <= 0;
            end 
            else if (active && weight_read) begin
                weight_valid <= 1;
                weight_data <= {                              
                    buffer[0][tile_idx*144 +: 144],
                    buffer[1][tile_idx*144 +: 144],
                    buffer[2][tile_idx*144 +: 144],
                    buffer[3][tile_idx*144 +: 144],
                    buffer[4][tile_idx*144 +: 144],
                    buffer[5][tile_idx*144 +: 144],
                    buffer[6][tile_idx*144 +: 144],
                    buffer[7][tile_idx*144 +: 144],
                    buffer[8][tile_idx*144 +: 144],
                    buffer[9][tile_idx*144 +: 144]
                };

                if (tile_idx == TILE_COUNT + 1) begin
                    active   <= 0;
                    tile_idx <= 0;
                end
                else begin
                    tile_idx <= tile_idx + 1;
                end
            end else begin
                weight_valid <= 0;
            end
        end
        
        else if(state == DONE)begin
        end
    end
    
    
    
endmodule