module top(
	input clk,
	input rst,
	output reg [31:0] inst,
	output reg [31:0] pc,
	output [31:0] dnpc,
	output reg execute_once
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
	wire                      ifu_arvalid;
	wire [31 : 0] ifu_araddr;
	wire                      ifu_arready;
	wire                      ifu_rvalid;
	wire [DATA_WIDTH - 1 : 0] ifu_rdata;
	wire [             1 : 0] ifu_rresp;
	wire                      ifu_rready;

	assign dnpc = id_to_if_bus;
	always @(posedge clk) begin
		if(!rst) begin
			pc <= 32'h8000_0000;
			execute_once <= 1'b0;
		end else begin
			if(if_to_id_valid && id_to_if_ready) begin
				inst <= if_to_id_bus[DATA_WIDTH - 1 : 0];
				pc <= if_to_id_bus[DATA_WIDTH + DATA_WIDTH - 1 : DATA_WIDTH];
			end
			if(wb_to_id_valid && id_to_wb_ready) begin
				execute_once <= 1'b1;
			end else if(execute_once) begin
				execute_once <= 1'b0;
			end
		end
	end

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
		.wb_to_if_done(wb_to_if_done),
		.arvalid(ifu_arvalid),
		.araddr(ifu_araddr),
		.arready(ifu_arready),
		.rvalid(ifu_rvalid),
		.rdata(ifu_rdata),
		.rresp(ifu_rresp),
		.rready(ifu_rready)
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

	wire                      lsu_arvalid;
	wire [32 - 1 : 0] lsu_araddr;
	wire                      lsu_arready;
	wire                      lsu_rvalid;
	wire [DATA_WIDTH - 1 : 0] lsu_rdata;
	wire [             1 : 0] lsu_rresp;
	wire                      lsu_rready;
	wire                      lsu_awvalid;
	wire [32 - 1 : 0] lsu_awaddr;
	wire                      lsu_awready;
	wire                      lsu_wvalid;
	wire [DATA_WIDTH - 1 : 0] lsu_wdata;
	wire [			   3 : 0] lsu_wstrb;		
	wire                      lsu_wready;
	wire                      lsu_bvalid;
	wire [             1 : 0] lsu_bresp;
	wire                      lsu_bready;
	
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
	  	.bresp(lsu_bresp)
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
	    .clk        (clk),
	    .rst        (rst),

	    .ifu_arvalid(ifu_arvalid),
	    .ifu_araddr (ifu_araddr),
	    .ifu_arready(ifu_arready),
	    .ifu_rvalid (ifu_rvalid),
	    .ifu_rdata  (ifu_rdata),
	    .ifu_rresp  (ifu_rresp),
	    .ifu_rready (ifu_rready),

	    .lsu_arvalid(lsu_arvalid),
	    .lsu_araddr (lsu_araddr),
	    .lsu_arready(lsu_arready),
	    .lsu_rvalid (lsu_rvalid),
	    .lsu_rdata  (lsu_rdata),
	    .lsu_rresp  (lsu_rresp),
	    .lsu_rready (lsu_rready),

	    .lsu_awvalid(lsu_awvalid),
	    .lsu_awaddr (lsu_awaddr),
	    .lsu_awready(lsu_awready),
	    .lsu_wvalid (lsu_wvalid),
	    .lsu_wdata  (lsu_wdata),
		.lsu_wstrb  (lsu_wstrb),
	    .lsu_wready (lsu_wready),
	    .lsu_bvalid (lsu_bvalid),      
	    .lsu_bresp  (lsu_bresp),
	    .lsu_bready (lsu_bready),

	    .arvalid    (arvalid),
	    .araddr     (araddr),
	    .arready    (arready),
	    .rvalid     (rvalid),
	    .rdata      (rdata),
	    .rresp      (rresp),
	    .rready     (rready),
	    .awvalid    (awvalid),
	    .awaddr     (awaddr),
	    .awready    (awready),
	    .wvalid     (wvalid),
	    .wdata      (wdata),
		.wstrb      (wstrb),
	    .wready     (wready),
	    .bvalid     (bvalid),
	    .bresp      (bresp),
	    .bready     (bready)
	);


    // 到 UART
    wire                 uart_arvalid;
    wire [32-1:0] uart_araddr;
    wire                  uart_arready;

    wire                  uart_rvalid;
    wire  [DATA_WIDTH-1:0] uart_rdata;
    wire  [1:0]            uart_rresp;
    wire                 uart_rready;

    wire                 uart_awvalid;
    wire [32-1:0] uart_awaddr;
    wire                  uart_awready;

    wire                 uart_wvalid;
    wire [DATA_WIDTH-1:0] uart_wdata;
    wire  [          3:0] uart_wstrb;
    wire                  uart_wready;

    wire                  uart_bvalid;
    wire  [1:0]            uart_bresp;
    wire                 uart_bready;

    // 到 SRAM
    wire                 sram_arvalid;
    wire [32-1:0] sram_araddr;
    wire                  sram_arready;

    wire                  sram_rvalid;
    wire  [DATA_WIDTH-1:0] sram_rdata;
    wire  [1:0]            sram_rresp;
    wire                 sram_rready;

    wire                 sram_awvalid;
    wire [32-1:0] sram_awaddr;
    wire                  sram_awready;

    wire                 sram_wvalid;
    wire [DATA_WIDTH-1:0] sram_wdata;
    wire  [          3:0] sram_wstrb;
    wire                  sram_wready;

    wire                  sram_bvalid;
    wire  [1:0]            sram_bresp;
    wire                 sram_bready;

	axi4lite_xbar xbar(
        .clk(clk),
        .rst(rst),
        
        // 来自 Arbiter 的 master 接口
        .arvalid(arvalid),
        .araddr(araddr),
        .arready(arready),
        .rvalid(rvalid),
        .rdata(rdata),
        .rresp(rresp),
        .rready(rready),
        
        .awvalid(awvalid),
        .awaddr(awaddr),
        .awready(awready),
        .wvalid(wvalid),
        .wdata(wdata),
        .wstrb(wstrb),
        .wready(wready),
        
        .bvalid(bvalid),
        .bresp(bresp),
        .bready(bready),
        
        // 到 UART
        .uart_arvalid(uart_arvalid),
        .uart_araddr(uart_araddr),
        .uart_arready(uart_arready),
        .uart_rvalid(uart_rvalid),
        .uart_rdata(uart_rdata),
        .uart_rresp(uart_rresp),
        .uart_rready(uart_rready),
        .uart_awvalid(uart_awvalid),
        .uart_awaddr(uart_awaddr),
        .uart_awready(uart_awready),
        .uart_wvalid(uart_wvalid),
        .uart_wdata(uart_wdata),
        .uart_wstrb(uart_wstrb),
        .uart_wready(uart_wready),
        .uart_bvalid(uart_bvalid),
        .uart_bresp(uart_bresp),
        .uart_bready(uart_bready),
        
        // 到 SRAM
        .sram_arvalid(sram_arvalid),
        .sram_araddr(sram_araddr),
        .sram_arready(sram_arready),
        .sram_rvalid(sram_rvalid),
        .sram_rdata(sram_rdata),
        .sram_rresp(sram_rresp),
        .sram_rready(sram_rready),
        .sram_awvalid(sram_awvalid),
        .sram_awaddr(sram_awaddr),
        .sram_awready(sram_awready),
        .sram_wvalid(sram_wvalid),
        .sram_wdata(sram_wdata),
        .sram_wstrb(sram_wstrb),
        .sram_wready(sram_wready),
        .sram_bvalid(sram_bvalid),
        .sram_bresp(sram_bresp),
        .sram_bready(sram_bready)
    );

	axi4lite_sram sram(
		.clk 		(clk),
		.rst        (rst),
	    .arvalid    (sram_arvalid),
	    .araddr     (sram_araddr),
	    .arready    (sram_arready),
	    .rvalid     (sram_rvalid),
	    .rdata      (sram_rdata),
	    .rresp      (sram_rresp),
	    .rready     (sram_rready),
	    .awvalid    (sram_awvalid),
	    .awaddr     (sram_awaddr),
	    .awready    (sram_awready),
	    .wvalid     (sram_wvalid),
	    .wdata      (sram_wdata),
		.wstrb      (sram_wstrb),
	    .wready     (sram_wready),
	    .bvalid     (sram_bvalid),
	    .bresp      (sram_bresp),
	    .bready     (sram_bready)
	);

	axi4lite_uart uart(
		.clk 		(clk),
		.rst        (rst),
	    .arvalid    (uart_arvalid),
	    .araddr     (uart_araddr),
	    .arready    (uart_arready),
	    .rvalid     (uart_rvalid),
	    .rdata      (uart_rdata),
	    .rresp      (uart_rresp),
	    .rready     (uart_rready),
	    .awvalid    (uart_awvalid),
	    .awaddr     (uart_awaddr),
	    .awready    (uart_awready),
	    .wvalid     (uart_wvalid),
	    .wdata      (uart_wdata),
		.wstrb      (uart_wstrb),
	    .wready     (uart_wready),
	    .bvalid     (uart_bvalid),
	    .bresp      (uart_bresp),
	    .bready     (uart_bready)
	);
endmodule

