module ifu #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)(
  input clk,
  input rst,

  //ID2IF Bus 
  input [DATA_WIDTH - 1 : 0] id_to_if_bus, //dnpc
  input        id_to_if_valid,
  output       if_to_id_ready,

  //IF2ID Bus
  output [ADDR_WIDTH + DATA_WIDTH - 1 : 0] if_to_id_bus,//pc+inst
  output            if_to_id_valid,
  input             id_to_if_ready,

  input wb_to_if_done,

  //axi
  output reg arvalid,
  input arready,
  output [3:0] arid,
  output [7:0] arlen,
  output [2:0] arsize,
  output [1:0] arburst,
  output [ADDR_WIDTH - 1 : 0] araddr,
  output rready,
  input rvalid,
  input [1:0] rresp,
  input [DATA_WIDTH - 1 : 0] rdata,
  input rlast,
  input [3:0] rid
);

  // 当前PC寄存器
  reg [ADDR_WIDTH - 1 : 0] fetch_pc;
  reg fetch_valid;

  // 存储ID阶段发来的PC
  reg [ADDR_WIDTH - 1:0] next_pc;

  // AXI 额外控制
  reg send_request;
  assign rready = rvalid;
  assign araddr = fetch_pc;
  assign arid = 4'b0;
  assign arsize = 3'h2; //每次传输2**arsize大小数据 
  assign arlen = 8'b0;  // arburst == 2'b01(incr)时支持256次 其余最大为16 传输arlen+1次
  assign arburst = 2'b0;//地址不变 2'h01时incr 2'h10时

  // 接收新的 PC
  wire accept_new_pc = wb_to_if_done;

  //当前流水级false或者id级准备好接收信息
  assign if_to_id_ready = !fetch_valid || id_to_if_ready;
  assign if_to_id_valid = fetch_valid && rvalid && rready && rresp == 2'h0 && rid == 4'b0 && rlast;

  always @(posedge clk) begin
    if (!rst) begin
      arvalid <= 1'b0;
      fetch_pc <= 32'h2000_0000;
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

endmodule
