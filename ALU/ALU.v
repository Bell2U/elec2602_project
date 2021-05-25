module genral_purpose_reg(D, clk, enable, Q);
	parameter D_width = 8 ;
	input [D_width-1:0] D;
	input clk, enable;
	output reg [D_width-1:0] Q;
	
   always @(posedge clk) 
   begin
   if (enable)
		Q <= D;
   end
endmodule


module tri_buf(a, b, enable);
   parameter a_width = 8 ;
   input [a_width - 1:0] a;
   output reg [a_width - 1:0] b;
   input enable;
	
   always @ (enable, a) begin
   if (enable)
        b = a;
   else 
        b = {a_width {1'bz}};
   end
endmodule


module nbits_fulladder(a, b, c_in, c_out, sum);
	parameter N = 8;
	input [N-1:0] a, b;
	input c_in;
	output reg c_out;
	output reg [N-1:0] sum;
	
	always@(a or b or c_in) begin
	{c_out, sum} = a + b + c_in;
	end
endmodule


module AUL(a, b, addsub, clk, ain, gin, gout, ALUout);
	parameter N = 8;	// N is the number of bits this ALU deal with
   input [N-1:0] a, b;
   input addsub, clk, ain, gin, gout;
	output [N-1:0] ALUout;
   wire [N-1:0] inverted_b, bout, sum, aout, GQ;

	genral_purpose_reg #(.D_width(N)) A(a, clk, ain, aout);	// verilog parameter reference: https://www.chipverify.com/verilog/verilog-parameters
   nbits_fulladder #(.N(N)) nfa(aout, bout, addsub, c_out, sum);
   genral_purpose_reg #(.D_width(N)) G(sum, clk, gin, GQ);
   tri_buf #(.a_width(N)) G_tb(GQ, ALUout, gout);

	assign inverted_b = ~b;
   assign bout = addsub ? inverted_b : b;

endmodule
