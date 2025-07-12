module ifu #(parameter DATA_WIDTH = 32)(
  input clk,
  input rst,

  //ID2IF Bus 
  input [DATA_WIDTH - 1 : 0] id_to_if_bus, //dnpc
  input        id_to_if_valid,
  output       if_to_id_ready,

  //IF2ID Bus
  output [DATA_WIDTH + DATA_WIDTH - 1 : 0] if_to_id_bus,//pc+inst
  output            if_to_id_valid,
  input             id_to_if_ready,

  input wb_to_if_done
);

  // 当前PC寄存器
  reg [DATA_WIDTH - 1 : 0] fetch_pc;
  reg fetch_valid;

  // 存储ID阶段发来的PC
  reg [31:0] next_pc;

  // IFU内部连接SRAM的AXI读端口信号
  reg arvalid;
  wire arready;
  wire rready = rvalid;
  wire rvalid;
  wire [1:0] rresp;
  wire [DATA_WIDTH-1:0] rdata;

  // AXI 额外控制
  reg send_request;

  // 接收新的 PC
  wire accept_new_pc = wb_to_if_done;

  //当前流水级false或者id级准备好接收信息
  assign if_to_id_ready = !fetch_valid || id_to_if_ready;
  assign if_to_id_valid = fetch_valid && rvalid && rready;

  always @(posedge clk) begin
    if (!rst) begin
      arvalid <= 1'b0;
      fetch_pc <= 32'h8000_0000;
      fetch_valid <= 1'b1;
      send_request <= 1'b0;
    end else begin
      // 接收来自 ID 阶段的新 PC
      if (accept_new_pc) begin
        fetch_pc <= next_pc;
        fetch_valid <= 1'b1;
      end

      if(id_to_if_valid && if_to_id_ready) begin
        next_pc <= id_to_if_bus;
      end

      // 发出 arvalid，只在“需要发请求 + 没发过请求”时，发起 arvalid
      if ((fetch_valid | accept_new_pc) && !arvalid && ~send_request) begin
        arvalid <= 1'b1;
        send_request <= 1'b1;
      end else if (arvalid && arready) begin
        arvalid <= 1'b0; // 发出后撤销
      end

      // 接收 rvalid 数据
      if (rvalid && rready) begin
        send_request <= 1'b0;
      end

      if(if_to_id_valid && id_to_if_ready) begin
        fetch_valid <= 1'b0;
      end
    end
  end


  assign if_to_id_bus = {fetch_pc,rdata};

  IFU_SRAM ifu_sram (
    .clk(clk),
    .rst(rst),
    .arvalid(arvalid),
    .araddr(fetch_pc),
    .arready(arready),
    .rready(rready),
    .rvalid(rvalid),
    .rresp(rresp),
    .rdata(rdata),
    .awvalid(1'b0), // 未使用写通道
    .awaddr(32'b0),
    .awready(),
    .wvalid(1'b0),
    .wstrb(4'b0),
    .wdata(32'b0),
    .wready(),
    .bready(1'b0),
    .bvalid(),
    .bresp()
  );

endmodule

module IFU_SRAM #(
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
  assign arready = 1'b1; //总是可以接受读请求

  reg [3:0] delay_cnt;
  reg pending;

  wire [3:0] rand_delay;
  lfsr4 lfsr(.clk(clk), .rst(rst), .rnd(rand_delay));

  // 通过 DPI-C 从内存读指令
  import "DPI-C" function bit [DATA_WIDTH - 1 : 0] mem_read(input logic [31:0] raddr);
  always @(posedge clk) begin
    if(~rst) begin
      rvalid <= 1'b0;
      pending <= 1'b0;
    end else begin
      if(arvalid && arready && ~pending) begin
        delay_cnt <= rand_delay % 8;
        pending <= 1'b1;
      end else if(pending) begin
        if(delay_cnt == 4'b0) begin
          rvalid <= 1'b1;
          rdata <= mem_read(araddr);
          rresp <= 2'b0;
          pending <= 1'b0;
        end else begin
          delay_cnt <= delay_cnt - 4'b1;
        end
      end
      if(rvalid && rready) begin
        rvalid <= 1'b0;
      end
    end
  end

endmodule

module lfsr4(
  input clk,
  input rst,
  output reg [3:0] rnd
);
  always @(posedge clk or negedge rst) begin
    if (!rst) rnd <= 4'hF; // 初始值不能为 0
    else rnd <= {rnd[2:0], rnd[3] ^ rnd[2]};
  end
endmodule
