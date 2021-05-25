`timescale 1ns/1ps

// registers
`define r1 4'b0001
`define r2 4'b0010
`define r3 4'b0011
`define r4 4'b0100

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011

`define INSTRUCTION_size 11

module my_chip_TB;
	reg [`INSTRUCTION_size-1:0] INSTRUCTION;
	reg clk, reset;
	
	my_chip little_boy(INSTRUCTION, clk, reset);
	
	initial begin
		reset = 1'b0;
		clk = 1'b0;
		#10
		reset = 1'b1;
		#10
		reset = 1'b0;
		#5
		INSTRUCTION = {`load, `r1, 4'b0110};  #50
		INSTRUCTION = 11'b0000_0000_111;		  #50
		INSTRUCTION = {`load, `r2, 4'b0110};  #100
		INSTRUCTION = 11'b0000_0001_000;		  #50
		INSTRUCTION = {`mov, `r3, `r2};		  #100
		INSTRUCTION = {`add, `r3, `r1};		  #200
		INSTRUCTION = {`sub, `r1, `r2};		
	 end
	 
	 always #25 clk = ~clk;
endmodule
