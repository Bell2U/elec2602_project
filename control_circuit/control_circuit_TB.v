`timescale 1ns / 1ps

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011
`define Xor 3'b100

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


module control_circuit_TB;
	parameter num_of_reg = 16;
	reg clk, reset;
	reg [10:0] instruction;
	wire [num_of_reg-1:0] Rin, Rout;
	wire [1:0] ALU_mode;
	wire ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load;
	
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
		instruction = {`load, `r1, 4'b0110}; #50
		instruction = 11'b10101010101;  #50
		instruction = {`mov, `r1, `r2}; #100
		instruction = {`add, `r3, `r4}; #200
		instruction = {`sub, `r2, `r4}; #200
		instruction = {`Xor, `r0, `r3}; #200
		instruction = {`mov, `r5, `r6}; #100
		instruction = {`mov, `r7, `r8}; #100
		instruction = {`mov, `r0, `r9}; #100
		instruction = {`mov, `r10, `r11}; #100
		instruction = {`mov, `r12, `r13}; #100
		instruction = {`mov, `r14, `r15};
	 end
	 
	 always #25 clk = ~clk;
endmodule
