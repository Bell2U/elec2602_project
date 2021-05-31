`timescale 1ns/1ps

// registers
`define r0 4'b0000
`define r1 4'b0001
`define r2 4'b0010
`define r3 4'b0011
`define r4 4'b0100
`define r5 4'b0101
`define r6 4'b0110
`define r7 4'b0111
`define r8 4'b1000
`define r9 4'b1001
`define r10 4'b1010
`define r11 4'b1011
`define r12 4'b1100
`define r13 4'b1101
`define r14 4'b1110
`define r15 4'b1111

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011

`define INSTRUCTION_size 11
`define reg_width 16

module my_chip_TB;
	reg [`reg_width-1:0] INSTRUCTION;
	reg clk, reset;
	localparam padding_bits = {(`reg_width-`INSTRUCTION_size){1'b0}};
	
	my_chip little_boy(INSTRUCTION, clk, reset);
	
	initial begin
		reset = 1'b0;
		clk = 1'b0;
		#10
		reset = 1'b1;
		#10
		reset = 1'b0;
		#5
		INSTRUCTION = {padding_bits, `load, `r1, 4'b0110};  #50
		INSTRUCTION = 16'b0000_0000_0000_0111;		  			 #50
		INSTRUCTION = {padding_bits, `load, `r2, 4'b0110};  #100
		INSTRUCTION = 16'b0000_0000_0000_1000;		  			 #50
		INSTRUCTION = {padding_bits, `mov, `r3, `r2};		  #100
		INSTRUCTION = {padding_bits, `add, `r3, `r1};		  #200
		INSTRUCTION = {padding_bits, `sub, `r1, `r2};		  #200
		INSTRUCTION = {padding_bits, `mov, `r4, `r1};
	 end
	 
	 always #25 clk = ~clk;
endmodule
