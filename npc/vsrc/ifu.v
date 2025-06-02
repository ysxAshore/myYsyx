module ifu(
	input clk,
	input rst,
	output reg [31:0] pc
);
	wire [31:0] snpc;
	assign snpc = pc + 32'h4;

	always @(posedge clk)begin
		if(~rst)
			pc <= 32'h8000_0000;
		else 
			pc <= snpc;
	end

endmodule
