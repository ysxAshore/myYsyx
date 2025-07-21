module exu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
	input clk,
	input rst,

	input [DATA_WIDTH + DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 19 - 1 : 0] id_to_exe_bus,
	input id_to_exe_valid,
	output exe_to_id_ready,

	output [DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 8 - 1 : 0] exe_to_mem_bus,
	output exe_to_mem_valid,
	input mem_to_exe_ready,
	
	//AXI
	input arready,
	output reg arvalid,
	output [31 : 0] araddr,
	output [3:0] arid,
	output [7:0] arlen,
	output [2:0] arsize,
	output [1:0] arburst,

	output rready,
	input rvalid,
	input rlast,
	input [1:0] rresp,
	input [3:0] rid,
	input [DATA_WIDTH - 1 : 0] rdata,

	input awready,
	output reg awvalid,
	output [31 : 0] awaddr,
	output [3:0] awid,
	output [7:0] awlen,
	output [2:0] awsize,
	output [1:0] awburst,

	input wready,
	output reg wvalid,
	output [3:0] wstrb,
	output wlast,
	output [DATA_WIDTH - 1 : 0] wdata,
	
	input bvalid,
	input [3:0] bid,
	output bready,
	input [1:0] bresp
);
	reg exe_valid;

	reg [DATA_WIDTH - 1 : 0] aluSrc1;
	reg [DATA_WIDTH - 1 : 0] aluSrc2;
	reg [10 : 0] aluOp;
	reg d_regW;
	reg [ADDR_WIDTH - 1 : 0] d_regAddr;
	reg [2 : 0] load_inst;
	reg [3 : 0] store_mask;
	reg [DATA_WIDTH - 1 : 0] store_data;
	
	assign exe_to_id_ready = ~exe_valid || mem_to_exe_ready;
	
	wire [3:0] rstrb;
	wire [DATA_WIDTH - 1 : 0] load_data;
	wire [DATA_WIDTH-1:0] aluResult;

	//AXI
	assign rready = rvalid;
	assign bready = bvalid;
	
	assign araddr = aluResult;
	assign arid = 4'b1;
  	assign arsize = load_inst == 3'b001 || load_inst == 3'b100 ? 3'h0 :
					load_inst == 3'b010 || load_inst == 3'b101 ? 3'h1 :
					load_inst == 3'b011 ? 3'h2 : 3'h0;//每次传输2**arsize大小数据 
	assign rstrb = load_inst == 3'b001 || load_inst == 3'b100 ? (1 << aluResult[1:0]) : //lb/lbu
				   load_inst == 3'b010 || load_inst == 3'b101 ? (aluResult[1:0] == 2'b00 ? 4'b0011 :
				   												 aluResult[1:0] == 2'b01 ? 4'b0110 :
																 aluResult[1:0] == 2'b10 ? 4'b1100 : 4'b0) :  //lh/lhu
				   load_inst == 3'b011 ? 4'b1111 : 4'b0;
	assign arlen = 8'b0;  // arburst == 2'b01(incr)时支持256次 其余最大为16 传输arlen+1次
  	assign arburst = 2'b0;//地址不变 2'h01时incr 2'h10时
	assign load_data = rdata;
	
	assign awid = 4'b1;
	assign awlen = 8'h0;
	assign awsize = 3'h2;
	assign awburst = 2'h0;
	assign awaddr = aluResult;

	wire [31:0] byteWriteData = aluResult[1:0] == 2'h1 ? store_data << 8 :
								aluResult[1:0] == 2'h2 ? store_data << 16 :
								aluResult[1:0] == 2'h3 ? store_data << 24 : store_data;
	wire [31:0] halfWriteData = aluResult[1:0] == 2'h1 ? store_data << 8 :
								aluResult[1:0] == 2'h2 ? store_data << 16 : store_data;								
	assign wdata = store_mask == 4'h1 ? byteWriteData :
				   store_mask == 4'h3 ? halfWriteData :
				   store_data;
	assign wlast = 'b1;
	assign wstrb = store_mask == 4'h1 ? (1 << aluResult[1:0]) : //sb
				   store_mask == 4'h3 ? (aluResult[1:0] == 2'b00 ? 4'b0011 : //sh
				   						 aluResult[1:0] == 2'b01 ? 4'b0110 :
										 aluResult[1:0] == 2'b10 ? 4'b1100 : 4'b0) :
				   store_mask == 4'hf ? 4'b1111 : 4'b0; //sw

	reg send_request_ar_aw;
	reg send_request_w;

	assign exe_to_mem_valid = exe_valid && load_inst != 3'b0 ? rvalid && rready && rresp == 2'b0 && rlast && rid == 4'h1: 
							  exe_valid && store_mask != 4'b0 ? bvalid && bready && bresp == 2'b0 && bid == 4'h1:
							  exe_valid;

	always @(posedge clk) begin
		if(~rst) begin
			arvalid <= 1'b0;
			awvalid <= 1'b0;
			send_request_ar_aw <= 1'b0;
			send_request_w <= 1'b0;
		end else begin
			if(id_to_exe_valid && exe_to_id_ready) begin
				exe_valid <= 1'b1;
				aluSrc1 <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + DATA_WIDTH + 4 + 3 + 12 - 1: DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + 4 + 3 + 12];
                aluSrc2 <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + DATA_WIDTH + 4 + 3 + 12 - 1 : DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 12];
				aluOp <= id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 12 - 1 : DATA_WIDTH + ADDR_WIDTH + 4 + 3 + 1];
				d_regW = id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 : DATA_WIDTH + ADDR_WIDTH + 4 + 3]; 
				d_regAddr = id_to_exe_bus[DATA_WIDTH + ADDR_WIDTH + 4 + 3 - 1 : DATA_WIDTH + 4 + 3];
				load_inst = id_to_exe_bus[DATA_WIDTH + 4 + 3 - 1 : DATA_WIDTH + 4];
				store_mask = id_to_exe_bus[DATA_WIDTH + 4 - 1 : DATA_WIDTH];
				store_data = id_to_exe_bus[DATA_WIDTH - 1 : 0];
			end

			if(exe_valid) begin
				if(load_inst != 3'b0) begin
					if(~arvalid && ~send_request_ar_aw) begin
						arvalid <= 1'b1;
						send_request_ar_aw <= 1'b1;
					end else if(arvalid && arready) begin
						arvalid <= 1'b0;
					end
				end else if(store_mask != 4'b0) begin
					if(~awvalid && ~send_request_ar_aw) begin
						awvalid <= 1'b1;
						send_request_ar_aw <= 1'b1;
					end else if(awvalid && awready) begin
						awvalid <= 1'b0;
					end
					//先发AW再发W
					if(awvalid && awready && ~wvalid && ~send_request_w) begin
						wvalid <= 1'b1;
						send_request_w <= 1'b1;
					end else if(wvalid && wready) begin
						wvalid <= 1'b0;
					end
				end 
			end

			if(rvalid && rready && rid == 4'h1) begin
				send_request_ar_aw <= 1'b0;
			end

			if(bvalid && bready && bid == 4'h1) begin
				send_request_ar_aw <= 1'b0;
				send_request_w <= 1'b0;
			end

			if(exe_to_mem_valid && mem_to_exe_ready) begin
				exe_valid <= 1'b0;
			end
		end
	end
	
	alu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) exe_alu(
		.aluOp(aluOp),
		.aluSrc1(aluSrc1),
		.aluSrc2(aluSrc2),
		.aluResult(aluResult)
	);

	assign exe_to_mem_bus = {
		load_inst,
		d_regW,
		d_regAddr,
		aluResult,
		rstrb,
		load_data
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
