`timescale 1ns / 1ps

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011

// registers
`define r1 3'b001
`define r2 3'b010
`define r3 3'b011
`define r4 3'b100


module control_circuit_TB;
	reg clk, reset;
	reg [10:0] instruction;
	wire [3:0] Rin, Rout;
	wire ALU_a_in, ALU_g_in, ALU_g_out, Done, External_data, ALU_mode;
	
	control_circuit CC
	(.INSTRUCTION(instruction),
	 .clk(clk), .reset(reset),
	 .Rin(Rin), .Rout(Rout),
	 .ALU_a_in(ALU_a_in), .ALU_g_in(ALU_g_in), .ALU_g_out(ALU_g_out),
	 .Done(Done), .External_data(External_data), .ALU_mode(ALU_mode));
	 
	 initial begin
		reset = 1'b0;
		clk = 1'b0;
		#10
		reset = 1'b1;
		#10
		reset = 1'b0;
		#5
		instruction = {`load, `r1, 5'b00110};
		#50
		instruction = {`mov, `r1, `r2, 2'b00};
		#100
		instruction = {`add, `r3, `r4, 2'b00};
		#200
		instruction = {`sub, `r2, `r4, 2'b00};
	 end
	 
	 always #25 clk = ~clk;
endmodule
