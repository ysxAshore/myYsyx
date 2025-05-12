module seg(
  input clk,
  input rst,
  output [7:0] o_seg0,
  output [7:0] o_seg1,
  output [7:0] o_seg2,
  output [7:0] o_seg3,
  output [7:0] o_seg4,
  output [7:0] o_seg5,
  output [7:0] o_seg6,
  output [7:0] o_seg7
);

wire [7:0] segs [7:0];
assign segs[0] = 8'b00000010;
assign segs[1] = 8'b10011111;
assign segs[2] = 8'b00100101;
assign segs[3] = 8'b00001101;
assign segs[4] = 8'b10011001;
assign segs[5] = 8'b01001001;
assign segs[6] = 8'b01000001;
assign segs[7] = 8'b00011111;

parameter CLK_NUM = 5000000;

reg [31:0] count;
reg [2:0] offset; //数组索引

always @(posedge clk) begin
  if(rst) begin 
	  count <= 0; 
	  offset <= 0; 
  end else begin
	  if(count == CLK_NUM) begin 
		  offset <= offset + 1; 
	  end //自动归0
      count <= (count == CLK_NUM) ? 0 : count + 1;
  end
end

assign o_seg0 = segs[offset + 3'd0]; //初值取0
assign o_seg1 = segs[offset + 3'd1]; //初值取1
assign o_seg2 = segs[offset + 3'd2]; //初值取2
assign o_seg3 = segs[offset + 3'd3]; //初值取3
assign o_seg4 = segs[offset + 3'd4]; //初值取4
assign o_seg5 = segs[offset + 3'd5]; //初值取5
assign o_seg6 = segs[offset + 3'd6]; //初值取6
assign o_seg7 = segs[offset + 3'd7]; //初值取7

endmodule
