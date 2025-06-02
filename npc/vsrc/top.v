module top(
	input clk,
	input rst,
	input [31:0] inst,
	output [31:0] pc
);
	localparam DATA_WIDTH = 32;
	localparam ADDR_WIDTH = 5;
	ifu if_stage(
		.clk(clk),
		.rst(rst),
		.pc(pc)		
	);

	wire [DATA_WIDTH-1:0] aluSrc1;
	wire [DATA_WIDTH-1:0] aluSrc2;
	wire [9:0] aluOp;
	wire d_regW;
	wire [ADDR_WIDTH-1:0] d_regAddr;
	wire w_regW;
	wire [ADDR_WIDTH-1:0] w_regAddr;
	wire [DATA_WIDTH-1:0] w_regData;

	idu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)id_stage(
		.clk(clk),
		.inst(inst),
		.aluSrc1(aluSrc1),
		.aluSrc2(aluSrc2),
		.aluOp(aluOp),
		.d_regW(d_regW),
		.d_regAddr(d_regAddr),
		.w_regW(w_regW),
		.w_regAddr(w_regAddr),
		.w_regData(w_regData)
	);

	wire e_regW;
	wire [ADDR_WIDTH-1:0] e_regAddr;
	wire [DATA_WIDTH-1:0] e_regData;
	exu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)exe_stage(
		.clk(clk),
		.aluSrc1(aluSrc1),
		.aluSrc2(aluSrc2),
		.aluOp(aluOp),
		.d_regW(d_regW),
		.d_regAddr(d_regAddr),
		.e_regW(e_regW),
		.e_regAddr(e_regAddr),
		.e_regData(e_regData)
	);

	wire m_regW;
	wire [ADDR_WIDTH-1:0] m_regAddr;
	wire [DATA_WIDTH-1:0] m_regData;
	mmu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)mem_stage(
		.clk(clk),
		.e_regW(e_regW),
		.e_regAddr(e_regAddr),
		.e_regData(e_regData),
		.m_regW(m_regW),
		.m_regAddr(m_regAddr),
		.m_regData(m_regData)
	);

	wbu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)wb_stage(
		.m_regW(m_regW),
		.m_regAddr(m_regAddr),
		.m_regData(m_regData),
		.w_regW(w_regW),
		.w_regAddr(w_regAddr),
		.w_regData(w_regData)
	);
endmodule

