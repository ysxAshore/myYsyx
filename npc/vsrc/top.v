module top(
	input clk,
	input rst,
	output [31:0] inst,
	output [31:0] pc,
	output [31:0] dnpc
);
	localparam DATA_WIDTH = 32;
	localparam ADDR_WIDTH = 5;

	wire [DATA_WIDTH - 1 : 0] id_to_if_bus;
	wire id_to_if_valid;
	wire if_to_id_ready;
	wire [DATA_WIDTH + DATA_WIDTH - 1 : 0] if_to_id_bus;
	wire if_to_id_valid;
	wire id_to_if_ready;
	wire wb_to_if_done;

	assign dnpc = id_to_if_bus;
	assign {pc,inst} = if_to_id_bus;
	
	ifu #(
		.DATA_WIDTH(DATA_WIDTH)
	)if_stage(
		.clk(clk),
		.rst(rst),
		.id_to_if_bus(id_to_if_bus),
		.id_to_if_valid(id_to_if_valid),
		.if_to_id_ready(if_to_id_ready),
		.if_to_id_bus(if_to_id_bus),
		.if_to_id_valid(if_to_id_valid),
		.id_to_if_ready(id_to_if_ready),
		.wb_to_if_done(wb_to_if_done)
	);


	wire [DATA_WIDTH + DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 19 - 1 : 0] id_to_exe_bus;
	wire id_to_exe_valid;
	wire exe_to_id_ready;

	wire [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] wb_to_id_bus;
	wire wb_to_id_valid;
	wire id_to_wb_ready;

	idu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)id_stage(
		.clk(clk),
		.rst(rst),
		.id_to_if_bus(id_to_if_bus),
		.id_to_if_valid(id_to_if_valid),
		.if_to_id_ready(if_to_id_ready),
		.if_to_id_bus(if_to_id_bus),
		.if_to_id_valid(if_to_id_valid),
		.id_to_if_ready(id_to_if_ready),
		.id_to_exe_bus(id_to_exe_bus),
		.id_to_exe_valid(id_to_exe_valid),
		.exe_to_id_ready(exe_to_id_ready),
		.wb_to_id_bus(wb_to_id_bus),
		.wb_to_id_valid(wb_to_id_valid),
		.id_to_wb_ready(id_to_wb_ready)
	);

	wire [DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 4 - 1 : 0] exe_to_mem_bus;
	wire exe_to_mem_valid;
	wire mem_to_exe_ready;
	
	exu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)exe_stage(
		.clk(clk),
		.rst(rst),
		.id_to_exe_bus(id_to_exe_bus),
		.id_to_exe_valid(id_to_exe_valid),
		.exe_to_id_ready(exe_to_id_ready),
		.exe_to_mem_bus(exe_to_mem_bus),
		.exe_to_mem_valid(exe_to_mem_valid),
		.mem_to_exe_ready(mem_to_exe_ready)
	);

	wire [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] mem_to_wb_bus;
	wire mem_to_wb_valid;
	wire wb_to_mem_ready;
	mmu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)mem_stage(
		.clk(clk),
		.rst(rst),
		.exe_to_mem_bus(exe_to_mem_bus),
		.exe_to_mem_valid(exe_to_mem_valid),
		.mem_to_exe_ready(mem_to_exe_ready),
		.mem_to_wb_bus(mem_to_wb_bus),
		.mem_to_wb_valid(mem_to_wb_valid),
		.wb_to_mem_ready(wb_to_mem_ready)
	);

	wbu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)wb_stage(
		.clk(clk),
		.rst(rst),
		.mem_to_wb_bus(mem_to_wb_bus),
		.mem_to_wb_valid(mem_to_wb_valid),
		.wb_to_mem_ready(wb_to_mem_ready),
		.wb_to_id_bus(wb_to_id_bus),
		.wb_to_id_valid(wb_to_id_valid),
		.id_to_wb_ready(id_to_wb_ready),
		.wb_to_if_done(wb_to_if_done)
	);
endmodule

