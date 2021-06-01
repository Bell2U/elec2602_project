// States
`define initial_state 5'b00000
`define Load1 5'b00001
`define Move 5'b00010
`define Add1 5'b00011
`define Add2 5'b00100
`define Add3 5'b00101
`define Sub1 5'b00110
`define Sub2 5'b00111
`define Sub3 5'b01000
`define Load2 5'b01001
`define Xor1 5'b01010
`define Xor2 5'b01011
`define Xor3 5'b01100
`define ldPM1 5'b01101
`define ldPM2 5'b01110
`define Ldpc 5'b01111
`define Branch 5'b10000

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011
`define Xor 3'b100
`define ldPM 3'b101
`define ldpc 3'b110
`define branch 3'b111

//size
`define INSTRUCTION_SIZE 16
`define instruction_size 3
`define state_size 5
`define operand_size 13
`define ALU_mode_size 2
`define mem_addr_size 8

module Next_state(instruction, curr, next);
	input [`instruction_size-1:0] instruction;
	input [`state_size-1:0] curr;
	output reg [`state_size-1:0] next;
	
	
	always @(instruction, curr) begin
		casex({curr, instruction})
		// load
		{`initial_state, `load}: next = `Load1;
		{`Load1, {`instruction_size{1'b?}}}: next = `Load2;	// Replication Operator: https://www.nandland.com/verilog/examples/example-replication-operator.html
		{`Load2, {`instruction_size{1'b?}}}: next = `initial_state;
		
		// mov
		{`initial_state, `mov}: next = `Move;
		{`Move, {`instruction_size{1'b?}}}: next = `initial_state;
		
		// add
		{`initial_state, `add}: next = `Add1;
		{`Add1, {`instruction_size{1'b?}}}: next = `Add2;
		{`Add2, {`instruction_size{1'b?}}}: next = `Add3;
		{`Add3, {`instruction_size{1'b?}}}: next = `initial_state;
		
		// sub
		{`initial_state, `sub}: next = `Sub1;
		{`Sub1, {`instruction_size{1'b?}}}: next = `Sub2;
		{`Sub2, {`instruction_size{1'b?}}}: next = `Sub3;
		{`Sub3, {`instruction_size{1'b?}}}: next = `initial_state;
		
		// xor
		{`initial_state, `Xor}: next = `Xor1;
		{`Xor1, {`instruction_size{1'b?}}}: next = `Xor2;
		{`Xor2, {`instruction_size{1'b?}}}: next = `Xor3;
		{`Xor3, {`instruction_size{1'b?}}}: next = `initial_state;
		
		//ldPM
		{`initial_state, `ldPM}: next = `ldPM1;
		{`ldPM1, {`instruction_size{1'b?}}}: next = `ldPM2;
		{`ldPM2, {`instruction_size{1'b?}}}: next = `initial_state;
		
		//ldpc
		{`initial_state, `ldpc}: next = `Ldpc;
		{`Ldpc, {`instruction_size{1'b?}}}: next = `initial_state;
		
		//branch
		{`initial_state, `branch}: next = `Branch;
		{`Branch, {`instruction_size{1'b?}}}: next = `initial_state;
		default: next = `initial_state;
		endcase
	end
endmodule


module current_state_register(next, clk, reset, curr);
	input [`state_size-1:0] next;
	input clk, reset;
	output reg [`state_size-1:0] curr;
	
	always @(posedge clk, posedge reset) begin
		if (reset)
			curr <= `initial_state;
		else
			curr <= next;
	end
endmodule


module last_state_output_register #(parameter num_of_reg = 16) (curr_Rinout, clk, reset, last_Rinout);
	input [num_of_reg-1:0] curr_Rinout;
	input clk, reset;
	output reg [num_of_reg-1:0] last_Rinout;
	
	always @(posedge clk) begin
		if (reset)
			last_Rinout <= {num_of_reg{1'b0}};
		else
			last_Rinout <= curr_Rinout;
	end
endmodule


module output_control_signal
	#(parameter num_of_reg = 16)
	(input [`operand_size-1 : 0] operand,
	 input [`state_size-1:0] curr,
	 input [num_of_reg-1:0] last_Rxinout, last_Ryinout,
	 input [`mem_addr_size-1:0] last_mem_addr,
	 output reg [num_of_reg-1:0] Rin, Rout,
	 output reg [`ALU_mode_size-1:0] ALU_mode,
	 output reg ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, PC_in, PC_out, RAM_wren,
	 output reg [num_of_reg-1:0] Rxinout, Ryinout,
	 output reg [`mem_addr_size-1:0] mem_addr);
	/* 
	Number of registers: 16
	Number of bits to encode registers: 4
	ALU_mode:
		00 add
		01 sub
		10 xor
	*/
	
	localparam reg_encoding_bits = 4;
	localparam r0 = 'b0000,  r1 = 'b0001,  r2 = 'b0010,  r3 = 'b0011,
				  r4 = 'b0100,  r5 = 'b0101,  r6 = 'b0110,  r7 = 'b0111,
				  r8 = 'b1000,  r9 = 'b1001,  r10 = 'b1010, r11 = 'b1011,
				  r12 = 'b1100, r13 = 'b1101, r14 = 'b1110, r15 = 'b1111;
				  
	wire [reg_encoding_bits-1:0] op1, op2, op3;
	reg [num_of_reg-1:0] Rzinout;
	wire [`mem_addr_size-1:0] curr_mem_addr;
	
	assign op1 = operand[`operand_size-1:`operand_size - reg_encoding_bits];
	assign op2 = operand[`operand_size - reg_encoding_bits - 1 : `operand_size - 2*reg_encoding_bits];
	assign op3 = operand[`operand_size - 2*reg_encoding_bits - 1 : `operand_size - 3*reg_encoding_bits];
	assign curr_mem_addr = {op1, op2};
	
	always @(op1) begin
		case(op1)
		r0:  Rxinout = 'b0000_0000_0000_0001;
		r1:  Rxinout = 'b0000_0000_0000_0010;
		r2:  Rxinout = 'b0000_0000_0000_0100;
		r3:  Rxinout = 'b0000_0000_0000_1000;
		r4:  Rxinout = 'b0000_0000_0001_0000;
		r5:  Rxinout = 'b0000_0000_0010_0000;
		r6:  Rxinout = 'b0000_0000_0100_0000;
		r7:  Rxinout = 'b0000_0000_1000_0000;
		r8:  Rxinout = 'b0000_0001_0000_0000;
		r9:  Rxinout = 'b0000_0010_0000_0000;
		r10: Rxinout = 'b0000_0100_0000_0000;
		r11: Rxinout = 'b0000_1000_0000_0000;
		r12: Rxinout = 'b0001_0000_0000_0000;
		r13: Rxinout = 'b0010_0000_0000_0000;
		r14: Rxinout = 'b0100_0000_0000_0000;
		r15: Rxinout = 'b1000_0000_0000_0000;
		default: Rxinout = 'b0000_0000_0000_0000;
		endcase
	end
	
	always @(op2) begin
		case(op2)
		r0:  Ryinout = 'b0000_0000_0000_0001;
		r1:  Ryinout = 'b0000_0000_0000_0010;
		r2:  Ryinout = 'b0000_0000_0000_0100;
		r3:  Ryinout = 'b0000_0000_0000_1000;
		r4:  Ryinout = 'b0000_0000_0001_0000;
		r5:  Ryinout = 'b0000_0000_0010_0000;
		r6:  Ryinout = 'b0000_0000_0100_0000;
		r7:  Ryinout = 'b0000_0000_1000_0000;
		r8:  Ryinout = 'b0000_0001_0000_0000;
		r9:  Ryinout = 'b0000_0010_0000_0000;
		r10: Ryinout = 'b0000_0100_0000_0000;
		r11: Ryinout = 'b0000_1000_0000_0000;
		r12: Ryinout = 'b0001_0000_0000_0000;
		r13: Ryinout = 'b0010_0000_0000_0000;
		r14: Ryinout = 'b0100_0000_0000_0000;
		r15: Ryinout = 'b1000_0000_0000_0000;
		default: Ryinout = 'b0000_0000_0000_0000;
		endcase
	end
	
	always @(op3) begin
		case(op3)
		r0:  Rzinout = 'b0000_0000_0000_0001;
		r1:  Rzinout = 'b0000_0000_0000_0010;
		r2:  Rzinout = 'b0000_0000_0000_0100;
		r3:  Rzinout = 'b0000_0000_0000_1000;
		r4:  Rzinout = 'b0000_0000_0001_0000;
		r5:  Rzinout = 'b0000_0000_0010_0000;
		r6:  Rzinout = 'b0000_0000_0100_0000;
		r7:  Rzinout = 'b0000_0000_1000_0000;
		r8:  Rzinout = 'b0000_0001_0000_0000;
		r9:  Rzinout = 'b0000_0010_0000_0000;
		r10: Rzinout = 'b0000_0100_0000_0000;
		r11: Rzinout = 'b0000_1000_0000_0000;
		r12: Rzinout = 'b0001_0000_0000_0000;
		r13: Rzinout = 'b0010_0000_0000_0000;
		r14: Rzinout = 'b0100_0000_0000_0000;
		r15: Rzinout = 'b1000_0000_0000_0000;
		default: Rzinout = 'b0000_0000_0000_0000;
		endcase
	end
	
	always @(curr) begin
		casex(curr)
		`initial_state: begin 
			Rin <= {num_of_reg{1'b0}};
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Load1: begin 
			Rin <= {num_of_reg{1'b0}};
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
			
		`Load2: begin 
			Rin <= last_Rxinout;
			Rout <= {num_of_reg{1'b0}};
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b1;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
			
		`Move: begin
			Rin <= Rxinout; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Add1: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Add2: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'b00; // add
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
			
		`Add3: begin
			Rin <= Rxinout; 
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Sub1: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Sub2: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'b01; // sub
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
			
		`Sub3: begin
			Rin <= Rxinout; 
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Xor1: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Xor2: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 2'b10; // xor
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
			
		`Xor3: begin
			Rin <= Rxinout; 
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`ldPM1: begin 
			Rin <= {num_of_reg{1'b0}};
			Rout <= {num_of_reg{1'b0}}; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= curr_mem_addr;
			end
			
		`ldPM2: begin 
			Rin <= {num_of_reg{1'b0}};
			Rout <= {num_of_reg{1'b0}};
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b1;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b0;
			RAM_wren <= 1'b1;
			mem_addr <= last_mem_addr;
			end
		
		`Ldpc: begin
			Rin <= Rxinout; 
			Rout <= {num_of_reg{1'b0}};
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b0;
			PC_out <= 1'b1;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		
		`Branch: begin
			Rin <= {num_of_reg{1'b0}}; 
			Rout <= Rxinout;
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 2'bxx;
			PC_in <= 1'b1;
			PC_out <= 1'b0;
			RAM_wren <= 1'b0;
			mem_addr <= {`mem_addr_size{1'bx}};
			end
		endcase
	end
endmodule


module control_circuit
	#(parameter num_of_reg = 16)
	(input [`INSTRUCTION_SIZE - 1 : 0] INSTRUCTION,
	 input clk, reset,
	 output [num_of_reg-1:0] Rin, Rout,
	 output [`ALU_mode_size-1:0] ALU_mode,
	 output ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, PC_in, PC_out, RAM_wren,
	 output [`mem_addr_size-1:0] RAM_addr);
	 
	 wire [`instruction_size-1:0] instruction;
	 wire [`operand_size-1:0] operand;
	 wire [`state_size-1:0] current_state, next_state;
	 wire [num_of_reg-1:0] curr_Rxinout, curr_Ryinout, last_Rxinout, last_Ryinout;
	 wire [`mem_addr_size-1:0] last_mem_addr_wire;
	 
	 
	 assign instruction = INSTRUCTION[`INSTRUCTION_SIZE - 1 : `INSTRUCTION_SIZE - `instruction_size];
	 assign operand = INSTRUCTION[`INSTRUCTION_SIZE - `instruction_size - 1 : 0];
	 
	 Next_state NS(instruction, current_state, next_state);
	 
	 current_state_register CS(next_state, clk, reset, current_state);
	 
	 last_state_output_register #(.num_of_reg(num_of_reg)) Last_Rxinout(curr_Rxinout, clk, reset, last_Rxinout);
	 last_state_output_register #(.num_of_reg(num_of_reg)) Last_Ryinout(curr_Ryinout, clk, reset, last_Ryinout);
	 last_state_output_register #(.num_of_reg(`mem_addr_size)) Last_RAM_addr(RAM_addr, clk, reset, last_mem_addr_wire);
	 
	 output_control_signal #(.num_of_reg(num_of_reg)) OUT
		(.operand(operand),
		 .curr(current_state),
		 .last_Rxinout(last_Rxinout), .last_Ryinout(last_Ryinout),
		 .Rin(Rin), .Rout(Rout),
		 .ALU_a_in(ALU_a_in),
		 .ALU_g_in(ALU_g_in),
		 .ALU_g_out(ALU_g_out),
		 .Done(Done),
		 .External_load(External_load),
		 .ALU_mode(ALU_mode),
		 .Rxinout(curr_Rxinout), .Ryinout(curr_Ryinout),
		 .PC_in(PC_in), .PC_out(PC_out), .RAM_wren(RAM_wren),
		 .last_mem_addr(last_mem_addr_wire), .mem_addr(RAM_addr));
endmodule
