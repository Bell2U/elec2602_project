// States
`define initial_state 4'b0000
`define Load1 4'b0001
`define Move 4'b0010
`define Add1 4'b0011
`define Add2 4'b0100
`define Add3 4'b0101
`define Sub1 4'b0110
`define Sub2 4'b0111
`define Sub3 4'b1000
`define Load2 4'b1001

// instructions
`define load 3'b000
`define mov 3'b001
`define add 3'b010
`define sub 3'b011

//size
`define instruction_size 3
`define state_size 4
`define operand_size 8

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


module last_state_output_register #(parameter num_of_reg = 4) (curr_Rinout, clk, reset, last_Rinout);
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
	#(parameter num_of_reg = 4)
	(input [`operand_size-1 : 0] operand,
	 input [`state_size-1:0] curr,
	 input [num_of_reg-1:0] last_Rxinout, last_Ryinout,
	 output reg [num_of_reg-1:0] Rin, Rout,
	 output reg ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, ALU_mode,
	 output reg [num_of_reg-1:0] Rxinout, Ryinout);
	/* 
	Number of registers: 4
	Number of bits to encode registers: 4
	ALU_mode:
		0 add
		1 sub
	*/
	
	localparam reg_encoding_bits = 4;
	localparam r1 = 'b0001, r2 = 'b0010, r3 = 'b0011, r4 = 'b0100;
	
	wire [reg_encoding_bits-1:0] op1, op2;
	reg curr_or_last_Rinout;
	
	
	assign op1 = operand[`operand_size-1:`operand_size - reg_encoding_bits];
	assign op2 = operand[`operand_size - reg_encoding_bits - 1 : `operand_size - 2*reg_encoding_bits];
	
	always @(op1) begin
		case(op1)
		r1: Rxinout = 'b0001;
		r2: Rxinout = 'b0010;
		r3: Rxinout = 'b0100;
		r4: Rxinout = 'b1000;
		default: Rxinout = 'b0000;
		endcase
	end
	
	always @(op2) begin
		case(op2)
		r1: Ryinout = 'b0001;
		r2: Ryinout = 'b0010;
		r3: Ryinout = 'b0100;
		r4: Ryinout = 'b1000;
		default: Ryinout = 'b0000;
		endcase
	end
	
	always @(curr) begin
		casex(curr)
		`initial_state: begin 
			Rin <= 'b0000;
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Load1: begin 
			Rin <= 'b0000;
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
			
		`Load2: begin 
			Rin <= last_Rxinout;
			Rout <= 'b0000;
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b1;
			ALU_mode <= 1'bx;
			end
			
		`Move: begin
			Rin <= Rxinout; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Add1: begin
			Rin <= 'b0000; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Add2: begin
			Rin <= 'b0000; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 1'b0; // add
			end
			
		`Add3: begin
			Rin <= Rxinout; 
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Sub1: begin
			Rin <= 'b0000; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Sub2: begin
			Rin <= 'b0000; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_load <= 1'b0;
			ALU_mode <= 1'b1; // sub
			end
			
		`Sub3: begin
			Rin <= Rxinout; 
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_load <= 1'b0;
			ALU_mode <= 1'bx;
			end
		endcase
	end
	
endmodule


module control_circuit
	#(parameter num_of_reg = 4)
	(input [`instruction_size + `operand_size - 1 : 0] INSTRUCTION,
	 input clk, reset,
	 output [num_of_reg:0] Rin, Rout,
	 output ALU_a_in, ALU_g_in, ALU_g_out, Done, External_load, ALU_mode);
	 
	 wire [`instruction_size-1:0] instruction;
	 wire [`operand_size-1:0] operand;
	 wire [`state_size-1:0] current_state, next_state;
	 wire [num_of_reg-1:0] curr_Rxinout, curr_Ryinout, last_Rxinout, last_Ryinout;
	 
	 
	 assign instruction = INSTRUCTION[`instruction_size + `operand_size - 1 : `operand_size];
	 assign operand = INSTRUCTION[`operand_size - 1 : 0];
	 
	 Next_state NS(instruction, current_state, next_state);
	 
	 current_state_register CS(next_state, clk, reset, current_state);
	 
	 last_state_output_register #(.num_of_reg(num_of_reg)) Last_Rxinout(curr_Rxinout, clk, reset, last_Rxinout);
	 last_state_output_register #(.num_of_reg(num_of_reg)) Last_Ryinout(curr_Ryinout, clk, reset, last_Ryinout);
	 
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
		 .Rxinout(curr_Rxinout), .Ryinout(curr_Ryinout));
endmodule
