import types_pkg::*;

module regfile (
    input logic clk,
    input logic reg_write,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    input logic [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    // This output and input port are for debugging
    // debug port is read only so it does not need to interact with the ff block.
    input logic [4:0] dbg_addr,
    output logic [31:0] dbg_data
);

    logic [31:0] registers [31:0];// 32 registers with 32 bits each.
    assign rs1_data = (rs1_addr == 0) ? 0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 0) ? 0 : registers[rs2_addr];
    assign dbg_data = (dbg_addr == 0) ? 0 : registers[dbg_addr];

    always_ff @(posedge clk) begin
        if (reg_write && rd_addr!= 0) begin
            registers[rd_addr] <= rd_data;
        end
    end
endmodule