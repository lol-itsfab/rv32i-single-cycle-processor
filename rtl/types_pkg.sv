package types_pkg;

typedef enum logic [6:0] {
    OPC_RTYPE = 7'b0110011, // For Register-types
    OPC_ITYPE = 7'b0010011, // For Immediate-types
    OPC_LOAD = 7'b0000011, // For Loads
    OPC_STORE = 7'b0100011, // For Stores
    OPC_BRANCH = 7'b1100011, // For Branches
    OPC_JAL = 7'b1101111, // For Jump And Link
    OPC_JALR = 7'b1100111, // For Jump And Link Register
    OPC_LUI = 7'b0110111, // For Load Upper Immediate
    OPC_AUIPC = 7'b0010111 // For Add Upper Immediate to PC
} opcode_e;

typedef enum logic [2:0] {
    F3_ADD_SUB = 3'b000, //For ADD, SUB, ADDI, 
    F3_XOR_XORI = 3'b100, // For XOR, XORI
    F3_OR_ORI = 3'b110, // For OR, ORI
    F3_AND_ANDI = 3'b111, // For AND, ANDI
    F3_SLL_SLLI = 3'b001, // For SLL, SLLI
    F3_SRL_SRA = 3'b101, // For SRL, SRA, SRLI, SRAI
    F3_SLT_SLTI = 3'b010, // For SLT, SLTI
    F3_SLTU_SLTIU = 3'b011 // For SLTU, SLTIU
} funct3_alu_e;

typedef enum logic [2:0] {
    F3_LB = 3'b000, // Load Byte
    F3_LH = 3'b001, // Load Half
    F3_LW = 3'b010, // Load Word
    F3_LBU = 3'b100, // Load Byte Unsigned
    F3_LHU = 3'b101 // Load Half Unsigned
} funct3_load_e;

typedef enum logic [2:0] {
    F3_SB = 3'b000, // Store Byte
    F3_SH = 3'b001, // Store Half
    F3_SW = 3'b010 // Store Word
} funct3_store_e;

typedef enum logic [2:0] {
    F3_BEQ = 3'b000, // Branch If Equal
    F3_BNE = 3'b001, // Branch Not Equal
    F3_BLT = 3'b100, // Branch Less Than
    F3_BGE = 3'b101, // Branch Greater Than Or Equal
    F3_BLTU = 3'b110, // Branch Less Than Unsigned
    F3_BGEU = 3'b111 // Branch Greater than Unsigned
} funct3_branch_e;

localparam logic [6:0] F7_NORMAL = 7'b0000000; //0x00 for every R-type instruction except SRA and SUB
localparam logic [6:0] F7_SRA_SUB = 7'b0100000; //0x20 for ONLY SRA and SUB

typedef enum logic [3:0] {
    ALU_ADD, // Add
    ALU_SUB, // Subtract
    ALU_XOR, // Xor
    ALU_OR, // Or
    ALU_AND, // And
    ALU_SLL, // Shift Left Logical
    ALU_SRL, // Shift Right Logical
    ALU_SRA, // Shift Right Arithmetic
    ALU_SLT, // Set Less Than
    ALU_SLTU, // Set Less Than Unsigned
    ALU_PASS_B // Passes the value of B to the result
} alu_op_e;

typedef enum logic [1:0] {
    ALUOP_RTYPE_ITYPE, // Check Funct3 and Funct7 to decode what operation it is
    ALUOP_LOAD_STORE, // Just Add (offset + register)
    ALUOP_BRANCH // Just subtract (rs1 - rs2)
} alu_op_hint_e;

typedef enum logic [2:0] {
    IMM_I, // Selects the immediate for an I-type instruction
    IMM_S, // Selects the immediate for an S-type instruction
    IMM_B, // Selects the immediate for an B-type instruction
    IMM_U, // Selects the immediate for an U-type instruction
    IMM_J // Selects the immediate for an J-type instruction
} imm_sel_e;

typedef enum logic [1:0] {
    WB_ALU, // writeback source comes from ALU result.
    WB_MEM, // writeback source comes from mem data.
    WB_PC4 // writeback source comes from PC + 4.
} wb_sel_e;

typedef struct packed {
    logic reg_write; // writes the ALU or MEM result back to the destination register, rd if 1.
    logic mem_read; // This is a load if 1.
    logic mem_write; // This is a store if 1.
    logic alu_src_b; // This is the ALU oprerand for B, if 1 its an immediate, if 0 its the second register source, rs2.
    logic branch; // This is a branch instruction if 1.
    logic jump; // This is a jump instruction, JALR or JAL if 1. 
    logic jalr; // This is a specifically the JALR instruction if 1.
    logic lui; // This is specifically the LUI instruction if 1.
    logic auipc; // This is specifically the AUIPC instruction if 1.
    alu_op_hint_e alu_op_hint; // This allows alu_control to know how to determine the ALU operation.
    imm_sel_e imm_sel; // This shows which type of immediate format is being worked with (I, S, B, U, J).
    wb_sel_e wb_sel; // This is a writeback source for memory data, either from ALU, MEM, or PC + 4.
} ctrl_t;
endpackage : types_pkg