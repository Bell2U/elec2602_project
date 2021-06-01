`define ALU_mode_encoding_bits 2


module genral_purpose_reg(D, clk, enable, Q);
	parameter D_width = 16 ;
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


module ALU_mode_decoder(
	input [`ALU_mode_encoding_bits-1:0] ALU_mode,
	output reg Addsub, output_select);
	/*
	ALU_mode		meaning	Addsub	output_select
	  00			 add			0				0
	  01			 sub			1				0
	  10			 xor			x				1
	*/
	always @(ALU_mode) begin
		case(ALU_mode)
		2'b00: begin Addsub = 1'b0; output_select = 1'b0; end
		2'b01: begin Addsub = 1'b1; output_select = 1'b0; end
		2'b10: begin Addsub = 1'bx; output_select = 1'b1; end
		default: begin Addsub = 1'bx; output_select = 1'bx; end
		endcase
	end
endmodule


module ALU_output_MUX
	#(parameter input_size = 16)
	(input [input_size-1:0] Adder_in, Xor_in,
	input output_select,
	output [input_size-1:0] out);
	
	assign out = output_select ? Xor_in : Adder_in;

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


module AUL(a, b, ALU_mode, clk, ain, gin, gout, ALUout);
	parameter N = 16;	// N is the number of bits this ALU deal with
   input [N-1:0] a, b;
	input [`ALU_mode_encoding_bits-1:0] ALU_mode;
   input clk, ain, gin, gout;
	output [N-1:0] ALUout;
   wire [N-1:0] inverted_b, bout, sum, aout, Gout_to_tri, Xored, output_to_G;
	wire addsub, output_select;

	genral_purpose_reg #(.D_width(N)) A(a, clk, ain, aout);	// verilog parameter reference: https://www.chipverify.com/verilog/verilog-parameters
   
	ALU_mode_decoder ModeDecoder(ALU_mode, addsub, output_select);
	
	nbits_fulladder #(.N(N)) nfa(aout, bout, addsub, c_out, sum);
	
	ALU_output_MUX #(.input_size(N)) OutMux(.Adder_in(sum), .Xor_in(Xored),
												.output_select(output_select), .out(output_to_G));
   
	genral_purpose_reg #(.D_width(N)) G(output_to_G, clk, gin, Gout_to_tri);
   
	tri_buf #(.a_width(N)) G_tb(Gout_to_tri, ALUout, gout);
	
	// multiplexer of b and inverted b
	assign inverted_b = ~b;
   assign bout = addsub ? inverted_b : b;
	
	// n-bit XORer
	assign Xored = aout ^ b;

endmodule
