#include <device/mmio.h>
#include <memory/paddr.h>

uint32_t i8042_data_io_handler(uint32_t offset, int len, bool is_write);
uint32_t getScreenSize();
void write_vmem(paddr_t addr, uint32_t data, int len);
void vga_update_screen();
extern bool screen_sync;

word_t mmio_read(paddr_t addr, int len)
{
    static uint64_t us; // 必须是静态的，不然每次进入都会初始化
    switch (addr)
    {
    case CONFIG_RTC_MMIO + 0x4:
        us = get_time_internal();
        return us >> 32;
    case CONFIG_RTC_MMIO:
        return (uint32_t)us;
    case CONFIG_I8042_DATA_MMIO:
        Assert(len == 4, "Reading the keyboard code must read 4 bytes"); // inl
        return i8042_data_io_handler(0, 4, false);
    case CONFIG_VGA_CTL_MMIO:
        return getScreenSize();
    case CONFIG_VGA_CTL_MMIO + 0x4:
        return screen_sync;
    default:
        break;
    }
    Assert(false, "Not implemented the " FMT_PADDR "read", addr);
}

void mmio_write(paddr_t addr, int len, word_t data)
{
    switch (addr)
    {
    case CONFIG_SERIAL_MMIO:
        putchar((char)data);
        fflush(stdout); // 让输出立即刷新 不然会很阻塞
        return;
    case CONFIG_VGA_CTL_MMIO + 0x4:
        screen_sync = data;
        vga_update_screen();
        return;
    default:
        break;
    }
    uint32_t size = getScreenSize();
    uint32_t screen_width = size >> 16;
    uint32_t screen_height = size & 0xffff;
    if (addr >= CONFIG_FB_ADDR && addr < CONFIG_FB_ADDR + screen_width * screen_height * sizeof(uint32_t))
    {
        write_vmem(addr - CONFIG_FB_ADDR, data, len);
        return;
    }
    Assert(false, "Not implemented the " FMT_PADDR "write", addr);
}

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;
#define IO_SPACE_MAX (32 * 1024 * 1024)
uint8_t *new_space(int size)
{
    uint8_t *p = p_space;
    // page aligned;
    size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
    p_space += size;
    Assert(p_space - io_space < IO_SPACE_MAX, "p_space - io_space >= IO_SPACE_MAX");
    return p;
}

void init_map()
{
    io_space = (uint8_t *)malloc(IO_SPACE_MAX);
    assert(io_space);
    p_space = io_space;
}