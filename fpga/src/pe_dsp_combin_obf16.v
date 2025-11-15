`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2025 06:11:38 PM
// Design Name: 
// Module Name: pe_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//


module pe_dsp_combine_obf16
(
    input                   clk                 ,
    input       [48-1:0]    dsp_prod            ,//[51-1:0]
    input                   sign_bc             ,
    input                   sign_bd             ,
    input       [9-1:0]     sum_exp_bc          ,
    input       [9-1:0]     sum_exp_bd          ,
    output reg  [16-1:0]    dout_bc=0           ,
    output reg  [16-1:0]    dout_bd=0       
);
    
    
    reg         [9-1:0]    r_sum_exp_bc=0      ;
    reg         [9-1:0]    r_sum_exp_bd=0      ;
    
    wire        [16-1:0]   prod_bc             ;
    wire        [16-1:0]   prod_bd             ;
    reg         [10-1:0]   exp_bc=0            ;
    reg         [10-1:0]   exp_bd=0            ;
    reg         [7-1:0]    mts_bc=0            ;
    reg         [7-1:0]    mts_bd=0            ;
    

    assign prod_bc =       dsp_prod[31:16]     ;
    assign prod_bd =       dsp_prod[15:0]      ;
    
    always @(posedge clk) begin
        r_sum_exp_bc <= sum_exp_bc;
        r_sum_exp_bd <= sum_exp_bd; 
    end


    always @(posedge clk) begin
        begin
            if(prod_bc[15]) begin
                exp_bc <= sum_exp_bc + 1;
                mts_bc <= {prod_bc[14:8]};
            end
            else begin
                exp_bc <= sum_exp_bc;
                mts_bc <= {prod_bc[13:7]};
            end
            
            if(r_sum_exp_bc != 9'd0 )
                dout_bc <= {sign_bc,exp_bc[7:0],mts_bc};
            else
                dout_bc <= {sign_bc,15'd0};
                ///!!!! 15'd0 can't meet the require , must be 31'd0
        end 
    end
    
    
    


    always @(posedge clk) begin
        begin
            if(prod_bd[15]) begin
                exp_bd <= sum_exp_bd + 1;
                mts_bd <= {prod_bd[14:8]};
            end
            else begin
                exp_bd <= sum_exp_bd;
                mts_bd <= {prod_bd[13:7]};
            end
            
            if(r_sum_exp_bd != 9'd0 )
                dout_bd <= {sign_bd,exp_bd[7:0],mts_bd};
            else
                dout_bd <= {sign_bd,15'd0};
        end 
    end



endmodule
