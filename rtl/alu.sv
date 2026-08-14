import types_pkg::*;

module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_op_e op,
    output logic [31:0] result,
    output logic zero
);

    // Here the lower 5 bits of b are meaningful for instructions like SLL, SRL, and SRA so we only need 5 bits of b
    // without this there will be a warning about being sensitive to all bits in b[31:0].
    logic[4:0] shamt; 
    assign shamt = b[4:0];
    always_comb begin
        case(op)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_XOR: result = a^b;
            ALU_OR: result = a | b;
            ALU_AND: result = a & b;
            ALU_SLL: result = a << shamt;
            ALU_SRL: result = a >> shamt;
            ALU_SRA: result = $signed(a) >>> shamt;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            ALU_PASS_B: result = b;
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule