module de10_top (
    input logic CLOCK_50, // the 50MHz oscillator on the board
    input logic [3:0] KEY, // the 4 pushbuttons on the DE-10
    input logic [9:0]SW, // the 10 switches on the DE-10
    output logic [9:0] LEDR // the 10 LEDs on the DE-10
);

    logic [31:0] dbg_data;
    // This connects necessary hardware to the inputs.
    rv32i_core_singlecycle core_inst (
        .clk (CLOCK_50),
        .rst_n (KEY[0]),
        .dbg_addr (SW[4:0]),
        .dbg_data (dbg_data)
    );

    assign LEDR = dbg_data[9:0];
endmodule