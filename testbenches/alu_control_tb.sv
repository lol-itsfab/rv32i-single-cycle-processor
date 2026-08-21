`timescale 1ns / 1ps
import types_pkg::*;

module alu_control_tb;
    // Dut connections
    alu_op_hint_e alu_op_hint;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic lui;
    logic auipc;
    alu_op_e alu_op;

    // Here we are setting both of these vars. to 0 to keep track of the passed and failed test cases.
    int pass_count = 0;
    int fail_count = 0;

    alu_control dut (
        .alu_op_hint (alu_op_hint),
        .funct3 (funct3),
        .funct7 (funct7),
        .lui (lui),
        .auipc (auipc),
        .alu_op (alu_op)
    );

    task automatic check (
        input string name,
        input alu_op_hint_e alu_op_hint_in,
        input logic [2:0] funct3_in,
        input logic [6:0] funct7_in,
        input logic lui_in,
        input logic auipc_in,
        input alu_op_e expected_result
    );
        alu_op_hint = alu_op_hint_in;
        funct3 = funct3_in;
        funct7 = funct7_in;
        lui = lui_in;
        auipc = auipc_in;
        #1;

        if (alu_op === expected_result) begin
            pass_count++;
            $display("PASS: %-10s result:%0d", name, alu_op);
        end else begin
            fail_count++;
            $display("FAIL: %-10s expected: %0d got:%0d", name, expected_result, alu_op);
        end
    endtask

    initial begin
        $display("---- alu_control Testbench start ----");
        // lui and auipac
        check("lui_override", ALUOP_RTYPE_ITYPE, 3'b000, 7'b0000000, 1'b1, 1'b0, ALU_PASS_B);
        check("auipc_override", ALUOP_RTYPE_ITYPE, 3'b000, 7'b0000000, 1'b0, 1'b1, ALU_ADD);

        // load / store / branch hits
        check("load_store", ALUOP_LOAD_STORE, 3'b000, 7'b0000000, 1'b0, 1'b0, ALU_ADD);
        check("branch", ALUOP_BRANCH, 3'b000, 7'b0000000, 1'b0, 1'b0, ALU_SUB); // generic branch case
        check("beq", ALUOP_BRANCH, F3_BEQ, 7'b0, 1'b0, 1'b0, ALU_SUB);
        check("bne", ALUOP_BRANCH, F3_BNE, 7'b0, 1'b0, 1'b0, ALU_SUB);
        check("blt", ALUOP_BRANCH, F3_BLT, 7'b0, 1'b0, 1'b0, ALU_SLT);
        check("bge", ALUOP_BRANCH, F3_BGE, 7'b0, 1'b0, 1'b0, ALU_SLT);
        check("bltu", ALUOP_BRANCH, F3_BLTU, 7'b0, 1'b0, 1'b0, ALU_SLTU);
        check("bgeu", ALUOP_BRANCH, F3_BGEU, 7'b0, 1'b0, 1'b0, ALU_SLTU);

        //R-type and I-type
        check("add", ALUOP_RTYPE_ITYPE, F3_ADD_SUB, F7_NORMAL, 1'b0, 1'b0, ALU_ADD);
        check("sub", ALUOP_RTYPE_ITYPE, F3_ADD_SUB, F7_SRA_SUB, 1'b0, 1'b0, ALU_SUB);
        check("xor", ALUOP_RTYPE_ITYPE, F3_XOR_XORI, F7_NORMAL, 1'b0, 1'b0, ALU_XOR);
        check("or", ALUOP_RTYPE_ITYPE, F3_OR_ORI, F7_NORMAL, 1'b0, 1'b0, ALU_OR);
        check("and", ALUOP_RTYPE_ITYPE, F3_AND_ANDI, F7_NORMAL, 1'b0, 1'b0, ALU_AND);
        check("sll", ALUOP_RTYPE_ITYPE, F3_SLL_SLLI, F7_NORMAL, 1'b0, 1'b0, ALU_SLL);
        check("srl", ALUOP_RTYPE_ITYPE, F3_SRL_SRA, F7_NORMAL, 1'b0, 1'b0, ALU_SRL);
        check("sra", ALUOP_RTYPE_ITYPE, F3_SRL_SRA, F7_SRA_SUB, 1'b0, 1'b0, ALU_SRA);
        check("slt", ALUOP_RTYPE_ITYPE, F3_SLT_SLTI, F7_NORMAL, 1'b0, 1'b0, ALU_SLT);
        check("sltu", ALUOP_RTYPE_ITYPE, F3_SLTU_SLTIU, F7_NORMAL, 1'b0, 1'b0, ALU_SLTU);
        $display("---- alu_control Testbench end ----");
        $display("Passed: %0d   Failed:%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule
