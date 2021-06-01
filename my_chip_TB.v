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
`define Xor 3'b100
`define ldPM 3'b101
`define ldpc 3'b110
`define branch 3'b111

`define reg_width 16

module my_chip_TB;
	reg [`reg_width-1:0] INSTRUCTION;
	reg clk, reset, memory_clk, mode;
	localparam padding_bits = 5'b00000;
	
	my_chip little_boy(
	.external_INSTRUCTION(INSTRUCTION),
	.clk(clk), .memory_clk(memory_clk), 
	.reset(reset), 
	.mode_sel(mode));
	
	
	/*
	// Program of mark scheme 7
	initial begin
		reset = 1'b0;
		clk = 1'b0;
		memory_clk = 1'b1;
		mode = 1'b1;
		
		#25 
		reset = 1'b1;
		INSTRUCTION = {`ldPM, 8'b0000_0000, padding_bits};  #25 reset = 1'b0; #75
		INSTRUCTION = {`load, `r0, 4'b1111, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0001, padding_bits};  #100
		INSTRUCTION = 16'b0000_0000_0000_0001;		  			 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0010, padding_bits};	 #100
		INSTRUCTION = {`mov, `r1, `r0, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0011, padding_bits};	 #100
		INSTRUCTION = {`add, `r0, `r1, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0100, padding_bits};	 #100
		INSTRUCTION = {`add, `r0, `r1, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0101, padding_bits};	 #100
		INSTRUCTION = {`add, `r0, `r1, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0110, padding_bits};	 #100
		INSTRUCTION = {`load, `r2, 4'b0000, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0111, padding_bits};	 #100
		INSTRUCTION = 16'b0000_0000_0000_0010;	 				 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1000, padding_bits};	 #100
		INSTRUCTION = {`add, `r0, `r2, padding_bits};		 #50
		
		mode = 1'b0;
		reset = 1'b1;	# 70
		reset = 1'b0;
	 end
	 */
	 
	 
	 // Fibonacci numbers
	 initial begin
		reset = 1'b0;
		clk = 1'b0;
		memory_clk = 1'b1;
		mode = 1'b1;
		
		#25 
		reset = 1'b1;
		INSTRUCTION = {`ldPM, 8'b0000_0000, padding_bits};  #25 reset = 1'b0; #75
		INSTRUCTION = {`load, `r0, 4'b1111, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0001, padding_bits};  #100
		INSTRUCTION = 16'b0000_0000_0000_0000;		  			 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0010, padding_bits};	 #100
		INSTRUCTION = {`load, `r1, 4'b0000, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0011, padding_bits};	 #100
		INSTRUCTION = 16'b0000_0000_0000_0001;		  			 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0100, padding_bits};	 #100
		INSTRUCTION = {`load, `r2, 4'b0000, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0101, padding_bits};	 #100
		INSTRUCTION = 16'b0000_0000_0000_0000;		  			 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0110, padding_bits};	 #100
		INSTRUCTION = {`ldpc, `r4, 4'b0000, padding_bits};	 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_0111, padding_bits};	 #100
		INSTRUCTION = {`mov, `r3, `r1, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1000, padding_bits};	 #100
		INSTRUCTION = {`add, `r1, `r2, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1001, padding_bits};	 #100
		INSTRUCTION = {`mov, `r0, `r3, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1010, padding_bits};	 #100
		INSTRUCTION = {`mov, `r2, `r3, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1011, padding_bits};	 #100
		INSTRUCTION = {`mov, `r1, `r0, padding_bits};		 #50
		
		INSTRUCTION = {`ldPM, 8'b0000_1011, padding_bits};	 #100
		INSTRUCTION = {`branch, `r4, 4'b0000, padding_bits}; #50
		
		mode = 1'b0;
		reset = 1'b1;	# 70
		reset = 1'b0;
	 end
	
	 
	 always #25 clk = ~clk;
	 always #12.5 memory_clk = ~memory_clk;
endmodule
