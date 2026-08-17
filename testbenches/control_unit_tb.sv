`timescale 1ns / 1ps
import types_pkg::*;

module control_unit_tb;
    // DUT connections
    opcode_e opcode;
    ctrl_t ctrl;

    // vars. to keep track of passed and failed cases.
    int pass_count = 0;
    int fail_count = 0;

    // instantiating control_unit
    control_unit dut (
        .opcode (opcode),
        .ctrl (ctrl)
    );

    task automatic check(
        input string name,
        input opcode_e opc,
        input logic       exp_reg_write,
        input logic       exp_mem_read,
        input logic       exp_mem_write,
        input logic       exp_alu_src_b,
        input logic       exp_branch,
        input logic       exp_jump,
        input logic       exp_jalr,
        input logic       exp_lui,
        input logic       exp_auipc,
        input alu_op_hint_e exp_alu_op_hint,
        input imm_sel_e     exp_imm_sel,
        input wb_sel_e       exp_wb_sel
    );
        opcode = opc;
        #1;

        if (ctrl.reg_write === exp_reg_write &&
            ctrl.mem_read === exp_mem_read &&
            ctrl.mem_write === exp_mem_write &&
            ctrl.alu_src_b === exp_alu_src_b &&
            ctrl.branch === exp_branch &&
            ctrl.jump === exp_jump &&
            ctrl.jalr === exp_jalr &&
            ctrl.lui === exp_lui &&
            ctrl.auipc === exp_auipc &&
            ctrl.alu_op_hint === exp_alu_op_hint &&
            ctrl.imm_sel === exp_imm_sel &&
            ctrl.wb_sel === exp_wb_sel) begin
            pass_count++;
            $display("PASS: %-15s", name);
        end else begin
            fail_count++;
            $display("FAIL: %-15s", name);
            $display("  field           expected  got");
            $display("  reg_write       %b         %b", exp_reg_write, ctrl.reg_write);
            $display("  mem_read        %b         %b", exp_mem_read, ctrl.mem_read);
            $display("  mem_write       %b         %b", exp_mem_write, ctrl.mem_write);
            $display("  alu_src_b       %b         %b", exp_alu_src_b, ctrl.alu_src_b);
            $display("  branch          %b         %b", exp_branch, ctrl.branch);
            $display("  jump            %b         %b", exp_jump, ctrl.jump);
            $display("  jalr            %b         %b", exp_jalr, ctrl.jalr);
            $display("  lui             %b         %b", exp_lui, ctrl.lui);
            $display("  auipc           %b         %b", exp_auipc, ctrl.auipc);
            $display("  alu_op_hint     %0d         %0d", exp_alu_op_hint, ctrl.alu_op_hint);
            $display("  imm_sel         %0d         %0d", exp_imm_sel, ctrl.imm_sel);
            $display("  wb_sel          %0d         %0d", exp_wb_sel, ctrl.wb_sel);
        end
    endtask

    initial begin
        $display("----control_unit Testbench start----");
        check("R-type", OPC_RTYPE, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALUOP_RTYPE_ITYPE, IMM_I, WB_ALU
        );

        check("I-type", OPC_ITYPE, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALUOP_RTYPE_ITYPE, IMM_I, WB_ALU
        );

        check("LOAD-type", OPC_LOAD, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALUOP_LOAD_STORE, IMM_I, WB_MEM
        );

        check("STORE-type", OPC_STORE, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALUOP_LOAD_STORE, IMM_S, WB_ALU
        );

        check("Branch-type", OPC_BRANCH, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, ALUOP_BRANCH, IMM_B, WB_ALU
        );

        check("LUI-type", OPC_LUI, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALUOP_RTYPE_ITYPE, IMM_U, WB_ALU
        );

        check("AUIPC-type", OPC_AUIPC, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, ALUOP_RTYPE_ITYPE, IMM_U, WB_ALU
        );

        check("JAL-type", OPC_JAL, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, ALUOP_RTYPE_ITYPE, IMM_J, WB_PC4
        );

        check("JALR-type", OPC_JALR, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, ALUOP_RTYPE_ITYPE, IMM_I, WB_PC4
        );
        $display("----control_unit Testbench end----");
        $display("Passed: %0d   Failed: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule