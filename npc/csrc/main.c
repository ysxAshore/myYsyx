#include <Vtop.h>
#include <Vtop__Dpi.h>
#include <verilated_vcd_c.h>
#include "include/debug.h"
#include <getopt.h>

#define BASE 0x80000000

static TOP_NAME dut;
static bool isFinish = false;
static char * img_file = NULL;
static char * log_file = NULL;
static uint32_t *img = NULL;
FILE *log_fp = NULL;

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

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
	img = (uint32_t*)realloc(img,3);
	img[0] = 0x00a00093; //addi x1,x0,10
	img[1] = 0x0ff00113; //addi x2,x0,255
	img[2] = 0x00100073; //ebreak
    return 12; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  img = (uint32_t *)realloc(img,size);
  int ret = fread(img, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

void init_log() {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout");
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
	{"log"      , required_argument, NULL, 'l'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  //保留一个-将非选项参数作为长选项处理 返回1
  while ( (o = getopt_long(argc, argv, "-l:", table, NULL)) != -1) {
    switch (o) {
	  case 'l': log_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE \n\n", argv[0]);
		printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

int main(int argc, char *argv[]) {

	parse_args(argc,argv);
	load_img();
	init_log();

    VerilatedVcdC * tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    dut.trace(tfp,0);
    tfp->open("wave.vcd");	

	const int clk_period = 10; // 时钟周期 10个仿真时间单位
	const int reset_cycles = 5;// 复位持续周期数
	vluint64_t sim_time = 0;

	dut.clk = 1;
	dut.rst = 0;

	while(!Verilated::gotFinish()) {
		if(sim_time == reset_cycles * clk_period)
			dut.rst = 1;
		if(sim_time % (clk_period/2) == 0){
			dut.clk = !dut.clk;
			if(dut.clk){
				dut.eval();
				dut.inst = pmem_read(dut.pc,4);
				Log("%x %x\n",dut.pc,dut.inst);
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
