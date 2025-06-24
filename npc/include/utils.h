#ifndef __UTILS_H__
#define __UTILS_H__

#include <common.h>

// ----------- state -----------

enum
{
    NPC_RUNNING,
    NPC_STOP,
    NPC_END,
    NPC_ABORT,
    NPC_QUIT
};

typedef struct
{
    int state;
    vaddr_t halt_pc;
    uint32_t halt_ret;
} NPCState;

extern NPCState NPC_state;

// ----------- timer -----------

uint64_t get_time_internal();
uint64_t get_time();
#define TIMER_HZ 60

//------------ ftrace ----------
#include <elf.h>
typedef MUXDEF(CONFIG_ISA64, Elf64_Addr, Elf32_Addr) Elf_Addr;
typedef MUXDEF(CONFIG_ISA64, Elf64_Ehdr, Elf32_Ehdr) Elf_Ehdr;
typedef MUXDEF(CONFIG_ISA64, Elf64_Shdr, Elf32_Shdr) Elf_Shdr;
typedef MUXDEF(CONFIG_ISA64, Elf64_Sym, Elf32_Sym) Elf_Sym;

#endif