module mmu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(    
	input clk,
	input rst,

	input [DATA_WIDTH + ADDR_WIDTH + 4 - 1 : 0] exe_to_mem_bus,
	input exe_to_mem_valid,
	output mem_to_exe_ready,

	
	output [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] mem_to_wb_bus,
	output reg mem_to_wb_valid,
	input wb_to_mem_ready,

	input [DATA_WIDTH - 1 : 0] load_data
);
	reg	e_regW;
	reg [ADDR_WIDTH-1:0]e_regAddr;
	reg [DATA_WIDTH-1:0]e_regData;
	reg	[2:0] e_load_inst;

	assign mem_to_exe_ready = ~mem_to_wb_valid || wb_to_mem_ready;

	always @(posedge clk) begin
		if(~rst) begin
			mem_to_wb_valid <= 1'b0;
		end else if(exe_to_mem_valid && mem_to_exe_ready) begin
			e_regW <= exe_to_mem_bus[DATA_WIDTH + ADDR_WIDTH + 3 : DATA_WIDTH + ADDR_WIDTH + 3];
			e_regAddr <= exe_to_mem_bus[DATA_WIDTH + ADDR_WIDTH + 3 - 1 : DATA_WIDTH + 3];
			e_regData <= exe_to_mem_bus[DATA_WIDTH + 3 - 1 : 3];
			e_load_inst <= exe_to_mem_bus[2 : 0];

			mem_to_wb_valid <= 1'b1;
		end else if(wb_to_mem_ready) begin
			mem_to_wb_valid <= 1'b0;
		end
	end
	


	wire [DATA_WIDTH - 1 : 0] m_regData = {DATA_WIDTH{e_load_inst == 3'h0}} & e_regData |
					   {DATA_WIDTH{e_load_inst == 3'h1}} & {{(DATA_WIDTH-8){load_data[7]}},load_data[7:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h2}} & {{(DATA_WIDTH-16){load_data[15]}},load_data[15:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h3}} & {{(DATA_WIDTH-32){load_data[31]}},load_data[31:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h4}} & {{(DATA_WIDTH-8){1'b0}},load_data[7:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h5}} & {{(DATA_WIDTH-16){1'b0}},load_data[15:0]};

	assign mem_to_wb_bus = {
		e_regW,
		e_regAddr,
		m_regData
	};

endmodule
