`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/14 20:56:55
// Design Name: 
// Module Name: id_ex
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
`include"defines.vh"

module id_ex(
    input wire rst,
    input wire clk,
    
    input wire[`AluSelBus] id_alusel,
    input wire[`AluOpBus] id_aluop,
    
    input wire[`RegBus] id_reg1,
    input wire[`RegBus] id_reg2,
    
    input wire[`RegAddrBus] id_wd,
    input wire id_wreg,
    
    output reg[`AluSelBus] ex_alusel,
    output reg[`AluOpBus] ex_aluop,
    
    output reg[`RegBus] ex_reg1,
    output reg[`RegBus] ex_reg2,
    
    output reg[`RegAddrBus] ex_wd,
    output reg ex_wreg
    );
    
    always @ (posedge clk) begin 
        if (rst == `Enable) begin
            ex_alusel <= `ALUS_NOP ;
            ex_aluop <= `ALU_NOP ;
            ex_reg1 <= `Zero ;
            ex_reg2 <= `Zero ;
            ex_wd <= `NopRegAddr ;
            ex_wreg <= 0 ;
        end else begin 
            ex_alusel <= id_alusel ;
            ex_aluop <= id_aluop ;
            ex_reg1 <= id_reg1 ;
            ex_reg2 <= id_reg2 ;
            ex_wd <= id_wd ;
            ex_wreg <= id_wreg ;
        end
    end
    
endmodule