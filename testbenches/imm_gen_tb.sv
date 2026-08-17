`timescale 1ns / 1ps
import types_pkg::*;

module imm_gen_tb;
    // DUT connections
    logic [31:0] instr;
    imm_sel_e imm_sel;
    logic [31:0] imm_out;

    // initializing 2 vars. pass_count and fail_count to 0.
    int pass_count = 0;
    int fail_count = 0;

    // instantiating the imm_gen
    imm_gen dut(
        .instr (instr),
        .imm_sel (imm_sel),
        .imm_out (imm_out)
    );

    task automatic check(
        input string name,
        input logic [31:0] instr_in,
        input imm_sel_e sel_in,
        input logic [31:0] expected
    );
        instr = instr_in;
        imm_sel = sel_in;
        #1; // wait 1 time unit (1 ns) so the output is computed so that we can check

        if (imm_out === expected) begin
            pass_count++;
            $display("PASS: %-15s imm_out=%0d (0x%08h)", name, imm_out, imm_out);
        end else begin
            fail_count++;
            $display("FAIL: %-15s expected=%0d (0x%08h) got=%0d (0x%08h)", name, expected, expected, imm_out, imm_out);
        end
    endtask

    initial begin
        $display("---- imm_gen Testbench start ----");
        // I-type imm[11:0], rs1, funct3, rd, opcode
        check("I_type_pos", 32'b0000_0011_0010_00010_000_00001_0010011, IMM_I, 32'd50);
        check("I_type_neg", 32'b1111_1111_1111_00011_000_00001_0010011, IMM_I, -32'd1);
        // S-type imm[11:5], rs2, rs1, funct3, imm[4:0], opcode
        check("S_type_pos", 32'b0000011_00101_00010_010_00100_0100011, IMM_S, 32'd100);
        // B-type imm[12|10:5], rs2, rs1, funct3, imm[4:1|11], opcode
        // imm[12], imm[11], imm[10:5], imm[4:1], imm[0]
        // imm = 8; 13-bits.
        // 0_0_000000_0100_0
        check("B_type_BEQ", 32'b0000000_00110_00101_000_01000_1100011, IMM_B, 32'd8);
        // U-type imm[31:12], rd, opcode
        check("U_type_lui", 32'b00000000000000000001_00001_0110111, IMM_U, 32'd4096);
        // J-type imm[20|10:1|11|19:12], rd, opcode
        // imm[20], imm[19:12], imm[11], imm[10:1], imm[0]
        // imm = 16; 21 bits -> 10000
        check("J_type_jal", 32'b00000001000000000000_00001_1101111, IMM_J, 32'd16);
        $display("---- imm_gen Testbench done ----");
        $display("Passed: %0d   Failed: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule