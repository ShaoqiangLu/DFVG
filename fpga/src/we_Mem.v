`default_nettype none

module we_Mem#(
    parameter 
        AXI_HP_BIT = 64,
        DATA_WIDTH = 16,
        ADDR_WIDTH = 14
)(
    input  wire clk,     
    
    input  wire [2:0]            OPCODE,          
                           
    input  wire wr_en,                                            
    input  wire [ADDR_WIDTH-1:0] wr_addr,    // write address
    input  wire [AXI_HP_BIT-1:0] wr_data,    // write data
    
    //CONVOLUTION
    input  wire C_rd_en,        
    input  wire [ADDR_WIDTH-1:0] C_rd_addr,    // read address
  
    //CONVOLUTION(KERNEL1)
    input  wire C1_rd_en,        
    input  wire [ADDR_WIDTH-1:0] C1_rd_addr,    // read address
    
    output wire [AXI_HP_BIT-1:0] rd_data     // read data
);
    reg rd_en; 
    reg [ADDR_WIDTH-1:0] rd_addr;

    always @(*)begin   
        case(OPCODE)
            3'b000: begin  
                        rd_en   <= C1_rd_en;
                        rd_addr <= C1_rd_addr;   
                    end
            3'b001: begin  
                        rd_en   <= C_rd_en;
                        rd_addr <= C_rd_addr;   
                    end
            3'b011: begin  

                    end
            
            default: begin  
                        rd_en   <= 0;
                        rd_addr <= 0; 
                    end
        endcase
    end
    
    weight_Mem weight_Mem (
        .clka        (clk),        // input wire clka
        .ena         (wr_en),      // input wire ena
        .wea         (wr_en),      // input wire [0 : 0] wea
        .addra       (wr_addr),    // input wire [15 : 0] addra
        .dina        (wr_data),    // input wire [63 : 0] dina
        .clkb        (clk),        // input wire clkb
        .enb         (rd_en),      // input wire enb
        .addrb       (rd_addr),    // input wire [15 : 0] addrb
        .doutb       (rd_data)     // output wire [63 : 0] doutb
    );  

endmodule