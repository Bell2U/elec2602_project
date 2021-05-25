`define reg_width 11
`define INSTRUCTION_size 11
`define Num_of_reg 4

module Reg_plus_tri(in, clk, Rin, Rout, out);
	input [`reg_width-1:0] in;
	input clk, Rin, Rout;
	output [`reg_width-1:0] out;
	wire [`reg_width-1:0] Q;
	
	genral_purpose_reg #(.D_width(`reg_width)) Reg(in, clk, Rin, Q);
	tri_buf #(.a_width(`reg_width)) Tri(Q, out, Rout);
endmodule



module my_chip
	(input [`INSTRUCTION_size-1:0] INSTRUCTION,
	 input clk, reset);
	 
	wire [`Num_of_reg-1:0] Rin, Rout;
	wire ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, ALU_mode;
	wire [`reg_width-1:0] Bus;
	 
	 
	genvar i;
	generate
		for (i = 0; i < `Num_of_reg; i = i + 1) begin: CPU_registers
			Reg_plus_tri R(Bus, clk, Rin[i], Rout[i], Bus);
		end
	endgenerate
	
	AUL #(.N(`reg_width)) alu(Bus, Bus, ALU_mode, clk, ALU_a_in, ALU_g_in, ALU_g_out, Bus);
	
	tri_buf #(.a_width(`reg_width)) External_load_tri_buff(INSTRUCTION, Bus, External_load);
	 
	control_circuit #(.num_of_reg(`Num_of_reg)) CC
	(.INSTRUCTION(INSTRUCTION),
	 .clk(clk), .reset(reset),
	 .Rin(Rin), .Rout(Rout),
	 .ALU_a_in(ALU_a_in), .ALU_g_in(ALU_g_in), .ALU_g_out(ALU_g_out),
	 .Done(Done), .External_load(External_load), .ALU_mode(ALU_mode));
	 
	
endmodule