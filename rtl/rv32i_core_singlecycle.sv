import types_pkg::*;

module rv32i_core_singlecycle (
    input logic clk, // clock
    input logic rst_n // active low reset
);

    // Fetch Stage
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] instr;

    // Decode Stage
    opcode_e opcode;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;
    logic [2:0] funct3;
    logic [6:0] funct7;
    ctrl_t ctrl;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;

    // Execute Stage
    alu_op_e alu_op;
    logic [31:0] alu_operand_a;
    logic [31:0] alu_operand_b;
    logic [31:0] alu_result;
    logic alu_zero;

    // Memory Stage
    logic [31:0] mem_read_data;

    // Writeback Stage
    logic [31:0] writeback_data;
    logic branch_taken;

    // PC Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'd0;
        else
            pc <= pc_next;
    end

    // Instruction Memory (hardcoded)
    logic [31:0] imem [0:255]; // 256 words
    assign instr = imem[pc[9:2]]; // word-aligned index (8-bits), drops the 2 most LSB's.

    // hardcoded instructions
    initial begin
        // ADDI x1, x0, 5 // x1 = x0 + 5 = 5
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 5, x0, 000, x1, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[0] = 32'b000000000101_00000_000_00001_0010011;

        // ADDI x2, x0, 10 // x2 = x0 + 10 = 10
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 10, x0, 000, x2, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[1] = 32'b000000001010_00000_000_00010_0010011;

        // ADD x3, x1, x2 // x3 = x1 + x2 = 15
        // R-Type funct7, rs2, rs1, funct3, rd, opcode
        // 0000000, x2, x1, 000, x3, 0110011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[2] = 32'b0000000_00010_00001_000_00011_0110011;

        // SW x3, 0(x0) // x0 = x3 store 15 to x0
        // S-Type imm[11:5], rs2, rs1, funct3, imm[4:0], opcode
        // 0000000, x3, x0, 010, 00000, 0100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[3] = 32'b0000000_00011_00000_010_00000_0100011;

        // LW x4, 0(x0) // x4 = x0 + 0 store 15 back into x4
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 0, x0, 010, x4, 0000011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[4] = 32'b000000000000_00000_010_00100_0000011;

        // HERE WE WILL ESTABLISH A KNOWN VALUE IN X5 BEFORE THE BRANCH
        // ADDI x5, x0, 0 // x5 = x0 + 0 = 0
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 0, x0, 000, x5, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[5] = 32'b000000000000_00000_000_00101_0010011;

        // BEQ x0, x0, 8 // (x0 == x0) ? 8 : 4 (always taken)
        // B-Type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0, x0, x0, 000, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[6] = 32'b0000000_00000_00000_000_01000_1100011;

        // ADDI x5, x0, 99 // x5 = x0 + 99
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 99, x0, 000, x5, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[7] = 32'b000001100011_00000_000_00101_0010011;

        // ADDI x6, x0, 7 // x6 = x0 + 7
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 7, x0, 000, x6, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[8] = 32'b000000000111_00000_000_00110_0010011;

        // BNE x0, x0, 8 // x0 = x0 + 8 = 8
        // B-Type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0000000, 0, 0, 001, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[9] = 32'b0000000_00000_00000_001_01000_1100011;

        // ADDI x7, x0, 42 // x7 = x0 + 42 = 42
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 42, x0, 000, x7, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[10] = 32'b000000101010_00000_000_00111_0010011;

        // BLT x1, x2, 8 // x1 < x2 ? 8 : 4
        // B-Type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0000000, 2, 1, 100, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[11] = 32'b0000000_00010_00001_100_01000_1100011;

        // Intention of being skipped, due to previous instruction.
        // ADDI x8, x0, 111 // x8 = x0 + 111
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 111, 0, 000, 8, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[12] = 32'b000001101111_00000_000_01000_0010011;

        // ADDI x8, x0, 8 // x8 = x0 + 8 = 8
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 8, 0, 000, 8, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[13] = 32'b000000001000_00000_000_01000_0010011;

        // BGE x2, x1, 8 // x2 > x1 ? 8 : 4
        // B-Type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0000000, 1, 2, 101, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[14] = 32'b0000000_00001_00010_101_01000_1100011;

        // This instruction should be skipped due to the previous instruction.
        // ADDI x9, x0, 111 // x9 = x0 + 111
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 111, 0, 000, 9, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[15] = 32'b000001101111_00000_000_01001_0010011;

        // ADDI x9, x0, 9 // x9 = x0 + 9
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 9, 0, 000, 9, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[16] = 32'b000000001001_00000_000_01001_0010011;

        // BLTU x1, x2, 8 // x1 < x2 ? 8 : 4
        // B-Type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0000000, x2, x1, 110, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[17] = 32'b0000000_00010_00001_110_01000_1100011;

        // This instruction should be skipped due to the last instruction.
        // ADDI x10, x0, 111 // x10 = x0 + 111
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 111, 0, 000, 10, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[18] = 32'b000001101111_00000_000_01010_0010011;

        // ADDI x10, x0, 10 // x10 = x0 + 10
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 10, 0, 000, 10, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[19] = 32'b000000001010_00000_000_01010_0010011;

        // BGEU x1, x2, 8 // x1 >= x2 ? 8 : 4
        // B-type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // 0000000, 2, 1, 111, 01000, 1100011
        // 7 bits, 5 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[20] = 32'b0000000_00010_00001_111_01000_1100011;

        // ADDI x11, x0, 11 // x11 = x0 + 11 = 11
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 11, 0, 000, 11, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[21] = 32'b000000001011_00000_000_01011_0010011;

        // LUI x12, 1 // x12 = 0x00001000 = 4096
        // U-Type imm[31:12], rd, opcode
        // 0x00001, 12, 0110111
        // 20 bits, 5 bits, 7 bits
        imem[22] = 32'b00000000000000000001_01100_0110111;

        // AUIPC x13, 1 // x13 = 4096 + 92 (current pc) = 4188
        // U-Type imm[31:12], rd, opcode
        // 0x00001, 13, 0010111
        // 20 bits, 5 bits, 7 bits
        imem[23] = 32'b00000000000000000001_01101_0010111;

        // JAL x14, 8 // x14 = PC + 4 = 100
        // J-Type imm[20|10:1|11|19:12], rd, opcode
        // 0x00001, 14, 1101111
        // 20 bits, 5 bits, 7 bits
        imem[24] = 32'b00000000100000000000_01110_1101111;

        // Should be skipped due to the last instruction (JAL)
        // ADDI x15, x0 ,111
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 111, 0, 000, 15, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[25] = 32'b000001101111_00000_000_01111_0010011;

        // JAL should target this instruction.
        // ADDI x15, x0, 55 // x15 = x0 + 55 = 55
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 55, 0, 000, 15, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[26] = 32'b000000110111_00000_000_01111_0010011;

        // Target address for JALR 
        // ADDI x16, x0, 124 // x16 = x0 + 124 = 124
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 124, 0, 000, 16, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[27] = 32'b000001111100_00000_000_10000_0010011;

        // JALR x17, x16, 0 // x17 = PC + 4 = 116, PC = x16 + 0
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 0, 16, 000, 17, 1100111
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[28] = 32'b000000000000_10000_000_10001_1100111;

        // skip over imem[29] and imem[30] since jalr skips over these 2.

        // ADDI x18, x0, 18 // x18 = x0 + 18 = 18
        // I-Type imm[11:0], rs1, funct3, rd, opcode
        // 18, 0, 000, 18, 0010011
        // 12 bits, 5 bits, 3 bits, 5 bits, 7 bits
        imem[31] = 32'b000000010010_00000_000_10010_0010011;

    end

    assign opcode = opcode_e'(instr[6:0]);
    assign rd_addr = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7 = instr[31:25];

    control_unit control_unit_inst (
        .opcode (opcode),
        .ctrl (ctrl)
    );

    regfile regfile_inst (
        .clk (clk),
        .reg_write (ctrl.reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr (rd_addr),
        .rd_data (writeback_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    imm_gen imm_gen_inst (
        .instr (instr),
        .imm_sel (ctrl.imm_sel),
        .imm_out (imm)
    );

    alu_control alu_control_inst (
        .alu_op_hint (ctrl.alu_op_hint),
        .funct3 (funct3),
        .funct7 (funct7),
        .lui (ctrl.lui),
        .auipc (ctrl.auipc),
        .alu_op (alu_op)
    );

    assign alu_operand_a = ctrl.auipc ? pc : rs1_data;
    assign alu_operand_b = ctrl.alu_src_b ? imm : rs2_data;

    alu alu_inst (
        .a (alu_operand_a),
        .b (alu_operand_b),
        .op (alu_op),
        .result (alu_result),
        .zero (alu_zero)
    );

    data_mem data_mem_inst (
        .clk (clk),
        .mem_read (ctrl.mem_read),
        .mem_write (ctrl.mem_write),
        .addr (alu_result),
        .write_data (rs2_data),
        .funct3 (funct3),
        .read_data (mem_read_data)
    );

    always_comb begin
        branch_taken = 1'b0;
        if (ctrl.branch) begin
            case (funct3_branch_e'(funct3))
                F3_BEQ: branch_taken = alu_zero;
                F3_BNE: branch_taken = ~alu_zero;
                F3_BLT: branch_taken = alu_result[0];
                F3_BGE: branch_taken = ~alu_result[0];
                F3_BLTU: branch_taken = alu_result[0];
                F3_BGEU: branch_taken = ~alu_result[0];
                default: branch_taken = 1'b0; // finally implemented the other branch types.
                //default: branch_taken = 1'b0; // for other branch types not implemented yet
            endcase
        end
    end
    // PC Next Value Mux
    always_comb begin
        if (ctrl.jump && ctrl.jalr)
            pc_next = alu_result;
        else if (ctrl.jump)
            pc_next = pc + imm;
        else if (branch_taken)
            pc_next = pc + imm;
        else
            pc_next = pc + 32'd4; //(pc + 4)
    end

    // Writeback Mux
    always_comb begin
        case (ctrl.wb_sel)
            WB_ALU: writeback_data = alu_result;
            WB_MEM: writeback_data = mem_read_data;
            WB_PC4: writeback_data = pc + 32'd4;
            default: writeback_data = alu_result;
        endcase
    end

endmodule