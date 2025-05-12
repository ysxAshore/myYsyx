// 子模块端口命名也尽量与nxdc保持一致
module led(
  input clk,
  input rst,
  input [4:0] btn,
  input [7:0] sw,
  output [15:0] ledr
);
  reg [31:0] count; //延时设置
  reg [7:0] led; // 8-15流水灯
  always @(posedge clk) begin
    if (rst) begin 
		led <= 1; 
		count <= 0; 
	end else begin
      if (count == 0) 
		  led <= {led[6:0], led[7]}; //流水
      count <= (count >= 5000000 ? 32'b0 : count + 1); //延时5000000
	end
  end
  assign ledr = {led[7:5], led[4:0] ^ btn, sw}; //sw决定低8个led灯 中间8-12的亮灭与btn取反(异或)
endmodule
