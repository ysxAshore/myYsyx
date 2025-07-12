module wbu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(    
	input clk,
	input rst,

	input [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] mem_to_wb_bus,
	input mem_to_wb_valid,
	output wb_to_mem_ready,

	output [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] wb_to_id_bus,
	input id_to_wb_ready,
	output reg wb_to_id_valid,

	output reg wb_to_if_done
);
	reg m_regW;
	reg [ADDR_WIDTH - 1 : 0] m_regAddr;
	reg [DATA_WIDTH - 1 : 0] m_regData;

	always @(posedge clk) begin
		if(~rst) begin
			wb_to_id_valid <= 1'b0;
			wb_to_if_done <= 1'b1;
		end else if(mem_to_wb_valid && wb_to_mem_ready) begin
			m_regW <= mem_to_wb_bus[DATA_WIDTH + ADDR_WIDTH : DATA_WIDTH + ADDR_WIDTH];
			m_regAddr <= mem_to_wb_bus[DATA_WIDTH + ADDR_WIDTH - 1 : DATA_WIDTH];
			m_regData <= mem_to_wb_bus[DATA_WIDTH - 1 : 0];

			wb_to_id_valid <= 1'b1;
			wb_to_if_done <= 1'b1;
		end else if(wb_to_mem_ready) begin
			wb_to_id_valid <= 1'b0;
			wb_to_if_done <= 1'b0;
		end
	end

	assign wb_to_mem_ready = ~wb_to_id_valid || id_to_wb_ready;

	assign wb_to_id_bus = {
		m_regData,
		m_regAddr,
		m_regW
	};
endmodule
