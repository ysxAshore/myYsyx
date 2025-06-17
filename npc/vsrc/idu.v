module idu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
	input clk,
	input [31:0] pc,
	input [31:0] inst,

	output [DATA_WIDTH-1:0] aluSrc1,
	output [DATA_WIDTH-1:0] aluSrc2,
	output [10:0] aluOp,
	output d_regW,
	output [ADDR_WIDTH-1:0] d_regAddr,

	input w_regW,
	input [ADDR_WIDTH-1:0] w_regAddr,
	input [DATA_WIDTH-1:0] w_regData,

	output [31:0] dnpc
);
	//recognize the inst
	wire addi = inst[6:0] == 7'b0010011 && inst[14:12] == 3'b000;
	wire auipc = inst[6:0] == 7'b0010111;
	wire sw = inst[6:0] == 7'b0100011 && inst[14:12] == 3'b010;
	wire lui = inst[6:0] == 7'b0110111;
	wire jalr = inst[6:0] == 7'b1100111 && inst[14:12] == 3'b000;
	wire jal = inst[6:0] == 7'b1101111;
	wire ebreak = inst[31:0] == 32'h0010_0073;

	//categorize the inst
	/*
	000:TYPE_N
	001:TYPE_R
	010:TYPE_I
	011:TYPE_U
	100:TYPE_S
	101:TYPE_B
	110:TYPE_J	
   	*/
	wire TYPE_N = ebreak;
	wire TYPE_R;
	wire TYPE_I = addi;
	wire TYPE_U = auipc;
	wire TYPE_S = sw;
	wire TYPE_B;
	wire TYPE_J = jalr | jal;
	wire [2:0] inst_type;
	assign inst_type[0] = TYPE_R | TYPE_U | TYPE_B;
	assign inst_type[1] = TYPE_I | TYPE_U | TYPE_J;
	assign inst_type[2] = TYPE_S | TYPE_B | TYPE_J;

	//read data,include register data and imm data
	wire [DATA_WIDTH-1:0] regData1;
	wire [DATA_WIDTH-1:0] regData2;
	wire [4:0]rs1 = ebreak ? 5'ha : inst[19:15];
	wire [4:0]rs2 = inst[24:20];
	wire [4:0]rd = inst[11:7];
	wire [DATA_WIDTH-1:0]immI = {{(DATA_WIDTH-12){inst[31]}},inst[31:20]};
	wire [DATA_WIDTH-1:0]immU = {{(DATA_WIDTH-20){inst[31]}},inst[31:12]} << 12;
	wire [DATA_WIDTH-1:0]immJ = {{(DATA_WIDTH-21){inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
	wire [DATA_WIDTH-1:0]immS = {{(DATA_WIDTH-12){inst[31]}},inst[31:25],inst[11:7]};
	wire [DATA_WIDTH-1:0]immB = {{(DATA_WIDTH-13){inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0}; 

	RegisterFile #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)regFile(
		.clk(clk),
		.wen(w_regW),
		.wdata(w_regData),
		.waddr(w_regAddr),
		.raddr1(rs1),
		.rdata1(regData1),
		.raddr2(rs2),
		.rdata2(regData2)
	);

	//decide the alu operands
	assign aluSrc1 = (auipc | jal | jalr)? pc : regData1;
	assign aluSrc2 = jalr | jal ? 32'h4 :
					 {DATA_WIDTH{inst_type == 3'b001}} & regData2 |
					 {DATA_WIDTH{inst_type == 3'b010}} & immI     |
					 {DATA_WIDTH{inst_type == 3'b011}} & immU     |
					 {DATA_WIDTH{inst_type == 3'b100}} & immS     |
					 {DATA_WIDTH{inst_type == 3'b101}} & immB     |
					 {DATA_WIDTH{inst_type == 3'b110}} & immJ;	

	//decide the alu op
	/*
		0: add
		1: sub
		2: slt
		3: sltu
		4: and
		5: or
		6: xor
		7: sll
		8: srl
		9: sra
	   10: lui
	*/
    assign aluOp[0] = addi | auipc | sw | jalr | jal;
	assign aluOp[10] = lui;
    
    //decide the write reg
	assign d_regW = inst_type == 3'b001 | inst_type == 3'b010 | inst_type == 3'b011 | inst_type == 3'b110;
	assign d_regAddr = rd;

	//jump and branch inst
	wire [31:0] snpc = pc + 32'h4;
	wire [31:0] jalr_pc = (regData1 + immI) & ~32'b1;
	wire [31:0] jal_pc = pc + immJ;
	assign dnpc = {32{jalr}} & jalr_pc |
				  {32{jal}}  & jal_pc  |
				  {32{~jal & ~jalr}} & snpc;

	//DPI-C recongnize the ebreak ,then notice the sim terminate
	import "DPI-C" function void callEbreak(int retval,logic[31:0] pc);
	always@(clk)begin //在ebreak上升沿时 pc和regData1都是上个指令的 因此需要在下降沿
		if(ebreak)
			callEbreak(regData1,pc);
	end
`ifdef FTRACE
	import "DPI-C" function void insertFtraceNode(int callType,logic[31:0] from_pc,logic[31:0] to_pc);
	always@(posedge clk)begin
		if(jal && rd == 0 && immJ == 0 && rs1 == 1) 
			insertFtraceNode(1,pc,jal_pc);
		else if(jalr && rd == 0 && immI == 0 && rs1 == 1)
			insertFtraceNode(1,pc,jalr_pc);
		else if((jal || jalr) && rd == 1)
			insertFtraceNode(0,pc,{32{jal}} & jal_pc | {32{jalr}} & jalr_pc);
	end
`endif
endmodule

module RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
  input clk,
  input wen,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input [ADDR_WIDTH-1:0] raddr1,
  output [DATA_WIDTH-1:0] rdata1,
  input [ADDR_WIDTH-1:0] raddr2,
  output [DATA_WIDTH-1:0] rdata2
);
  reg [DATA_WIDTH-1:0] rf [0:(1 << ADDR_WIDTH)-1];
  logic [DATA_WIDTH-1:0] temp_rf [0:(1 << ADDR_WIDTH)-1];
  integer i;
  import "DPI-C" function void recordRegs(input logic [DATA_WIDTH-1:0] dut_regs [2**ADDR_WIDTH-1:0]);
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
	// 创建一个带有更新内容的副本
	temp_rf[0] = {DATA_WIDTH{1'b0}};
    for (i = 1; i < (1 << ADDR_WIDTH); i = i + 1)
    	temp_rf[i] = (i[ADDR_WIDTH-1:0] == waddr && wen) ? wdata : rf[i];
    // 调用 recordRegs，传入的是更新后的数组
    recordRegs(temp_rf);
  end

  assign rdata1 = raddr1 == 0 ? {DATA_WIDTH{1'b0}} : rf[raddr1];
  assign rdata2 = raddr2 == 0 ? {DATA_WIDTH{1'b0}} : rf[raddr2];

endmodule
