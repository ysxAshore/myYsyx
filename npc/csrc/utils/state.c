#include <utils.h>
#include <Vtop__Dpi.h> //DPI-C函数的头文件 在该.h中声明了DPI-C函数
#include <verilated_vcd_c.h>

bool isFinish = false;
static int state = 0;
extern VerilatedVcdC *tfp;

NPCState npc_state = {.state = NPC_STOP};

int is_exit_status_bad()
{
	tfp->close();
	delete tfp;

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
