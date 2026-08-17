import types_pkg::*;

module control_unit(
    input opcode_e opcode,
    output ctrl_t ctrl
);

    always_comb begin
        ctrl = '0; // defaults every field to 0 initially.
        case(opcode)
            OPC_RTYPE: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_op_hint = ALUOP_RTYPE_ITYPE;
            end

            OPC_ITYPE: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1; // makes sure that the operand b comes from the immediate as opposed to rs2 like Rtype.
                ctrl.alu_op_hint = ALUOP_RTYPE_ITYPE;
                ctrl.imm_sel = IMM_I;
            end

            OPC_LOAD: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1; // rs1 + immediate
                ctrl.mem_read = 1'b1;
                ctrl.wb_sel = WB_MEM;
                ctrl.alu_op_hint = ALUOP_LOAD_STORE;
                ctrl.imm_sel = IMM_I;
            end

            OPC_STORE: begin
                ctrl.alu_src_b = 1'b1; // address = rs1 + immediate
                ctrl.mem_write = 1'b1;
                ctrl.alu_op_hint = ALUOP_LOAD_STORE;
                ctrl.imm_sel = IMM_S;
            end

            OPC_BRANCH: begin
                ctrl.branch = 1'b1;
                ctrl.alu_op_hint = ALUOP_BRANCH;
                ctrl.imm_sel = IMM_B;
            end

            OPC_LUI: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.lui = 1'b1;
                ctrl.imm_sel = IMM_U;
            end

            OPC_AUIPC: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.auipc = 1'b1;
                ctrl.imm_sel = IMM_U;
            end

            OPC_JAL: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.jump = 1'b1;
                ctrl.imm_sel = IMM_J;
                ctrl.wb_sel = WB_PC4;
            end

            OPC_JALR: begin
                ctrl.reg_write = 1'b1;
                ctrl.alu_src_b = 1'b1;
                ctrl.jump = 1'b1;
                ctrl.jalr = 1'b1;
                ctrl.imm_sel = IMM_I;
                ctrl.wb_sel = WB_PC4;
            end
        endcase
    end
endmodule