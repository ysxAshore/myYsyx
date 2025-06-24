#include <cpu/cpu.h>
#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <verilated_vcd_c.h>

static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
extern CPUState cpu;

uint8_t *guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len)
{
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data)
{
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr)
{
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
        addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem()
{
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len)
{
#ifdef CONFIG_MTRACE
  printf("This is a paddr_read,read " FMT_PADDR " address and %d size\n", addr, len);
#endif
  if (likely(in_pmem(addr)))
    return pmem_read(addr, len);
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data)
{
#ifdef CONFIG_MTRACE
  printf("This is a paddr_write,write " FMT_PADDR " address and %d size and " FMT_WORD " data\n", addr, len, data);
#endif
  if (likely(in_pmem(addr)))
  {
    pmem_write(addr, len, data);
    return;
  }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}

extern "C" svBitVecVal mem_read(const svLogicVecVal *raddr)
{
  return paddr_read(raddr->aval, 4);
}

extern "C" void mem_write(const svLogicVecVal *addr, const svLogicVecVal *data, char mask)
{
  switch (mask)
  {
  case 1:
    paddr_write(addr->aval, 1, data->aval);
    break;
  case 3:
    paddr_write(addr->aval, 2, data->aval);
    break;
  case 15:
    paddr_write(addr->aval, 4, data->aval);
    break;
  default:
    break;
  }
}