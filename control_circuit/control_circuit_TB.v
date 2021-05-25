`timescale 1ns / 1ps

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011

// registers
`define r1 4'b0001
`define r2 4'b0010
`define r3 4'b0011
`define r4 4'b0100

module control_circuit_TB;
	reg clk, reset;
	reg [10:0] instruction;
	wire [3:0] Rin, Rout;
	wire ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, ALU_mode;
	
	control_circuit CC
	(.INSTRUCTION(instruction),
	 .clk(clk), .reset(reset),
	 .Rin(Rin), .Rout(Rout),
	 .ALU_a_in(ALU_a_in), .ALU_g_in(ALU_g_in), .ALU_g_out(ALU_g_out),
	 .Done(Done), .External_load(External_load), .ALU_mode(ALU_mode));
	 
	 initial begin
		reset = 1'b0;
		clk = 1'b0;
		#10
		reset = 1'b1;
		#10
		reset = 1'b0;
		#5
		instruction = {`load, `r1, 4'b0110};
		#50
		instruction = 11'b10101010101;
		#50
		instruction = {`mov, `r1, `r2};
		#100
		instruction = {`add, `r3, `r4};
		#200
		instruction = {`sub, `r2, `r4};
	 end
	 
	 always #25 clk = ~clk;
endmodule
