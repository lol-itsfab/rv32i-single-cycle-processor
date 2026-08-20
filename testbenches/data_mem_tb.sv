`timescale 1ns/1ps
import types_pkg::*;

module data_mem_tb;
    // DUT connections
    logic clk;
    logic mem_read;
    logic mem_write;
    logic [31:0] addr;
    logic [31:0] write_data;
    logic [2:0] funct3;
    logic [31:0] read_data;

    int pass_count = 0;
    int fail_count = 0;

    initial clk = 0;
    always #5 clk = ~clk;

    data_mem dut (
        .clk (clk),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .addr (addr),
        .write_data (write_data),
        .funct3 (funct3),
        .read_data (read_data)
    );

    // This performs a write and waits for a clock edge so the write actually lands.
    task automatic do_write(
        input logic [31:0] addr_in,
        input logic [31:0] write_data_in,
        input logic [2:0] funct3_in
    );
        addr = addr_in;
        write_data = write_data_in;
        funct3 = funct3_in;
        mem_write = 1'b1;
        mem_read = 1'b0;
        @(posedge clk);
        #1; // wait one time unit to avoid race condition.
        mem_write = 1'b0;
    endtask

    // This performs a read and checks it against an expected value, this is combinational so no clock wait.
    task automatic check_read (
        input string name,
        input logic [31:0] addr_in,
        input logic [2:0] funct3_in,
        input logic [31:0] expected
    );
        addr = addr_in;
        funct3 = funct3_in;
        mem_read = 1'b1;
        #1;
        if (read_data === expected) begin
            pass_count++;
            $display("PASS: %-15s read_data: %0d (0x%08h)", name, read_data, read_data);
        end else begin
            fail_count++;
            $display("FAIL: %-15s expected: %0d (0x%08h) got = %0d (0x%08h)", name, expected, expected, read_data, read_data);
        end
        mem_read = 1'b0;
    endtask

    initial begin
        $display("---- data_mem Testbench start ----");
        // sw and lw (write a full word then read it back).
        do_write(32'd0, 32'hDEADBEEF, F3_SW);
        check_read("LW_readback", 32'd0, F3_LW, 32'hDEADBEEF);

        // sb and lb / lbu
        do_write(32'd4, 32'h000000FF, F3_SB);
        check_read("LB_signed", 32'd4, F3_LB, -32'b1); // should sign extend to 0xFFFFFFFF
        check_read("LBU_unsigned", 32'd4, F3_LBU, 32'd255); // should zero extend here to 0x000000FF

        // sh and lh / lhu
        do_write(32'd8, 32'h0000FF80, F3_SH);
        check_read("LH_signed", 32'd8, F3_LH, -32'd128); // sign extends 0xFF80 = -128
        check_read("LHU_unsigned", 32'd8, F3_LHU, 32'd65408); // should zero extend from 0xFF80 = 65408

        // after doing the SW we must check the individual
        check_read("byte0_of_word", 32'd0, F3_LBU, 32'hEF); // LSB
        check_read("byte1_of_word", 32'd1, F3_LBU, 32'hBE);
        check_read("byte2_of_word", 32'd2, F3_LBU, 32'hAD);
        check_read("byte3_of_word", 32'd3, F3_LBU, 32'hDE); // MSB

        $display("---- data_mem Testbench end ----");
        $display("Passed: %0d   Failed: %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule