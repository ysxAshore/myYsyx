#include <utils.h>
#include <Vtop__Dpi.h> //DPI-C函数的头文件 在该.h中声明了DPI-C函数
#include <verilated_vcd_c.h>

bool isFinish = false;
static int state = 0;

NPCState npc_state = {.state = NPC_STOP};

int is_exit_status_bad()
{
#ifdef CONFIG_VCD
	extern VerilatedVcdC *tfp;
	tfp->close();
	delete tfp;
#endif

	int good = (npc_state.state == NPC_END && npc_state.halt_ret == 0) ||
			   (npc_state.state == NPC_QUIT);
	return !good;
}

extern "C" void callEbreak(int retval, const svLogicVecVal *pc)
{
	isFinish = true;
	npc_state.halt_pc = pc->aval;
	npc_state.halt_ret = retval;
	npc_state.state = NPC_END;
}
