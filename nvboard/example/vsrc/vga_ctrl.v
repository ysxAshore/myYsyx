module vga_ctrl (
    input pclk,
    input reset,
    input [23:0] vga_data,
    output [10:0] h_addr,
    output [10:0] v_addr,
    output hsync,
    output vsync,
    output valid,
    output [7:0] vga_r,
    output [7:0] vga_g,
    output [7:0] vga_b
);

parameter H_SYNC = 96,
	      H_BACK = 40,
		  H_LEFT = 8,
		  H_VALID = 640,
		  H_RIGHT = 8,
		  H_FRONT = 8,
		  H_TOTAL = 800;
parameter V_SYNC = 2,
	      V_BACK = 25,
		  V_TOP = 8,
		  V_VALID = 480,
		  V_BOTTOM = 8,
		  V_FRONT = 2,
		  V_TOTAL = 525;

reg [10:0] x_cnt;
reg [10:0] y_cnt;
wire pix_data_req;

always @(posedge pclk) begin
    if(reset) begin
        x_cnt <= 1;
        y_cnt <= 1;
    end
    else begin
        if(x_cnt == H_TOTAL)begin // 先行扫描再列扫描
            x_cnt <= 1;
            if(y_cnt == V_TOTAL) 
				y_cnt <= 1;
            else 
				y_cnt <= y_cnt + 1;
        end else 
			x_cnt <= x_cnt + 1;
    end
end

// 生成同步信号    
assign hsync = x_cnt <= H_SYNC; 
assign vsync = y_cnt <= V_SYNC;

// VGA有效显示区域
assign valid = (x_cnt > H_SYNC + H_BACK + H_LEFT) && (x_cnt <= H_SYNC + H_BACK + H_LEFT + H_VALID) && (y_cnt > V_SYNC + V_BACK + V_TOP) && (y_cnt <= V_SYNC + V_BACK + V_TOP + V_VALID);

//pix_data_req:像素点色彩信息请求信号,超前rgb_valid信号一个时钟周期 但是top中是直接读取的并不需要提前请求
//assign  pix_data_req = (x_cnt >= H_SYNC + H_BACK + H_LEFT)
//					&& (x_cnt < H_SYNC + H_BACK + H_LEFT + H_VALID)
//					&& (y_cnt >= V_SYNC + V_BACK + V_TOP)
//					&& (y_cnt < V_SYNC + V_BACK + V_TOP + V_VALID);

//计算当前有效像素坐标
//assign h_addr = pix_data_req ? (x_cnt - H_SYNC - H_BACK - H_LEFT - 1) : 11'b0;
//assign v_addr = pix_data_req ? (y_cnt - V_SYNC - V_BACK - V_TOP - 1) : 11'b0;
assign h_addr = valid ? (x_cnt - H_SYNC - H_BACK - H_LEFT - 1) : 11'b0;
assign v_addr = valid ? (y_cnt - V_SYNC - V_BACK - V_TOP - 1) : 11'b0;

//设置输出的颜色值
assign {vga_r, vga_g, vga_b} = vga_data;

endmodule
