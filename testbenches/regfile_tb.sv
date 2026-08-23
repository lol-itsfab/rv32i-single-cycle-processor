`timescale 1ns / 1ps
import types_pkg::*;

module regfile_tb;
    // DUT connections
    logic clk;
    logic reg_write;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [4:0] dbg_addr;
    logic [31:0] dbg_data;

    // This is our pass / fail tracking.
    int pass_count = 0;
    int fail_count = 0;

    // Clock generation since we are working with always_ff
    initial clk = 0;
    always #5 clk = ~clk;

    regfile dut (
        .clk (clk),
        .reg_write (reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr (rd_addr),
        .rd_data (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .dbg_addr (dbg_addr),
        .dbg_data (dbg_data)
    );

    task automatic check_write_read (
        input string name,
        input logic write_en,
        input logic [4:0] waddr,
        input logic [31:0] wdata,
        input logic [4:0] raddr1,
        input logic [4:0] raddr2,
        input logic [31:0] expected1,
        input logic [31:0] expected2
    );

        reg_write = write_en;
        rd_addr = waddr;
        rd_data = wdata;

        @(posedge clk); // a wait statement 
        #1;
        reg_write = 0;
        rs1_addr = raddr1;
        rs2_addr = raddr2;
        #1;

        if (rs1_data === expected1 && rs2_data === expected2) begin
            pass_count++;
            $display("PASS: %-20s rs1=%0d rs2=%0d", name, rs1_data, rs2_data);
        end else begin
            fail_count++;
            $display("FAIL: %-20s expected rs1=%0d rs2=%0d, got rs1=%0d rs2=%0d", name, expected1, expected2, rs1_data, rs2_data);
        end
    endtask

    task automatic check_dbg_read (
        input string name,
        input logic [4:0] dbg_addr_in,
        input logic [31:0] expected
    );
        dbg_addr = dbg_addr_in;
        #1;
        if (dbg_data === expected) begin
            pass_count++;
            $display("PASS: %-20s dbg_data=%0d", name, dbg_data);
        end else begin
            fail_count++;
            $display("FAIL: %-20s expected=%0d got=%0d", name, expected, dbg_data);
        end
    endtask
    initial begin
        $display("----Regfile Testbench start----");
        check_write_read("basic_write_read", 1, 5'd5, 32'd123, 5'd5, 5'd5, 32'd123, 32'd123);
        check_write_read("x0_write_ignored", 1, 5'd0, 32'd999, 5'd0, 5'd0, 32'd0, 32'd0);
        check_write_read("x0_read_after_other_write", 1, 5'd10, 32'd77, 5'd0, 5'd10, 32'd0, 32'd77);
        check_write_read("write_disabled_setup", 1, 5'd8, 32'd200, 5'd8, 5'd8, 32'd200, 32'd200);
        check_write_read("write_disabled", 0, 5'd8, 32'd555, 5'd8, 5'd8, 32'd200, 32'd200);
        check_write_read("independent_reads", 1, 5'd5, 32'd123, 5'd5, 5'd10, 32'd123, 32'd77);

        // debug port tests
        check_dbg_read("dbg_x5", 5'd5, 32'd123);
        check_dbg_read("dbg_x10", 5'd10, 32'd77);
        check_dbg_read("dbg_x0_always_zero", 5'd0, 32'd0);
        $display("----Regfile Testbench done----");
        $display("Passed: %0d   Failed:%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED.");
        else
            $display("SOME TESTS FAILED.");
        $finish;
    end
endmodule

