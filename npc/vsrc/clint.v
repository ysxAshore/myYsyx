module axi4lite_clint #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)(
  input clk,
  input rst,

  //ar  
  input arvalid,
  input [ADDR_WIDTH - 1 : 0] araddr,
  output arready,

  //r
  input rready,
  output reg [1:0] rresp,
  output reg rvalid,
  output reg [DATA_WIDTH - 1 : 0] rdata,

  //aw
  input awvalid,
  input [ADDR_WIDTH - 1 : 0] awaddr,
  output awready,

  //w
  input wvalid,
  input [3:0] wstrb,
  input [DATA_WIDTH - 1 : 0] wdata,
  output wready,

  //b
  input bready,
  output reg bvalid,
  output reg [1:0] bresp
);
    reg [63:0] mtime;

  	assign arready = 1'b1; //总是可以接受读请求
	assign awready = 1'b1; //总是可以接受写请求

	reg [3:0] delay_cnt;
	reg pending_read;

	wire [3:0] rand_delay;
	lfsr4 lfsr(.clk(clk), .rst(rst), .rnd(rand_delay));

	// 通过 DPI-C 从内存读
  	import "DPI-C" function bit [DATA_WIDTH - 1 : 0] mem_read(input logic [31:0] raddr);
  	always @(posedge clk) begin
   		if(~rst) begin
      		rvalid <= 1'b0;
			pending_read <= 1'b0;
            mtime <= 'h0;
		end else begin
            mtime <= mtime + 'b1;
    		if(arvalid && arready && ~pending_read) begin //在复位无效后开始取指
		   		delay_cnt <= rand_delay % 8;
		   		pending_read <= 1'b1;
			end else if(pending_read) begin
				if(delay_cnt == 4'b0) begin
      				rdata <= araddr == 32'ha000_0048 ? mtime[31:0] :
                             araddr == 32'ha000_004c ? mtime[63:32] :
                             32'h0;
      				rvalid <= 1'b1;
      				rresp <= 2'b0;
					pending_read <= 1'b0;
				end else begin
					delay_cnt <= delay_cnt - 4'b1;
				end
			end
			if(rvalid && rready) begin
   		   		rvalid <= 1'b0;
    		end
  		end
	end
	// aw 和 w 通道应该是解耦的 即允许同时发送awaddr和wdata
	// 因此需要使用reg暂存发来的wdata wstrb awaddr
	// 当他们都有效时 就可以发送写请求
	reg [ADDR_WIDTH - 1 : 0] reg_awaddr;
	reg [DATA_WIDTH - 1 : 0] reg_wdata;
	reg [3 : 0] reg_wstrb;
	reg aw_regValid;
	reg w_regValid;

	reg pending_write;

	assign awready = ~aw_regValid;
	assign wready = ~w_regValid;

	import "DPI-C" function void mem_write(input logic[31:0] waddr, input logic[31:0] wdata, input byte wmask);
	always @(posedge clk) begin
		if(~rst) begin
			bvalid <= 1'b0;
			aw_regValid <= 1'b0;
			w_regValid <= 1'b0;
			pending_write <= 1'b0;
		end else begin
			if(awready && awvalid) begin
				aw_regValid <= 1'b1;
				reg_awaddr <= awaddr;
			end

			if(wready && wvalid) begin
				w_regValid <= 1'b1;
				reg_wdata <= wdata;
				reg_wstrb <= wstrb;
			end

			if(aw_regValid && w_regValid && ~pending_write) begin
				pending_write <= 1'b1;
				delay_cnt <= rand_delay % 8;
			end else if(pending_write) begin
				if(delay_cnt == 4'b0) begin
					aw_regValid <= 1'b0;
					w_regValid <= 1'b0;
                    mtime <= reg_awaddr == 32'ha000_0048 ? {mtime[63:32],reg_wdata} :
                             reg_awaddr == 32'ha000_004c ? {reg_wdata,mtime[31:0]} :
                             mtime;
					// mem_write(reg_awaddr,reg_wdata,{4'b0,reg_wstrb});
                    $fflush;
                    bvalid <= 1'b1;
					bresp <= 2'b0;

					pending_write <= 1'b0;
				end else begin
					delay_cnt <= delay_cnt - 4'b1;
				end
			end

			if(bvalid && bready) begin
				bvalid <= 1'b0;
			end
		end
	end
	
endmodule