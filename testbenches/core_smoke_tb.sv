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

        repeat(6) @(posedge clk);
        #1;

        $display("pc = %0d", dut.pc);
        $display("x1 = %0d (expect 5)", dut.regfile_inst.registers[1]);
        $display("x2 = %0d (expect 10)", dut.regfile_inst.registers[2]);
        $display("x3 = %0d (expect 15)", dut.regfile_inst.registers[3]);
        $display("x4 = %0d (expect 15, loaded back from mem)", dut.regfile_inst.registers[4]);

        if (dut.regfile_inst.registers[1] == 32'd5 &&
            dut.regfile_inst.registers[2] == 32'd10 &&
            dut.regfile_inst.registers[3] == 32'd15 &&
            dut.regfile_inst.registers[4] == 32'd15)
            $display("SMOKE TEST PASSED");
        else
            $display("SMOKE TEST FAILED");
        $finish;
    end
endmodule