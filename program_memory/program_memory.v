`define data_bus_wide 16
`define addr_bus_wide 8


module reg_with_enable_and_reset #(parameter width = 8) (in, clk, enable, reset, out);
	input clk, enable, reset;
	input [width-1:0] in;
	output reg [width-1:0] out;
	
	always @(negedge clk, posedge reset) begin
		if (reset) 
			out <= {width{1'b0}};
		else if (enable)
			out <= in;
	end
endmodule


module Program_counter(
	input PC_in, Done, PC_clk, reset,
	input [`data_bus_wide-1:0] Data_bus,
	output [`addr_bus_wide-1:0] addr);
	
	wire [`addr_bus_wide-1:0] addr_plus_one, next_addr, bus_addr;
	
	reg_with_enable_and_reset #(.width(`addr_bus_wide)) current_addr_reg(next_addr, PC_clk, Done, reset, addr);
	
	assign bus_addr = Data_bus[`addr_bus_wide-1:0];
	assign addr_plus_one = addr + 1'b1;
	assign next_addr = PC_in ? bus_addr : addr_plus_one;
	
endmodule
