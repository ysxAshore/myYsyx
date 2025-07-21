#include <common.h>

#ifdef CONFIG_VCD
#include <verilated_vcd_c.h>
#endif

void init_monitor(int, char *[]);
void engine_start();
int is_exit_status_bad();

int main(int argc, char *argv[])
{
#ifdef CONFIG_VCD
	Verilated::commandArgs(argc, argv);
#endif
	init_monitor(argc, argv);
	engine_start();
	return is_exit_status_bad();
}
