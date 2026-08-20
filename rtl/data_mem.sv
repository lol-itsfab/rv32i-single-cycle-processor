import types_pkg::*;

module data_mem (
    input logic clk,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] addr,
    input logic [31:0] write_data,
    input logic [2:0] funct3,
    output logic [31:0] read_data
);

    logic [7:0] dmem [0:1023]; // 1024 bytes ~= 1 Kb of data mem.
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                F3_SB: dmem[addr] <= write_data[7:0];
                F3_SH: begin
                    dmem[addr] <= write_data [7:0];
                    dmem[addr + 1] <= write_data [15:8];
                end
                F3_SW: begin
                    dmem[addr] <= write_data [7:0];
                    dmem[addr + 1] <= write_data [15:8];
                    dmem[addr + 2] <= write_data [23:16];
                    dmem[addr + 3] <= write_data [31:24];
                end
                default: ; // Default is no op (no operation / do nothing).
            endcase
        end
    end

    always_comb begin
        if (mem_read) begin
            case (funct3)
                F3_LW: read_data = {dmem[addr + 3], dmem[addr + 2], dmem[addr + 1], dmem[addr]};
                F3_LBU: read_data = {24'b0, dmem[addr]};
                F3_LB: read_data = {{24{dmem[addr][7]}}, dmem[addr]};
                F3_LH: read_data = {{16{dmem[addr + 1][7]}}, dmem[addr + 1], dmem[addr]};
                F3_LHU: read_data = {16'b0, dmem[addr + 1], dmem[addr]};
                default: read_data = 32'd0;
            endcase
        end else begin
            read_data = 32'd0;
        end
    end


endmodule