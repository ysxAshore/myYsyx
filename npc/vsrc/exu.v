module exu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
	input clk,
	input rst,

	input [DATA_WIDTH + DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 19 - 1 : 0] id_to_exe_bus,
	input id_to_exe_valid,
	output exe_to_id_ready,

	output [DATA_WIDTH + ADDR_WIDTH + 4 - 1 : 0] exe_to_mem_bus,
	output reg exe_to_mem_valid,
	input mem_to_exe_ready,

	output reg[DATA_WIDTH - 1 : 0] load_data
);
	reg [31:0] aluSrc1;
	reg [31:0] aluSrc2;
	reg [10:0] aluOp;
	reg d_regW;
	reg [ADDR_WIDTH-1:0] d_regAddr;
	reg [2:0] load_inst;
	reg [3:0] store_mask;
	reg [DATA_WIDTH-1:0] store_data;

	assign exe_to_id_ready = ~exe_to_mem_valid || mem_to_exe_ready;
	always @(posedge clk) begin
		if(~rst) begin
			exe_to_mem_valid <= 1'b0;
		end else if (id_to_exe_valid && exe_to_id_ready) begin
			aluSrc1 <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH + 4 + 3 + 12 - 1: DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + 4 + 3 + 12];
			aluSrc2 <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + 4 + 3 + 12 - 1 : DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 12];
			aluOp <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 12 - 1 : DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 1];
			d_regW <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 : DATA_WIDTH + ADDR_WIDTH + 4 + 3];
			d_regAddr <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 - 1 : DATA_WIDTH + 4 + 3];
			load_inst <= id_to_exe_bus[DATA_WIDTH + 4 + 3 - 1 : DATA_WIDTH + 4];
			store_mask <= id_to_exe_bus[DATA_WIDTH + 4 - 1 : DATA_WIDTH];
			store_data <= id_to_exe_bus[DATA_WIDTH - 1 : 0];

			exe_to_mem_valid <= 1'b1;
		end else if (mem_to_exe_ready) begin
			exe_to_mem_valid <= 1'b0;
		end
	end
	
	wire [DATA_WIDTH-1:0] aluResult;
	alu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) exe_alu(
		.aluOp(aluOp),
		.aluSrc1(aluSrc1),
		.aluSrc2(aluSrc2),
		.aluResult(aluResult)
	);

	
	import "DPI-C" function bit[DATA_WIDTH-1:0] mem_read(input logic[31:0] raddr);
	import "DPI-C" function void mem_write(input logic[31:0] waddr, input logic[31:0] wdata, input byte wmask);
	always @(posedge clk) begin
		if(exe_to_mem_valid) begin
			if(load_inst != 3'b0) begin
				load_data <= mem_read(aluResult);
			end else begin
				load_data <= {DATA_WIDTH{1'b0}};
			end

			if(store_mask != 4'b0) begin
				mem_write(aluResult,store_data,{4'b0,store_mask});
			end
		end
	end

	assign exe_to_mem_bus = {
		d_regW,
		d_regAddr,
		aluResult,
		load_inst
	};
endmodule

module alu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
	input [10:0] aluOp,
	input [DATA_WIDTH-1:0] aluSrc1,
	input [DATA_WIDTH-1:0] aluSrc2,
	output [DATA_WIDTH-1:0] aluResult	
);
 	wire op_add  = aluOp[0];
 	wire op_sub  = aluOp[1];
 	wire op_slt  = aluOp[2];
 	wire op_sltu = aluOp[3];
 	wire op_and  = aluOp[4];
 	wire op_or   = aluOp[5];
 	wire op_xor  = aluOp[6];
 	wire op_sll  = aluOp[7];
 	wire op_srl  = aluOp[8];
 	wire op_sra  = aluOp[9];
 	wire op_lui  = aluOp[10];
  	
	wire [DATA_WIDTH-1:0] add_sub_result;
 	wire [DATA_WIDTH-1:0] slt_result;
 	wire [DATA_WIDTH-1:0] sltu_result;
 	wire [DATA_WIDTH-1:0] and_result;
 	wire [DATA_WIDTH-1:0] or_result;
 	wire [DATA_WIDTH-1:0] xor_result;
 	wire [DATA_WIDTH-1:0] lui_result;
 	wire [DATA_WIDTH-1:0] sll_result;
 	wire [63:0] sr64_result;
 	wire [DATA_WIDTH-1:0] sr_result;

 	// 32-bit adder 作加减法操作
 	wire [DATA_WIDTH-1:0] adder_a;  //加法器的加数a
 	wire [DATA_WIDTH-1:0] adder_b;  //加法器的加数b
 	wire adder_cin;  //加法器的低位进位
 	wire [DATA_WIDTH-1:0] adder_result;  //加法结果
 	wire adder_cout;  //加法器的进位输出

 	assign adder_a = aluSrc1;  //加数a不用变化
 	assign adder_b   = (op_sub | op_slt | op_sltu) ? ~aluSrc2 : aluSrc2;  //src1 - src2 rj-rk 加数b需要根据执行减法取反
 	assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1 : 1'b0;//因为b只是取反了，减法的话需要加1
 	assign {adder_cout, adder_result} = {1'b0,adder_a} + {1'b0,adder_b} + {{DATA_WIDTH{1'b0}},adder_cin};  //赋值计算

 	// ADD, SUB result
 	assign add_sub_result = adder_result;  //赋值最终的结果

 	// SLT result SLT结果如果src1小于src2那么置1,否则置0
 	assign slt_result[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};  //rj < rk 1
 	assign slt_result[0] = (aluSrc1[DATA_WIDTH-1] & ~aluSrc2[DATA_WIDTH-1])  //src1是负数，src2是正数
 	    | ((aluSrc1[DATA_WIDTH-1] ~^ aluSrc2[DATA_WIDTH-1]) & adder_result[DATA_WIDTH-1]);//~^表示同或，src1和src2符号相同，src1<src2时，正数作差是负数，负数作差还是负数

 	// SLTU result
 	assign sltu_result[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
 	assign sltu_result[0]    = ~adder_cout;//无符号数比较，如果src1>src2时，高位进位输出1

 	// bitwise operation
 	assign and_result = aluSrc1 & aluSrc2;  //与结果
 	assign or_result = aluSrc1 | aluSrc2;  //或结果      
 	assign xor_result = aluSrc1 ^ aluSrc2;  //异或
 	assign lui_result = aluSrc2;  //12位立即数的符号扩展

 	// SLL result 
 	assign sll_result = aluSrc1 << aluSrc2[4:0];  //rj << i5

 	// SRL, SRA result
 	// {op_sra&alu_src1[DATA_WIDTH-1]}如果是算术右移，那么补全32个符号位；如果不是算术右移，那么补全32个0
 	assign sr64_result = {{32{op_sra & aluSrc1[DATA_WIDTH-1]}}, aluSrc1[DATA_WIDTH-1:0]} >> aluSrc2[4:0];  //rj >> i5 

 	assign sr_result = sr64_result[DATA_WIDTH-1:0];  //再取低位

 	// final result mux
 	assign aluResult = ({DATA_WIDTH{op_add|op_sub}} & add_sub_result)//多路选择，这里直接是根据op进行32位1扩展，全f与结果
 	    			  | ({DATA_WIDTH{op_slt       }} & slt_result)
 	    			  | ({DATA_WIDTH{op_sltu      }} & sltu_result)
 	    			  | ({DATA_WIDTH{op_and       }} & and_result)
 	    			  | ({DATA_WIDTH{op_or        }} & or_result)
 	    			  | ({DATA_WIDTH{op_xor       }} & xor_result)
 	    			  | ({DATA_WIDTH{op_lui       }} & lui_result)
 	    			  | ({DATA_WIDTH{op_sll       }} & sll_result)
 	    			  | ({DATA_WIDTH{op_srl|op_sra}} & sr_result);
endmodule
