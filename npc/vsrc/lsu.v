module mmu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(    
	input clk,
	input rst,

	input [DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 8 - 1 : 0] exe_to_mem_bus,
	input exe_to_mem_valid,
	output mem_to_exe_ready,

	
	output [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] mem_to_wb_bus,
	output mem_to_wb_valid,
	input wb_to_mem_ready

);
	reg mem_valid;
	reg	e_regW;
	reg [ADDR_WIDTH-1:0]e_regAddr;
	reg [DATA_WIDTH-1:0]e_regData;
	reg [DATA_WIDTH-1:0]load_data;
	reg [2:0] load_inst;
	reg	[3:0] load_strb;

	assign mem_to_exe_ready = ~mem_to_wb_valid || wb_to_mem_ready;
	assign mem_to_wb_valid = mem_valid;

	always @(posedge clk) begin
		if(~rst) begin
			mem_valid <= 1'b0;
		end else begin
			if(exe_to_mem_valid && mem_to_exe_ready) begin
				load_inst <= exe_to_mem_bus[DATA_WIDTH + DATA_WIDTH +ADDR_WIDTH + 4 + 4 - 1 : DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 4 + 1];
				e_regW <= exe_to_mem_bus[DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 4 : DATA_WIDTH + DATA_WIDTH +ADDR_WIDTH + 4];
				e_regAddr <= exe_to_mem_bus[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + 4 - 1 : DATA_WIDTH + DATA_WIDTH + 4];
				e_regData <= exe_to_mem_bus[DATA_WIDTH + DATA_WIDTH + 4 - 1 : DATA_WIDTH + 4];
				load_strb <= exe_to_mem_bus[DATA_WIDTH + 4 - 1 : DATA_WIDTH];
				load_data <= exe_to_mem_bus[DATA_WIDTH - 1 : 0];
				mem_valid <= 1'b1;
			end 
			if(mem_to_wb_valid &&wb_to_mem_ready) begin
				mem_valid <= 1'b0;
			end
		end
	end
	
	wire [DATA_WIDTH - 1 :0] byteReadData = {{(DATA_WIDTH - 8){load_data[7] && load_inst == 3'h1}},load_data[7:0]};
	
	wire [DATA_WIDTH - 1:0] halfReadData = {{(DATA_WIDTH - 16){load_data[15] && load_inst == 3'h2}},load_data[15:0]};
	wire [DATA_WIDTH - 1:0] m_regData = load_inst == 3'h0 ? e_regData :
					 		load_inst == 3'h1 || load_inst == 3'h4 ? byteReadData :
							load_inst == 3'h2 || load_inst == 3'h5 ? halfReadData :
					   		load_inst == 3'h3 ? {{(DATA_WIDTH-32){load_data[31]}},load_data[31:0]} : {DATA_WIDTH{1'b0}} ;

	assign mem_to_wb_bus = {
		e_regW,
		e_regAddr,
		m_regData
	};

endmodule
