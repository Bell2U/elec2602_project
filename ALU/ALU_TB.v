`timescale 1ns/1ps

module ALU_TB;
	localparam N = 16;
	reg [N-1:0] a, b;
	reg [1:0] ALU_mode;
	reg clk, ain, gin, gout;
	wire [N-1:0] ALUout;
	
	AUL #(.N(N)) alu(a, b, ALU_mode, clk, ain, gin, gout, ALUout);
	
	initial begin
		a <= 16'b0000_0000_0000_0010;
		b <= 16'b0000_0000_0000_0011;
		{clk, ain, gin, gout} <= 4'b1000;
		ALU_mode = 2'b00;	//add
		
		#50
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;
		
		#50
		ALU_mode <= 2'b01;	//sub
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;
		
		#50
		a <= 16'b1010_1010_1000_1111;
		b <= 16'b0101_0101_1000_1111;
		ALU_mode <= 2'b10;	//xor
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;

	end
	
	always #25 clk = ~clk;
	
	
endmodule
