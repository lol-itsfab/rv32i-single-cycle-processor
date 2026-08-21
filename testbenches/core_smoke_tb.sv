`timescale 1ns / 1ps
import types_pkg::*;

module core_smoke_tb;
    logic clk = 0;
    logic rst_n;
    always #5 clk = ~clk;

    rv32i_core_singlecycle dut (
        .clk (clk),
        .rst_n (rst_n)
    );

    initial begin
        rst_n = 0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        repeat(20) @(posedge clk);
        #1;

        $display("pc = %0d", dut.pc);
        $display("x1 = %0d (expect 5)", dut.regfile_inst.registers[1]);
        $display("x2 = %0d (expect 10)", dut.regfile_inst.registers[2]);
        $display("x3 = %0d (expect 15)", dut.regfile_inst.registers[3]);
        $display("x4 = %0d (expect 15, loaded back from mem)", dut.regfile_inst.registers[4]);
        $display("x5 = %0d (expect 0, set then skipped by BEQ)", dut.regfile_inst.registers[5]);
        $display("x6 = %0d (expect 7, branch target executed)", dut.regfile_inst.registers[6]);
        $display("x7 = %0d (expect 42, BNE not taken (fell through))", dut.regfile_inst.registers[7]);
        $display("x8 = %0d (expect 8, blt taken - skips 111)", dut.regfile_inst.registers[8]);
        $display("x9 = %0d (expect 9, bge taken - skips 111)", dut.regfile_inst.registers[9]);
        $display("x10 = %0d (expect 10, bltu taken - skips 111)", dut.regfile_inst.registers[10]);
        $display("x11 = %0d (expect 11, bgeu not taken (fell through))", dut.regfile_inst.registers[11]);

        if (dut.regfile_inst.registers[1] == 32'd5 &&
            dut.regfile_inst.registers[2] == 32'd10 &&
            dut.regfile_inst.registers[3] == 32'd15 &&
            dut.regfile_inst.registers[4] == 32'd15 &&
            dut.regfile_inst.registers[5] == 32'd0 &&
            dut.regfile_inst.registers[6] == 32'd7 &&
            dut.regfile_inst.registers[7] == 32'd42 &&
            dut.regfile_inst.registers[8] == 32'd8 &&
            dut.regfile_inst.registers[9] == 32'd9 &&
            dut.regfile_inst.registers[10] == 32'd10 &&
            dut.regfile_inst.registers[11] == 32'd11)
            $display("SMOKE TEST PASSED");
        else
            $display("SMOKE TEST FAILED");
        $finish;
    end
endmodule