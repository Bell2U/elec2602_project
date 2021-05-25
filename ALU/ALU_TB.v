`timescale 1ns/1ps

module ALU_TB;
	localparam N = 8;
	reg [N-1:0] a, b;
	reg addsub, clk, ain, gin, gout;
	wire [N-1:0] ALUout;
	
	AUL #(.N(N)) alu(a, b, addsub, clk, ain, gin, gout, ALUout);
	
	initial begin
		a <= 8'b0000_0010;
		b <= 8'b0000_0011;
		{clk, ain, gin, gout, addsub} <= 5'b10000;
		
		#50
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;
		
		#50
		addsub <= 1'b1;
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;
		
		#50
		a <= 8'b1000_0001;
		b <= 8'b1000_1111;
		addsub <= 1'b0;
		{ain, gin, gout} <= 3'b100;
		#50
		{ain, gin, gout} <= 3'b010;
		#50
		{ain, gin, gout} <= 3'b001;

	end
	
	always #25 clk = ~clk;
	
	
endmodule
