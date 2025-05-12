#include <nvboard.h>
#include <Vtop.h>

// TOP_NAME是宏,展开为Vtop
static TOP_NAME dut; 

void nvboard_bind_all_pins(TOP_NAME* top);

// 时钟边沿模拟，模拟了从低电平到高电平的时钟跳变
static void single_cycle() {
	dut.clk = 0; dut.eval();
	dut.clk = 1; dut.eval();
}

static void reset(int n) {
	dut.rst = 1;
	// rst高电平复位 复位n个cycle
	while (n -- > 0) single_cycle();
	dut.rst = 0;
}

int main() {

	//绑定引脚
	nvboard_bind_all_pins(&dut);
	//初始化NVBoard
	nvboard_init();
	//reset 10个时钟周期
	reset(10);

	while(1) {
		// 更新NVBoard中各组件的状态和clk信号,重新计算电路状态
		nvboard_update();
		single_cycle();
	}
}
