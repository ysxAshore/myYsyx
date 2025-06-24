module ifu #(parameter  DATA_WIDTH = 32)(
	input clk,
	input rst,
	input [31:0] dnpc,
	output reg[31:0] inst,
	output reg [31:0] fectch_pc
);

	import "DPI-C" function bit[DATA_WIDTH-1:0] mem_read(input logic[31:0] raddr);
	always @(rst or fectch_pc) begin
		if(rst)
			inst = mem_read(fectch_pc);
		else
			inst = 32'h00000013; //复位指令 nop = addi x0,x0,0
	end

	always @(posedge clk)begin
		if(~rst)
			fectch_pc <= 32'h8000_0000;
		else begin 
			fectch_pc <= dnpc;
		end
	end

endmodule
