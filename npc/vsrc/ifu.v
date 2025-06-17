module ifu(
	input clk,
	input rst,
	input [31:0] dnpc,
	output reg [31:0] fectch_pc
);

	always @(posedge clk)begin
		if(~rst)
			fectch_pc <= 32'h8000_0000;
		else begin 
			fectch_pc <= dnpc;
		end
	end

endmodule
