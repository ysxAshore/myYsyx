module mmu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(    
	input clk,
	input e_regW,
    input [ADDR_WIDTH-1:0]e_regAddr,
    input [DATA_WIDTH-1:0]e_regData,
	input [2:0] e_load_inst,
	input [3:0] e_store_mask,
	input [DATA_WIDTH-1:0] e_store_data,
	
	output m_regW,
    output [ADDR_WIDTH-1:0]m_regAddr,
    output [DATA_WIDTH-1:0]m_regData
);
	assign m_regW = e_regW;
	assign m_regAddr = e_regAddr;

	reg[DATA_WIDTH-1:0] load_data;
	
	import "DPI-C" function bit[DATA_WIDTH-1:0] mem_read(input logic[31:0] raddr);
	import "DPI-C" function void mem_write(input logic[31:0] waddr, input logic[31:0] wdata, input byte wmask);
	always @(*) begin
		if(e_load_inst != 3'b0) begin
			load_data = mem_read(e_regData);
		end else begin
			load_data = {DATA_WIDTH{1'b0}};
		end

		if(e_store_mask != 4'b0) begin
			mem_write(e_regData,e_store_data,{4'b0,e_store_mask});
		end
	end

	assign m_regData = {DATA_WIDTH{e_load_inst == 3'h0}} & e_regData |
					   {DATA_WIDTH{e_load_inst == 3'h1}} & {{(DATA_WIDTH-8){load_data[7]}},load_data[7:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h2}} & {{(DATA_WIDTH-16){load_data[15]}},load_data[15:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h3}} & {{(DATA_WIDTH-32){load_data[31]}},load_data[31:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h4}} & {{(DATA_WIDTH-8){1'b0}},load_data[7:0]} |
					   {DATA_WIDTH{e_load_inst == 3'h5}} & {{(DATA_WIDTH-16){1'b0}},load_data[15:0]};

endmodule
