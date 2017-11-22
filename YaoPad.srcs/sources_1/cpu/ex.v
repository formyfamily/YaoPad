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

module ex(
    input wire rst,
    
    input wire[`AluSelBus] alusel_i,
    input wire[`AluOpBus] aluop_i,
    
    input wire[`RegBus] reg1_i,
    input wire[`RegBus] reg2_i,
    
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    
    input wire[`RegBus] lo_i,
    input wire[`RegBus] hi_i,

    input wire wb_whilo_i,
    input wire[`RegBus] wb_hi_i,
    input wire[`RegBus] wb_lo_i,

    input wire mem_whilo_i,
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,

    input wire div_ready_i,
    input wire[`DoubleRegBus] div_result_i,
    input wire[`RegBus] inst_i,

    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    output reg whilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    output reg div_start_o, 
    output reg signed_div_o,
    output reg[`RegBus] div_opdata1_o,
    output reg[`RegBus] div_opdata2_o,

    output wire[`AluOpBus] aluop_o,
    output wire[`RegBus] mem_addr_o,
    output wire[`RegBus] reg2_o,

    output reg stallreq
    );

    reg[`RegBus] logicres ;
    reg[`RegBus] shiftres ;
    reg[`RegBus] moveres ;
    reg[`RegBus] arithres ;
    reg[`DoubleRegBus] mulres ;
    reg[`RegBus] hi ;
    reg[`RegBus] lo ;

    assign reg2_o = reg2_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
    assign aluop_o = aluop_i;
    always @ (*) begin // logic operations 
        if (rst == `Enable) begin 
            logicres <= `Zero ;
        end else begin 
            case(aluop_i)
                `ALU_OR: begin 
                    logicres <= (reg1_i | reg2_i) ;
                end 
                `ALU_AND: begin
                    logicres <= (reg1_i & reg2_i) ;
                end
                `ALU_XOR: begin
                    logicres <= (reg1_i ^ reg2_i) ;
                end
                `ALU_NOR: begin
                    logicres <= ~(reg1_i | reg2_i) ;                    
                end
                default: begin
                    logicres <= `Zero ; 
                end
            endcase
        end
    end

    always @ (*) begin // shift operations
        if (rst == `Enable) begin 
            shiftres <= `Zero ;
        end else begin 
            case(aluop_i)
                `ALU_SLL: begin
                    shiftres <= reg2_i << reg1_i[4:0] ;   
                end
                `ALU_SRL: begin
                    shiftres <= reg2_i >> reg1_i[4:0] ; 
                end
                `ALU_SRA: begin
                    shiftres <= ((({32{reg2_i[31]}} << reg1_i[4:0]) >> reg1_i[4:0]) ^ {32{reg2_i[31]}}) | (reg2_i >> reg1_i[4:0]) ;
                end   
                default: begin
                    shiftres <= `Zero ; 
                end
            endcase
        end
    end

    always @ (*) begin // move operations
        if (rst == `Enable) begin 
            moveres <= `Zero ;
            hi = `Zero; lo = `Zero ;
        end else begin 
            if (mem_whilo_i == `Enable) begin hi = mem_hi_i; lo = mem_lo_i ; end
            else if(wb_whilo_i == `Enable) begin hi = wb_hi_i; lo = wb_lo_i ; end
            else begin hi = hi_i; lo = lo_i; end
            case(aluop_i)
                `ALU_MOVN, `ALU_MOVZ: begin
                    moveres <= reg1_i ;
                end
                `ALU_MFHI: begin
                    moveres <= hi ;
                end
                `ALU_MFLO: begin
                    moveres <= lo ;
                end
                default: begin
                    moveres <= `Zero ; 
                end
            endcase
        end
    end

    // some pre-computed values used in arithmetic operations
    
    wire[`RegBus] reg2_i_mux ;
    wire[`RegBus] reg1_i_not ;
    wire[`RegBus] add_sum ;
    wire is_overflow ; // overflow 
    wire is_equal ; // zero 
    wire is_less ; // negative 
    assign reg1_i_not = (aluop_i == `ALU_CLO) ? (~reg1_i) : (reg1_i) ;
    assign reg2_i_mux = ((aluop_i == `ALU_SUB) ||  (aluop_i == `ALU_SUBU) || (aluop_i == `ALU_SLT)) ? (~reg2_i+1) : reg2_i ;
    assign add_sum = reg1_i + reg2_i_mux ;
    assign is_equal = (reg1_i == reg2_i) ;
    assign is_overflow = ((!reg1_i[31] && !reg2_i_mux[31]) && add_sum[31]) || ((reg1_i[31] && reg2_i_mux[31]) && (!add_sum[31])) ;
    assign is_less = (aluop_i == `ALU_SLT) ? ((reg1_i[31] && !reg2_i[31]) || ((reg1_i[31] == reg2_i[31]) && add_sum[31])) : (reg1_i < reg2_i) ;

    always @ (*) begin // arithmetic operations
        if (rst == `Enable) begin 
            arithres <= `Zero ;
        end else begin 
            case(aluop_i)
                `ALU_SLT, `ALU_SLTU: begin
                    arithres <= is_less ;
                end
                `ALU_ADD, `ALU_SUB: begin
                    arithres <= add_sum ;
                end
                `ALU_ADDU, `ALU_SUBU: begin
                    arithres <= add_sum ;
                end
                `ALU_CLZ, `ALU_CLO: begin
                    arithres <=  reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 :
                                reg1_i_not[29] ? 2 : reg1_i_not[28] ? 3 :
                                reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
                                reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 :
                                reg1_i_not[23] ? 8 : reg1_i_not[22] ? 9 :
                                reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
                                reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 :
                                reg1_i_not[17] ? 14 : reg1_i_not[16] ? 15 :
                                reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
                                reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 :
                                reg1_i_not[11] ? 20 : reg1_i_not[10] ? 21 :
                                reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 :
                                reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 :
                                reg1_i_not[5] ? 26 : reg1_i_not[4] ? 27 :
                                reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 :
                                reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32 ;
                end
                default: begin
                    arithres <= `Zero ;
                end
            endcase
        end
    end

    // some pre-computed values used in mul operations

    wire[`RegBus] mul_op1 ;
    wire[`RegBus] mul_op2 ;
    wire[`DoubleRegBus] mul_ans ;
    assign mul_op1 = ((aluop_i == `ALU_MUL || aluop_i == `ALU_MULT) && reg1_i[31]) ? (~reg1_i+1) : reg1_i ;
    assign mul_op2 = ((aluop_i == `ALU_MUL || aluop_i == `ALU_MULT) && reg2_i[31]) ? (~reg2_i+1) : reg2_i ;
    assign mul_ans = mul_op1 * mul_op2 ;

    always @ (*) begin // mul operations
        if (rst == `Enable) begin 
            mulres = `DZero ;
        end else begin 
            case(aluop_i)
                `ALU_MUL, `ALU_MULT: begin
                    mulres <= ((reg1_i[31] ^ reg2_i[31]) == 1) ? (~mul_ans+1) : mul_ans ;
                end
                `ALU_MULTU: begin
                    mulres <= mul_ans ;
                end
                default: begin
                    mulres <= `DZero ;
                end
            endcase
        end
    end

    always @ (*) begin // hi-lo operations
        if (rst == `Enable) begin 
            hi_o = `Zero; lo_o = `Zero ;
            stallreq = `Zero ;
        end else begin 
            div_start_o <= 0 ;
            case(aluop_i)
                `ALU_MTHI: begin
                    whilo_o <= 1 ;
                    hi_o <= reg1_i ;
                end
                `ALU_MTLO: begin
                    whilo_o <= 1 ;
                    lo_o <= reg1_i ;
                end
                `ALU_MULT, `ALU_MULTU: begin
                    whilo_o <= 1 ;
                    hi_o <= mulres[63:32] ;
                    lo_o <= mulres[31:0] ;
                end
                `ALU_DIV, `ALU_DIVU: begin
                    div_start_o <= (~div_ready_i) ;
                    div_opdata1_o <= reg1_i ;
                    div_opdata2_o <= reg2_i ;
                    signed_div_o <= (aluop_i == `ALU_DIV) ;
                    stallreq = (~div_ready_i) ;
                    hi_o <= div_result_i[63:32] ;
                    lo_o <= div_result_i[31:0] ;
                    whilo_o <= 1 ;
                end
                default: begin
                    whilo_o <= 0 ;
                    hi_o = `Zero; lo_o = `Zero ;
                end
            endcase
        end
    end
    
    always @ (*) begin // choose answer
        if (rst == `Enable) begin 
            wdata_o <= `Zero ;
            wd_o <= `NopRegAddr ;
            wreg_o <= 0 ;
        end else begin 
            wd_o <= wd_i ;
            if(((aluop_i == `ALU_ADD) || (aluop_i == `ALU_SUB)) && is_overflow) begin
                wreg_o <= 0 ;
            end else begin wreg_o <= wreg_i ; end 
            case(alusel_i) 
                `ALUS_LOGIC: begin
                    wdata_o <= logicres ;
                end
                `ALUS_SHIFT: begin
                    wdata_o <= shiftres ;
                end
                `ALUS_MOVE: begin
                    wdata_o <= moveres ;
                end
                `ALUS_ARITHMETIC: begin
                    wdata_o <= arithres ;
                end
                `ALUS_MUL: begin
                    wdata_o = mulres[31:0] ;
                end
                default: begin
                    wdata_o <= `Zero ;
                end
            endcase 
        end
    end
endmodule
