// Constants // 
`define Enable 1'b1
`define Disable 1'b0
`define True 1'b1
`define False 1'b0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Zero 32'h00000000
`define DZero 64'h0000000000000000

`define RegNum 20

// Length of different data type// 
`define RegLen 32
`define DoubleRegLen 64
`define RegLenLog 5
`define MemNumLog 18 

// Buses // 
`define AluOpBus 7:0
`define AluSelBus 2:0
`define AddrBus 31:0
`define InstBus 31:0
`define MemNum 262144 // The actual memory size is 256KB 
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegIdBus 0:31
`define DoubleRegBus 63:0


// Instruction Number //
`define EXE_ORI 6'b001101
`define EXE_ANDI 6'b001100
`define EXE_XORI 6'b001110
`define EXE_LUI 6'b001111
`define EXE_SPECIAL 6'b000000
`define EXE_PREF 6'b110011
`define EXE_NOP 6'b000000

// Alu Operation Number // 
`define ALU_OR 8'b00100101
`define ALU_AND 8'b00100100
`define ALU_XOR 8'b00100110
`define ALU_NOR 8'b00100111
`define ALU_SLL 8'b00000000
`define ALU_SRL 8'b00000010
`define ALU_SRA 8'b00000011
`define ALU_SLLV 8'b00000100
`define ALU_SRLV 8'b00000110
`define ALU_SRAV 8'b00000111
`define ALU_SYNC 8'b00001111
`define ALU_NOP 8'b00000000

// Alu Suboperation Number // 
`define ALUS_SHIFT 3'b010
`define ALUS_LOGIC 3'b001
`define ALUS_NOP 3'b000

`define NopRegAddr 5'b00000