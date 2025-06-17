#include <cpu/cpu.h>
#include <Vtop__Dpi.h> //DPI-C函数的头文件 在该.h中声明了DPI-C函数

// RV32E RV32I Rv64I都是这个顺序
extern TOP_NAME dut;
extern CPUState cpu;
const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};

/*
typedef struct t_vpi_vecval {
  uint32_t aval; // 2-state component
  uint32_t bval; // 4-state component
} s_vpi_vecval, *p_vpi_vecval;
typedef s_vpi_vecval svLogicVecVal;
*/
extern "C" void recordRegs(const svLogicVecVal dut_regs[])
{
    for (size_t i = 0; i < NR_GPR; i++)
        cpu.gprs[i] = dut_regs[i].aval;
    cpu.pc = dut.pc;
}
void isa_reg_display()
{
    for (int i = 0; i < NR_GPR; i = i + 4)
        printf("%s:%#x\t%s:%#x\t%s:%#x\t%s:%#x\n", regs[i], cpu.gprs[i], regs[i + 1], cpu.gprs[i + 1], regs[i + 2], cpu.gprs[i + 2], regs[i + 3], cpu.gprs[i + 3]);
}

word_t isa_reg_str2val(const char *s, bool *success)
{
    for (int i = 1; i < NR_GPR; ++i)
    {
        if (strcmp(s, regs[i]) == 0)
            return cpu.gprs[i];
    }
    if (strcmp(s, "pc") == 0)
        return dut.pc;
    else
    {
        *success = false;
        return 0;
    }
}
