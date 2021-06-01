`define reg_width 16
`define addr_width 8
`define Num_of_reg 16
`define ALU_mode_size 2

module Reg_plus_tri(in, clk, Rin, Rout, out);
	input [`reg_width-1:0] in;
	input clk, Rin, Rout;
	output [`reg_width-1:0] out;
	wire [`reg_width-1:0] Q;
	
	genral_purpose_reg #(.D_width(`reg_width)) Reg(in, clk, Rin, Q);
	tri_buf #(.a_width(`reg_width)) Tri(Q, out, Rout);
endmodule



module my_chip
	(input [`reg_width-1:0] external_INSTRUCTION,
	 input clk, memory_clk, reset, mode_sel);
	 
	wire [`Num_of_reg-1:0] Rin, Rout;
	wire [`ALU_mode_size-1:0] ALU_mode;
	wire ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, PC_in, PC_out, RAM_wren;
	wire [`reg_width-1:0] Bus, INSTRUCTION, internal_INSTRUCTION, PC_addr_output_padded;
	wire [`addr_width-1:0] Addr_bus, PC_addr_output, CC_addr_output;
	wire enable_signal, read_enable;
	
	
	genvar i;
	generate
		for (i = 0; i < `Num_of_reg; i = i + 1) begin: CPU_registers
			Reg_plus_tri R(Bus, clk, Rin[i], Rout[i], Bus);
		end
	endgenerate
	
	AUL #(.N(`reg_width)) alu(Bus, Bus, ALU_mode, clk, ALU_a_in, ALU_g_in, ALU_g_out, Bus);
	
	tri_buf #(.a_width(`reg_width)) External_load_tri_buff(INSTRUCTION, Bus, External_load);
	
	Program_counter PC(
	.PC_in(PC_in),	.Done(Done), .PC_clk(clk), .reset(mode_sel),
	.Data_bus(Bus),
	.addr(PC_addr_output));
	
	tri_buf #(.a_width(`addr_width)) PC_addr_to_addrBus_tri(PC_addr_output, Addr_bus, read_enable);
	tri_buf #(.a_width(`addr_width)) PC_addr_to_Bus_tri(PC_addr_output_padded, Bus, PC_out);
	
	ram1 program_memory(.address(Addr_bus),
	.clock(memory_clk),
	.data(Bus),
	.wren(RAM_wren),
	.q(internal_INSTRUCTION));
	
	// genral_purpose_reg #(.D_width(`reg_width)) Instruction_reg(Function, clk, enable_signal, internal_INSTRUCTION);
	
	control_circuit #(.num_of_reg(`Num_of_reg)) CC
	(.INSTRUCTION(INSTRUCTION),
	 .clk(clk), .reset(reset),
	 .Rin(Rin), .Rout(Rout),
	 .ALU_a_in(ALU_a_in), .ALU_g_in(ALU_g_in), .ALU_g_out(ALU_g_out),
	 .Done(Done), .External_load(External_load), .ALU_mode(ALU_mode),
	 .PC_in(PC_in), .PC_out(PC_out), .RAM_wren(RAM_wren), .RAM_addr(CC_addr_output));
	 
	 tri_buf #(.a_width(`addr_width)) CC_addr_tri(CC_addr_output, Addr_bus, RAM_wren);
	 
	 
	assign enable_signal = 1'b1;
	assign read_enable = ~RAM_wren;
	assign INSTRUCTION = mode_sel ? external_INSTRUCTION : internal_INSTRUCTION;
	assign PC_addr_output_padded = {8'b0000_0000, PC_addr_output};
	
endmodule
