#ifndef __CPU_CPU_H__
#define __CPU_CPU_H__

#include <common.h>
#include <Vtop.h>
#include <Vtop__Dpi.h>
#include <verilated_vcd_c.h>

#define NR_GPR MUXDEF(CONFIG_RVE, 16, 32)

typedef struct
{
    word_t gprs[NR_GPR];
    word_t pc;
} CPUState;

void cpu_exec(uint64_t n);

#endif