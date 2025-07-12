module ifu #(parameter DATA_WIDTH = 32)(
  input clk,
  input rst,

  //ID2IF Bus 
  input [DATA_WIDTH - 1 : 0] id_to_if_bus, //dnpc
  input        id_to_if_valid,
  output       if_to_id_ready,

  //IF2ID Bus
  output [DATA_WIDTH + DATA_WIDTH - 1 : 0] if_to_id_bus,//pc+inst
  output reg        if_to_id_valid,
  input             id_to_if_ready,

  input wb_to_if_done
);

  // 当前PC寄存器
  reg [DATA_WIDTH - 1 : 0] fetch_pc;
  reg        fetch_valid;

  // 存储ID阶段发来的PC
  wire [31:0] next_pc;
  assign next_pc = id_to_if_bus;

  wire [DATA_WIDTH - 1 : 0] inst;

  // 接收新的 PC
  wire accept_new_pc = id_to_if_valid && if_to_id_ready;

  //当前流水级false或者id级准备好接收信息
  assign if_to_id_ready = (!fetch_valid || id_to_if_ready) & wb_to_if_done;

  always @(posedge clk) begin
    if (!rst) begin
      fetch_pc <= 32'h8000_0000;
      fetch_valid <= 1'b1;
      if_to_id_valid <= 1'b0;
    end else begin
      if (accept_new_pc) begin
        fetch_pc <= next_pc;
        fetch_valid <= 1'b1;
      end

      // 发出指令
      if (fetch_valid && id_to_if_ready) begin
//        inst <= mem_read(fetch_pc);
        if_to_id_valid <= 1'b1;
        fetch_valid <= 1'b0; // 清除旧指令状态
      end else if (if_to_id_valid && ~id_to_if_ready) begin
        // 等待ID阶段准备好
        if_to_id_valid <= 1'b1;
      end else begin
        if_to_id_valid <= 1'b0;
      end
    end
  end
  assign if_to_id_bus = {fetch_pc,inst};

  IFU_SRAM ifu_sram(
    .clk(clk),
    .rst(rst),
    .addr(fetch_pc),
    .data(inst)
  );

endmodule

module IFU_SRAM #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 32
)(
  input clk,
  input rst,
  input [ADDR_WIDTH - 1 : 0] addr,
  output reg [DATA_WIDTH - 1 : 0] data
);
  // 通过 DPI-C 从内存读指令
  import "DPI-C" function bit [DATA_WIDTH - 1 : 0] mem_read(input logic [31:0] raddr);
  always @(posedge clk) begin
    if(rst) begin //在复位无效后开始取指
      data <=  mem_read(addr);
    end
  end
endmodule
