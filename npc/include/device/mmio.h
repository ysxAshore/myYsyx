#ifndef __MEMORY_MMIO_H__
#define __MEMORY_MMIO_H__

#include <utils.h>

void init_map();
uint8_t *new_space(int size);
void mmio_write(paddr_t addr, int len, word_t data);
word_t mmio_read(paddr_t addr, int len);

#endif