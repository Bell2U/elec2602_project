// States
`define initial_state 4'b0000
`define Load 4'b0001
`define Move 4'b0010
`define Add1 4'b0011
`define Add2 4'b0100
`define Add3 4'b0101
`define Sub1 4'b0110
`define Sub2 4'b0111
`define Sub3 4'b1000

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
		{`initial_state, `load}: next = `Load;
		{`Load, {`instruction_size{1'b?}}}: next = `initial_state;	// Replication Operator: https://www.nandland.com/verilog/examples/example-replication-operator.html
		
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


module output_control_signal
	(input [`operand_size-1 : 0] operand,
	 input [`state_size-1:0] curr,
	 output reg [3:0] Rin, Rout,
	 output reg ALU_a_in, ALU_g_in, ALU_g_out, Done, External_data, ALU_mode);
	/* 
	Number of registers: 4
	Number of bits to encode registers: 3
	ALU_mode:
		0 add
		1 sub
	*/
	
	localparam reg_encoding_bits = 3;
	localparam r1 = 'b001, r2 = 'b010, r3 = 'b011, r4 = 'b100;
	
	wire [reg_encoding_bits-1:0] op1, op2;
	// wire [`operand_size - reg_encoding_bits-1:0] load_D;
	reg [3:0] Rxinout, Ryinout;
	
	assign op1 = operand[`operand_size-1:`operand_size - reg_encoding_bits];
	assign op2 = operand[`operand_size - reg_encoding_bits - 1 : `operand_size - 2*reg_encoding_bits];
	// assign load_D = operand[`operand_size - reg_encoding_bits - 1 : 0];
	
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
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Load: begin 
			Rin <= Rxinout;
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_data <= 1'b1;
			ALU_mode <= 1'bx;
			end
			
		`Move: begin
			Rin <= Rxinout; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b1;
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Add1: begin
			Rin <= 'b0000; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Add2: begin
			Rin <= 'b0000; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_data <= 1'b0;
			ALU_mode <= 1'b0; // add
			end
			
		`Add3: begin
			Rin <= Rxinout; 
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Sub1: begin
			Rin <= 'b0000; 
			Rout <= Rxinout; 
			ALU_a_in <= 1'b1;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		
		`Sub2: begin
			Rin <= 'b0000; 
			Rout <= Ryinout; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b1;
			ALU_g_out <= 1'b0;
			Done <= 1'b0;
			External_data <= 1'b0;
			ALU_mode <= 1'b1; // sub
			end
			
		`Sub3: begin
			Rin <= Rxinout; 
			Rout <= 'b0000; 
			ALU_a_in <= 1'b0;
			ALU_g_in <= 1'b0;
			ALU_g_out <= 1'b1;
			Done <= 1'b1;
			External_data <= 1'b0;
			ALU_mode <= 1'bx;
			end
		endcase
	end
	
endmodule


module control_circuit
	(input [`instruction_size + `operand_size - 1 : 0] INSTRUCTION,
	 input clk, reset,
	 output [3:0] Rin, Rout,
	 output ALU_a_in, ALU_g_in, ALU_g_out, Done, External_data, ALU_mode);
	 
	 wire [`instruction_size-1:0] instruction;
	 wire [`operand_size-1:0] operand;
	 wire [`state_size-1:0] current_state, next_state;
	 
	 
	 assign instruction = INSTRUCTION[`instruction_size + `operand_size - 1 : `operand_size];
	 assign operand = INSTRUCTION[`operand_size - 1 : 0];
	 
	 Next_state NS(instruction, current_state, next_state);
	 current_state_register CS(next_state, clk, reset, current_state);
	 output_control_signal OUT
		(.operand(operand),
		 .curr(current_state),
		 .Rin(Rin), .Rout(Rout),
		 .ALU_a_in(ALU_a_in),
		 .ALU_g_in(ALU_g_in),
		 .ALU_g_out(ALU_g_out),
		 .Done(Done),
		 .External_data(External_data),
		 .ALU_mode(ALU_mode));
endmodule
