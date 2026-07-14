`timescale 1ns / 1ps
import types_pkg::*;

module alu_tb;
    //This is our Device Under Test connections
    logic [31:0]a, b;
    alu_op_e op;
    logic [31:0] result;
    logic zero;

    //Here we are keeping track of the pass and fail counts across the run
    int pass_count = 0;
    int fail_count = 0;

    //Instantiating the ALU
    alu dut (
        .a (a),
        .b (b),
        .op (op),
        .result (result),
        .zero (zero)
    );

    task automatic check(
        input string name,
        input logic [31:0] a_in,
        input logic [31:0] b_in,
        input alu_op_e op_in,
        input logic [31:0] expected_result
    );

        a = a_in;
        b = b_in;
        op = op_in;
        #1;

        if (result === expected_result) begin
            pass_count++;
            $display("PASS: %-10s result=%0d (0x%08h)", name, result, result);
        end else begin
            fail_count++;
            $display("FAIL: %-10s expected=%0d (0x%08h) got=%0d", name, expected_result, expected_result, result, result);
        end
    endtask

    initial begin
        $display("---- ALU Testbench start ----");
        //ADD and SUB
        check("ADD", 32'd10, 32'd15, ALU_ADD, 32'd25);
        check("SUB", 32'd20, 32'd8, ALU_SUB, 32'd12);
        check("SUB_neg", 32'd5, 32'd10, ALU_SUB, -32'd5);

        //BitWise
        check("XOR", 32'hFF00FF00, 32'h0F0F0F0F, ALU_XOR, 32'hF00FF00F);
        check("OR", 32'hF0F0F0F0, 32'h0F0F0F0F, ALU_OR, 32'hFFFFFFFF);
        check("AND", 32'hFF00FF00, 32'h0FF00FF0, ALU_AND, 32'h0F000F00);

        //Shifts
        check("SLL", 32'h00000001, 32'd4, ALU_SLL, 32'h00000010);
        check("SRL", 32'hF0000000, 32'd4, ALU_SRL, 32'h0F000000);
        check("SRA_pos", 32'h40000000, 32'd4, ALU_SRA, 32'h04000000);
        check("SRA_neg", 32'hF0000000, 32'd4, ALU_SRA, 32'hFF000000);
        check("SLL_max", 32'h00000001, 32'd31, ALU_SLL, 32'h80000000);
        check("SLL_upperbits", 32'h00000001, 32'hFFFFFFE1, ALU_SLL, 32'h00000002);
         
        //Set less than
        check("SLT_true", 32'hFFFFFFFF, 32'd1, ALU_SLT, 32'd1);
        check("SLT_false", 32'd5, 32'd1, ALU_SLT, 32'd0);
        check("SLTU_true", 32'd1, 32'hFFFFFFFF, ALU_SLTU, 32'd1);
        check("SLTU_false", 32'hFFFFFFFF, 32'd1, ALU_SLTU, 32'd0);

        //The LUI pass through
        check("PASS_B", 32'hDEADBEEF, 32'h12345678, ALU_PASS_B, 32'h12345678);

        //The Zero flag check for branches
        a = 32'd7;
        b = 32'd7;
        op = ALU_SUB;
        #1;
        if (zero === 1'b1) begin
            pass_count++;
            $display("PASS: zero_flag (equal operands)");
        end else begin
            fail_count++;
            $display("FAIL: zero_flag exepcted = 1 got =%0b", zero);
        end

        a = 32'd7;
        b = 32'd8;
        op = ALU_SUB;
        #1;
        if (zero === 1'b0) begin
            pass_count++;
            $display("PASS: zero_flag (unequal operands)");
        end else begin
            fail_count++;
            $display("FAIL: zero_flag expected = 0 got = %0b", zero);
        end

        $display("---- ALU Testbench done ----");
        $display("Passed: %0d \nFailed: %0d", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule