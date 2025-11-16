`default_nettype none

module out_Mem#(
    parameter 
        AXI_HP_BIT = 64,
        DATA_WIDTH = 16,
        ADDR_WIDTH = 14
)(
    input  wire                  clk,       
    input  wire [2:0]            OPCODE,                     
                         
    input  wire                  out_rd_en,                          
    input  wire [ADDR_WIDTH-1:0] out_rd_addr,    // read address
    
    //CONVOLUTION
    input  wire                  C_wr_en, 
    input  wire [ADDR_WIDTH-1:0] C_wr_addr,    // write address
    input  wire [AXI_HP_BIT-1:0] C_wr_data,    // write data
    
    //CONVOLUTION(KERNEL1)
    input  wire                  C1_wr_en, 
    input  wire [ADDR_WIDTH-1:0] C1_wr_addr,    // write address
    input  wire [AXI_HP_BIT-1:0] C1_wr_data,    // write data
    
    //MAXPOOLING 
    input  wire                  M_wr_en,
    input  wire [ADDR_WIDTH-1:0] M_wr_addr,
    input  wire [AXI_HP_BIT-1:0] M_wr_data,    // write data
   
    output wire [AXI_HP_BIT-1:0] rd_data     // read data
);

    reg wr_en; 
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [AXI_HP_BIT-1:0] wr_data;

    reg rd_en; 
    reg [ADDR_WIDTH-1:0] rd_addr;

    always @(*)begin   
        case(OPCODE)
            3'b000: begin  
                        wr_en   <= C1_wr_en;
                        wr_addr <= C1_wr_addr; 
                        wr_data <= C1_wr_data;  
                    end
            3'b001: begin  
                        wr_en   <= C_wr_en;
                        wr_addr <= C_wr_addr; 
                        wr_data <= C_wr_data;  
                    end
            3'b010: begin  
                        wr_en   <= M_wr_en;
                        wr_addr <= M_wr_addr; 
                        wr_data <= M_wr_data;  
                    end

            default: begin  
                        wr_en   <= 0;
                        wr_addr <= 0; 
                        wr_data <= 0;  
                    end
        endcase
    end
    
//    always @(*)begin   
//        case(accul_bram_EN)
//            1'b1: begin  
//                        rd_en   <= out_rd_en;
//                        rd_addr <= out_rd_addr; 
//                    end
//            default: begin  
//                        rd_en   <= out_rd_en;
//                        rd_addr <= out_rd_addr;  
//                    end
//        endcase
//    end

    output_Mem output_Mem (
        .clka        (clk),        // input wire clka
        .ena         (wr_en),      // input wire ena
        .wea         (wr_en),      // input wire [0 : 0] wea
        .addra       (wr_addr),    // input wire [15 : 0] addra
        .dina        (wr_data),    // input wire [63 : 0] dina
        .clkb        (clk),        // input wire clkb
        .enb         (out_rd_en),      // input wire enb
        .addrb       (out_rd_addr),    // input wire [15 : 0] addrb
        .doutb       (rd_data)     // output wire [63 : 0] doutb
    );

endmodule