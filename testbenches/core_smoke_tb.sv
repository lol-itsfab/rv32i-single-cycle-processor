`timescale 1ns / 1ps
import types_pkg::*;

module core_smoke_tb;
    logic clk = 0;
    logic rst_n;
    logic [4:0] dbg_addr;
    logic [31:0] dbg_data;
    always #5 clk = ~clk;

    rv32i_core_singlecycle dut (
        .clk (clk),
        .rst_n (rst_n),
        .dbg_addr (dbg_addr),
        .dbg_data (dbg_data)
    );

    initial begin
        dbg_addr = 5'd0;
        rst_n = 0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // 26 here since 25 instructions actually execute and we also add a cycle
        repeat(26) @(posedge clk);
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
        $display("x12 = %0d (expect 4096, LUI)", dut.regfile_inst.registers[12]);
        $display("x13 = %0d (expect 4188, AUIPC)", dut.regfile_inst.registers[13]);
        $display("x14 = %0d (expect 100, JAL return address)", dut.regfile_inst.registers[14]);
        $display("x15 = %0d (expect 55, JAL target)", dut.regfile_inst.registers[15]);
        $display("x16 = %0d (expect 124, target address for JALR)", dut.regfile_inst.registers[16]);
        $display("x17 = %0d (expect 116, JALR return address)", dut.regfile_inst.registers[17]);
        $display("x18 = %0d (expect 18, JALR target)", dut.regfile_inst.registers[18]);

        // new debug port
        dbg_addr = 5'd18;
        #1;
        $display("dbg_data(x18) = %0d (expect 18, via debug port)", dbg_data);

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
            dut.regfile_inst.registers[11] == 32'd11 &&
            dut.regfile_inst.registers[12] == 32'd4096 &&
            dut.regfile_inst.registers[13] == 32'd4188 &&
            dut.regfile_inst.registers[14] == 32'd100 &&
            dut.regfile_inst.registers[15] == 32'd55 &&
            dut.regfile_inst.registers[16] == 32'd124 &&
            dut.regfile_inst.registers[17] == 32'd116 &&
            dut.regfile_inst.registers[18] == 32'd18 &&
            dbg_data == 32'd18)
            $display("SMOKE TEST PASSED");
        else
            $display("SMOKE TEST FAILED");
        $finish;
    end
endmodule