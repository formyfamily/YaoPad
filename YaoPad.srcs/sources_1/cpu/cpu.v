`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/14 22:42:56
// Design Name: 
// Module Name: cpu
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
`include"pc.v"
`include"if_id.v"
`include"id.v"
`include"regfile.v"
`include"id_ex.v"
`include"ex.v"
`include"ex_mem.v"
`include"mem.v"
`include"mem_wb.v"
`include"hilo.v"
`include"ctrl.v"
`include"div.v"

module cpu(
    input wire rst, 
    input wire clk,
    input wire[`InstBus] rom_data_i,
    output wire[`InstBus] rom_addr_o,
    output wire rom_ce_o
    );
    
    wire[`AddrBus] pc ;
    wire[`AddrBus] id_pc_i ;
    wire[`InstBus] id_inst_i ;
    
    wire[`AluOpBus] id_aluop_o ;
    wire[`AluSelBus] id_alusel_o ;
    wire[`RegBus] id_reg1_o ;
    wire[`RegBus] id_reg2_o ;
    wire id_wreg_o ;
    wire[`RegAddrBus] id_wd_o ;
    wire[`RegBus] id_inst_o ;
    
    wire[`AluOpBus] ex_aluop_i ;
    wire[`AluSelBus] ex_alusel_i ;
    wire[`RegBus] ex_reg1_i ;
    wire[`RegBus] ex_reg2_i ;
    wire ex_wreg_i ;
    wire[`RegAddrBus] ex_wd_i ;
    
    wire ex_wreg_o ;
    wire[`RegAddrBus] ex_wd_o ;
    wire[`RegBus] ex_wdata_o ;
    wire ex_whilo_o ;
    wire [`RegBus] ex_hi_o ;
    wire [`RegBus] ex_lo_o ;
    wire[`RegBus] ex_inst_o ;

    wire mem_wreg_i ;
    wire[`RegAddrBus] mem_wd_i ;
    wire[`RegBus] mem_wdata_i ;
    wire mem_whilo_i ;
    wire [`RegBus] mem_hi_i ;
    wire [`RegBus] mem_lo_i ;

    wire mem_wreg_o ;
    wire[`RegAddrBus] mem_wd_o ;
    wire[`RegBus] mem_wdata_o ;
    wire mem_whilo_o ;
    wire [`RegBus] mem_hi_o ;
    wire [`RegBus] mem_lo_o ;
    
    wire wb_wreg_i ;
    wire[`RegAddrBus] wb_wd_i ;
    wire[`RegBus] wb_wdata_i ;
    wire wb_whilo_i ;
    wire [`RegBus] wb_hi_i ;
    wire [`RegBus] wb_lo_i ;

    wire wb_whilo_o ;
    wire [`RegBus] wb_hi_o ;
    wire [`RegBus] wb_lo_o ;
    
    wire reg1_read ;
    wire reg2_read ;
    wire[`RegBus] reg1_data ;
    wire[`RegBus] reg2_data ;
    wire[`RegAddrBus] reg1_addr ;
    wire[`RegAddrBus] reg2_addr ;

    wire[`RegBus] hi_o ;
    wire[`RegBus] lo_o ;

    wire stalleq_from_id ;
    wire stalleq_from_ex ;
    wire[5:0] stall ;

    wire div_start ;
    wire div_annul ;
    wire[`RegBus] div_opdata1 ;
    wire[`RegBus] div_opdata2 ;
    wire div_signed ;
    wire[`DoubleRegBus] div_result ;
    wire div_ready ;

    assign rom_addr_o = pc;
    pc_rom pc_rom0(
        .clk(clk), .rst(rst), 
        .pc(pc), 
        .ce(rom_ce_o),
        .stall(stall)
    ) ;
    
    if_id if_id0(
        .clk(clk), .rst(rst),
        .if_pc(pc), 
        .if_inst(rom_data_i), 
        .id_pc(id_pc_i), 
        .id_inst(id_inst_i),
        .stall(stall)
    ) ;
    
    id id0(
        .rst(rst),
        .pc_i(id_pc_i),
        .inst_i(id_inst_i),
        
        .reg1_data_i(reg1_data),
        .reg2_data_i(reg2_data),
        
        .reg1_read_o(reg1_read),
        .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),
        .reg2_addr_o(reg2_addr),
        
        .aluop_o(id_aluop_o),
        .alusel_o(id_alusel_o),
        .reg1_o(id_reg1_o),
        .reg2_o(id_reg2_o),
        .wd_o(id_wd_o),
        .wreg_o(id_wreg_o),
        .inst_o(id_inst_o),

        .mem_wdata_i(mem_wdata_o), 
        .mem_wd_i(mem_wd_o), 
        .mem_wreg_i(mem_wreg_o), 
        .ex_wdata_i(ex_wdata_o), 
        .ex_wd_i(ex_wd_o), 
        .ex_wreg_i(ex_wreg_o),

        .stallreq(reqstalleq_from_id)
    ) ;
    
    regfile regfile0(
        .clk(clk), .rst(rst),
        
        .we(wb_wreg_i),
        .waddr(wb_wd_i),
        .wdata(wb_wdata_i), 
        
        .re1(reg1_read),
        .raddr1(reg1_addr),
        .rdata1(reg1_data), 
        
        .re2(reg2_read),
        .raddr2(reg2_addr),
        .rdata2(reg2_data)               
    ) ;
    
    id_ex id_ex0(
        .clk(clk), .rst(rst),        
        
        .id_aluop(id_aluop_o),
        .id_alusel(id_alusel_o),
        .id_inst(id_inst_o),
        .id_reg1(id_reg1_o),
        .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),
        .id_wreg(id_wreg_o),
        
        .ex_aluop(ex_aluop_i),
        .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),
        .ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),
        .ex_wreg(ex_wreg_i),
        .ex_inst(ex_inst_o),
        .stall(stall)
    ) ;
    
    ex ex0(
        .rst(rst),

        .aluop_i(ex_aluop_i),
        .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
        .reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),
        .wreg_i(ex_wreg_i),
        
        .lo_i(lo_o),
        .hi_i(hi_o),
        .wb_whilo_i(wb_whilo_o),
        .wb_hi_i(wb_hi_o),
        .wb_lo_i(wb_lo_o),
        .mem_whilo_i(mem_whilo_o),
        .mem_hi_i(mem_hi_o),
        .mem_lo_i(mem_lo_o),
        
        .wd_o(ex_wd_o),
        .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),
        .whilo_o(ex_whilo_o),
        .hi_o(ex_hi_o),
        .lo_o(ex_lo_o),

        .div_ready_i(div_ready),
        .div_result_i(div_result),
        .div_start_o(div_start),
        .signed_div_o(div_signed),
        .div_opdata1_o(div_opdata1),
        .div_opdata2_o(div_opdata2),

        .stallreq(stalleq_from_ex)
    ) ;
    
    ex_mem ex_mem0(
        .clk(clk), .rst(rst),
        
        .ex_wd(ex_wd_o),
        .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .ex_whilo(ex_whilo_o),
        .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),
        
        .mem_wd(mem_wd_i),
        .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),
        .mem_whilo(mem_whilo_i),
        .mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),

        .stall(stall) 
    ) ;
    
    mem mem0(
        .rst(rst),
        
        .wd_i(mem_wd_i),
        .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),
        .whilo_i(mem_whilo_i),
        .hi_i(mem_hi_i),
        .lo_i(mem_lo_i),
        
        .wd_o(mem_wd_o),
        .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),
        .whilo_o(mem_whilo_o),
        .hi_o(mem_hi_o),
        .lo_o(mem_lo_o)
    ) ;
    
    mem_wb mem_wb0(
        .clk(clk), .rst(rst), 
        
        .mem_wd(mem_wd_o),
        .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),
        .mem_whilo(mem_whilo_o),
        .mem_hi(mem_hi_o),
        .mem_lo(mem_lo_o),
        
        .wb_wd(wb_wd_i),
        .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),
        .wb_whilo(wb_whilo_i),
        .wb_hi(wb_hi_i),
        .wb_lo(wb_lo_i),
        .stall(stall) 
    ) ;

    hilo hilo0(
        .clk(clk), .rst(rst),

        .we(wb_whilo_i),
        .hi_i(wb_hi_i),
        .lo_i(wb_lo_i),
        .hi_o(hi_o),
        .lo_o(lo_o)
    ) ;

    ctrl ctrl0(
        .rst(rst),
        .stalleq_from_id(stalleq_from_id),
        .stalleq_from_ex(stalleq_from_ex),
        .stall(stall)
    ) ;

    assign div_annul = 0 ;
    div div0(
        .clk(clk), .rst(rst),

        .start_i(div_start),
        .annul_i(div_annul),
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .signed_div_i(div_signed),
        .result_o(div_result),
        .ready_o(div_ready)
    ) ;
endmodule
