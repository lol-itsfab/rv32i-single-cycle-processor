import types_pkg::*;

module imm_gen (
    input logic [31:0] instr,
    input imm_sel_e imm_sel,
    output logic [31:0] imm_out
);

    always_comb begin
        case (imm_sel)
            IMM_I: imm_out = {{20{instr[31]}}, instr[31:20]};
            IMM_S: imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B: imm_out = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U: imm_out = {instr[31:12], 12'b0}; //point of this is to set the upper 20 bits so no sign extension necessary.
            IMM_J: imm_out = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm_out = 32'd0;
        endcase
    end
endmodule