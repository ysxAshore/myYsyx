#include <Vtop.h>
#include <Vtop__Dpi.h>
#include <verilated_vcd_c.h>

#define BASE 0x80000000

static TOP_NAME dut;
static bool isFinish = false;
static const uint32_t img [] = {
	0x00a00093, //addi x1,x0,10
	0x0ff00113, //addi x2,x0,255
	0x00100073, //ebreak
};	

uint32_t pmem_read(uint32_t addr,int size){
	uint32_t realAddr = addr - BASE;
	switch(size){
		case 1: return *(uint8_t *)((uintptr_t)img + realAddr);
		case 2: return *(uint16_t *)((uintptr_t)img + realAddr);
		case 4: return *(uint32_t *)((uintptr_t)img + realAddr);
		default: assert(0);return 0;
	}
}

void callEbreak(){
	isFinish = true;
}

int main() {
    VerilatedVcdC * tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    dut.trace(tfp,0);
    tfp->open("wave.vcd");	

	const int clk_period = 10; // 时钟周期 10个仿真时间单位
	const int reset_cycles = 5;// 复位持续周期数
	vluint64_t sim_time = 0;

	dut.clk = 1;
	dut.rst = 0;

	while(!Verilated::gotFinish() && sim_time < 100) {
		if(sim_time == reset_cycles * clk_period)
			dut.rst = 1;
		if(sim_time % (clk_period/2) == 0){
			dut.clk = !dut.clk;
			if(dut.clk){
				dut.eval();
				dut.inst = pmem_read(dut.pc,4);
				printf("%x %x\n",dut.pc,dut.inst);
			}
		}
		dut.eval();

		tfp->dump(sim_time);
		++sim_time;
		if(isFinish)
			break;
	}
	tfp->close();
	delete tfp;
	return 0;
}
