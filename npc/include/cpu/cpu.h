#ifndef __CPU_CPU_H__
#define __CPU_CPU_H__

#include <common.h>
#include <VysyxSoCFull.h>
#include <VysyxSoCFull__Dpi.h>

#ifdef CONFIG_VCD
#include <verilated_vcd_c.h>
#endif

#define NR_GPR MUXDEF(CONFIG_RVE, 16, 32)

typedef struct
{
    word_t gprs[NR_GPR];
    word_t pc;
    word_t inst;
} CPUState;

void cpu_exec(uint64_t n);

#endif