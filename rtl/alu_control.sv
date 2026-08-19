import types_pkg::*;

module alu_control (
    input alu_op_hint_e alu_op_hint,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic lui,
    input logic auipc,
    output alu_op_e alu_op
);
    always_comb begin
        if (lui) begin
            alu_op = ALU_PASS_B;
        end else if (auipc) begin
            alu_op = ALU_ADD;
        end else begin
            case (alu_op_hint)
                ALUOP_LOAD_STORE: alu_op = ALU_ADD;
                ALUOP_BRANCH: alu_op = ALU_SUB;
                ALUOP_RTYPE_ITYPE: begin
                    case(funct3)
                        F3_ADD_SUB: alu_op = alu_op_e'((funct7 == F7_SRA_SUB) ? ALU_SUB : ALU_ADD); //need an explicit cast otherwise not treated as alu_op_e type.
                        F3_XOR_XORI: alu_op = ALU_XOR;
                        F3_OR_ORI: alu_op = ALU_OR;
                        F3_AND_ANDI: alu_op = ALU_AND;
                        F3_SLL_SLLI: alu_op = ALU_SLL;
                        F3_SRL_SRA: alu_op = alu_op_e'((funct7 == F7_SRA_SUB) ? ALU_SRA : ALU_SRL); //need an explicit cast otherwise not treated as alu_op_e type.
                        F3_SLT_SLTI: alu_op = ALU_SLT;
                        F3_SLTU_SLTIU: alu_op = ALU_SLTU;
                        default: alu_op = ALU_ADD;
                    endcase
                end
                default: alu_op = ALU_ADD;
            endcase
        end
    end
endmodule