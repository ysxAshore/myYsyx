module NPC(
	input clock,
	input reset,
	input io_interrupt,
	
	input io_master_awready,
	output io_master_awvalid,
	output [31:0] io_master_awaddr,
	output [3:0] io_master_awid,
	output [7:0] io_master_awlen,
	output [2:0] io_master_awsize,
	output [1:0] io_master_awburst,
	
	input io_master_wready,
	output io_master_wvalid,
	output [31:0] io_master_wdata,
	output [3:0] io_master_wstrb,
	output io_master_wlast,

	output io_master_bready,
	input io_master_bvalid,
	input [1:0] io_master_bresp,
	input [3:0] io_master_bid,

	input io_master_arready,
	output io_master_arvalid,
	output [31:0] io_master_araddr,
	output [3:0] io_master_arid,
	output [7:0] io_master_arlen,
	output [2:0] io_master_arsize,
	output [1:0] io_master_arburst,

	output io_master_rready,
	input io_master_rvalid,
	input [1:0] io_master_rresp,
	input [3:0] io_master_rid,
	input io_master_rlast,
	input [31:0] io_master_rdata,

	output io_slave_awready,
	input io_slave_awvalid,
	input [31:0] io_slave_awaddr,
	input [3:0] io_slave_awid,
	input [7:0] io_slave_awlen,
	input [2:0] io_slave_awsize,
	input [1:0] io_slave_awburst,
	
	output io_slave_wready,
	input io_slave_wvalid,
	input [31:0] io_slave_wdata,
	input [3:0] io_slave_wstrb,
	input io_slave_wlast,

	input io_slave_bready,
	output io_slave_bvalid,
	output [1:0] io_slave_bresp,
	output [3:0] io_slave_bid,

	output io_slave_arready,
	input io_slave_arvalid,
	input [31:0] io_slave_araddr,
	input [3:0] io_slave_arid,
	input [7:0] io_slave_arlen,
	input [2:0] io_slave_arsize,
	input [1:0] io_slave_arburst,

	input io_slave_rready,
	output io_slave_rvalid,
	output [1:0] io_slave_rresp,
	output [3:0] io_slave_rid,
	output io_slave_rlast,
	output [31:0] io_slave_rdata,

	output reg [31:0] io_inst,
	output reg [31:0] io_pc,
	output [31:0] io_dnpc,
	output reg io_execute_once
);
	wire rst = !reset;

	localparam DATA_WIDTH = 32;
	localparam ADDR_WIDTH = 5;

	wire [DATA_WIDTH - 1 : 0] id_to_if_bus;
	wire id_to_if_valid;
	wire if_to_id_ready;
	wire [DATA_WIDTH + DATA_WIDTH - 1 : 0] if_to_id_bus;
	wire if_to_id_valid;
	wire id_to_if_ready;
	wire wb_to_if_done;
	wire                      ifu_arvalid;
	wire [            31 : 0] ifu_araddr;
	wire                      ifu_arready;
	wire                      ifu_rvalid;
	wire [DATA_WIDTH - 1 : 0] ifu_rdata;
	wire [             1 : 0] ifu_rresp;
	wire                      ifu_rready;
	wire [			   3 : 0] ifu_arid;
	wire [             7 : 0] ifu_arlen;
	wire [             2 : 0] ifu_arsize;
	wire [             1 : 0] ifu_arburst;
	wire                      ifu_rlast;
	wire [             3 : 0] ifu_rid;

	assign io_dnpc = id_to_if_bus;
	always @(posedge clock) begin
		if(!rst) begin
			io_pc <= 32'h8000_0000;
			io_execute_once <= 1'b0;
		end else begin
			if(if_to_id_valid && id_to_if_ready) begin
				io_inst <= if_to_id_bus[DATA_WIDTH - 1 : 0];
				io_pc <= if_to_id_bus[DATA_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH];
			end
			if(wb_to_id_valid && id_to_wb_ready) begin
				io_execute_once <= 1'b1;
			end else if(io_execute_once) begin
				io_execute_once <= 1'b0;
			end
		end
	end

	ifu #(
		.DATA_WIDTH(DATA_WIDTH)
	)if_stage(
		.clk(clock),
		.rst(rst),
		.id_to_if_bus(id_to_if_bus),
		.id_to_if_valid(id_to_if_valid),
		.if_to_id_ready(if_to_id_ready),
		.if_to_id_bus(if_to_id_bus),
		.if_to_id_valid(if_to_id_valid),
		.id_to_if_ready(id_to_if_ready),
		.wb_to_if_done(wb_to_if_done),
		.arvalid(ifu_arvalid),
		.araddr(ifu_araddr),
		.arready(ifu_arready),
		.rvalid(ifu_rvalid),
		.rdata(ifu_rdata),
		.rresp(ifu_rresp),
		.rready(ifu_rready),
		.arid(ifu_arid),
		.arlen(ifu_arlen),
		.arsize(ifu_arsize),
		.arburst(ifu_arburst),
		.rlast(ifu_rlast),
		.rid(ifu_rid)
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
		.clk(clock),
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

	wire [DATA_WIDTH + DATA_WIDTH + ADDR_WIDTH + 8 - 1 : 0] exe_to_mem_bus;
	wire exe_to_mem_valid;
	wire mem_to_exe_ready;

	wire                      lsu_arvalid;
	wire [32 - 1 : 0] lsu_araddr;
	wire                      lsu_arready;
	wire                      lsu_rvalid;
	wire [DATA_WIDTH - 1 : 0] lsu_rdata;
	wire [             1 : 0] lsu_rresp;
	wire                      lsu_rready;
	wire [			   3 : 0] lsu_arid;
	wire [             7 : 0] lsu_arlen;
	wire [             2 : 0] lsu_arsize;
	wire [             1 : 0] lsu_arburst;
	wire                      lsu_rlast;
	wire [             3 : 0] lsu_rid;
	wire                      lsu_awvalid;
	wire [        32 - 1 : 0] lsu_awaddr;
	wire                      lsu_awready;
	wire [             3 : 0] lsu_awid;
	wire [             7 : 0] lsu_awlen;
	wire [             2 : 0] lsu_awsize;
	wire [             1 : 0] lsu_awburst;
	wire                      lsu_wvalid;
	wire [DATA_WIDTH - 1 : 0] lsu_wdata;
	wire [			   3 : 0] lsu_wstrb;		
	wire 					  lsu_wlast;
	wire                      lsu_wready;
	wire [ 			   3 : 0] lsu_bid;	
	wire                      lsu_bvalid;
	wire [             1 : 0] lsu_bresp;
	wire                      lsu_bready;
	
	exu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)exe_stage(
		.clk(clock),
		.rst(rst),
		.id_to_exe_bus(id_to_exe_bus),
		.id_to_exe_valid(id_to_exe_valid),
		.exe_to_id_ready(exe_to_id_ready),
		.exe_to_mem_bus(exe_to_mem_bus),
		.exe_to_mem_valid(exe_to_mem_valid),
		.mem_to_exe_ready(mem_to_exe_ready),
	  	.arvalid(lsu_arvalid),
	  	.araddr(lsu_araddr),
	  	.arready(lsu_arready),
	  	.rready(lsu_rready),
	  	.rvalid(lsu_rvalid),
	  	.rresp(lsu_rresp),
	  	.rdata(lsu_rdata),
	  	.awvalid(lsu_awvalid), // 未使用写通道
	  	.awaddr(lsu_awaddr),
	  	.awready(lsu_awready),
	  	.wvalid(lsu_wvalid),
	  	.wstrb(lsu_wstrb),
	  	.wdata(lsu_wdata),
	  	.wready(lsu_wready),
	  	.bready(lsu_bready),
	  	.bvalid(lsu_bvalid),
	  	.bresp(lsu_bresp),
		.arid(lsu_arid),
		.arlen(lsu_arlen),
		.arsize(lsu_arsize),
		.arburst(lsu_arburst),
		.rlast(lsu_rlast),
		.rid(lsu_rid),
		.awid(lsu_awid),
		.awlen(lsu_awlen),
		.awsize(lsu_awsize),
		.awburst(lsu_awburst),
		.wlast(lsu_wlast),
		.bid(lsu_bid)
	);

	wire [DATA_WIDTH + ADDR_WIDTH + 1 - 1 : 0] mem_to_wb_bus;
	wire mem_to_wb_valid;
	wire wb_to_mem_ready;
	mmu #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	)mem_stage(
		.clk(clock),
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
		.clk(clock),
		.rst(rst),
		.mem_to_wb_bus(mem_to_wb_bus),
		.mem_to_wb_valid(mem_to_wb_valid),
		.wb_to_mem_ready(wb_to_mem_ready),
		.wb_to_id_bus(wb_to_id_bus),
		.wb_to_id_valid(wb_to_id_valid),
		.id_to_wb_ready(id_to_wb_ready),
		.wb_to_if_done(wb_to_if_done)
	);

  	//ar  
 	wire arvalid;
 	wire [32 - 1 : 0] araddr;
 	wire arready;

 	//r
 	wire rready;
 	wire [1:0] rresp;
 	wire rvalid;
 	wire [DATA_WIDTH - 1 : 0] rdata;

 	//aw
 	wire awvalid;
 	wire [32 - 1 : 0] awaddr;
 	wire awready;

 	//w
 	wire wvalid;
 	wire [3:0] wstrb;
 	wire [DATA_WIDTH - 1 : 0] wdata;
 	wire wready;

 	//b
 	wire bready;
 	wire bvalid;
 	wire [1:0] bresp;

	axi4lite_arbiter arbiter(
	    // 时钟/复位
	    .clk        (clock),
	    .rst        (rst),

	    .ifu_arvalid(ifu_arvalid),
	    .ifu_araddr (ifu_araddr),
	    .ifu_arready(ifu_arready),
	    .ifu_rvalid (ifu_rvalid),
	    .ifu_rdata  (ifu_rdata),
	    .ifu_rresp  (ifu_rresp),
	    .ifu_rready (ifu_rready),
		.ifu_arid	(ifu_arid),
		.ifu_arlen 	(ifu_arlen),
		.ifu_arsize	(ifu_arsize),
		.ifu_arburst(ifu_arburst),
		.ifu_rlast	(ifu_rlast),
		.ifu_rid	(ifu_rid),

	    .lsu_arvalid(lsu_arvalid),
	    .lsu_araddr (lsu_araddr),
	    .lsu_arready(lsu_arready),
	    .lsu_rvalid (lsu_rvalid),
	    .lsu_rdata  (lsu_rdata),
	    .lsu_rresp  (lsu_rresp),
	    .lsu_rready (lsu_rready),
		.lsu_arid	(lsu_arid),
		.lsu_arlen	(lsu_arlen),
		.lsu_arsize	(lsu_arsize),
		.lsu_arburst(lsu_arburst),
		.lsu_rlast	(lsu_rlast),
		.lsu_rid	(lsu_rid),

	    .lsu_awvalid(lsu_awvalid),
	    .lsu_awaddr (lsu_awaddr),
	    .lsu_awready(lsu_awready),
		.lsu_awid	(lsu_awid),
		.lsu_awlen	(lsu_awlen),
		.lsu_awsize	(lsu_awsize),
		.lsu_awburst(lsu_awburst),

	    .lsu_wvalid (lsu_wvalid),
	    .lsu_wdata  (lsu_wdata),
		.lsu_wstrb  (lsu_wstrb),
	    .lsu_wready (lsu_wready),
		.lsu_wlast	(lsu_wlast),

	    .lsu_bvalid (lsu_bvalid),      
	    .lsu_bresp  (lsu_bresp),
	    .lsu_bready (lsu_bready),
		.lsu_bid	(lsu_bid),

	    .arvalid    (io_master_arvalid),
	    .araddr     (io_master_araddr),
		.arid       (io_master_arid),
		.arlen  	(io_master_arlen),
		.arsize 	(io_master_arsize),
		.arburst	(io_master_arburst),
	    .arready    (io_master_arready),

	    .rvalid     (io_master_rvalid),
	    .rdata      (io_master_rdata),
	    .rresp      (io_master_rresp),
	    .rready     (io_master_rready),
		.rlast 		(io_master_rlast),
		.rid		(io_master_rid),

	    .awvalid    (io_master_awvalid),
	    .awaddr     (io_master_awaddr),
	    .awready    (io_master_awready),
		.awid       (io_master_awid),
		.awlen  	(io_master_awlen),
		.awsize 	(io_master_awsize),
		.awburst	(io_master_awburst),

	    .wvalid     (io_master_wvalid),
	    .wdata      (io_master_wdata),
		.wstrb      (io_master_wstrb),
		.wlast		(io_master_wlast),
	    .wready     (io_master_wready),

	    .bvalid     (io_master_bvalid),
	    .bresp      (io_master_bresp),
	    .bready     (io_master_bready),
		.bid		(io_master_bid)
	);

endmodule
