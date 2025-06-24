#include <device/mmio.h>

#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_800x600, 800, 400))
#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_800x600, 600, 300))

static uint32_t screen_width()
{
    return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).width, SCREEN_W);
}

static uint32_t screen_height()
{
    return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).height, SCREEN_H);
}

static uint32_t screen_size()
{
    return screen_width() * screen_height() * sizeof(uint32_t);
}

void *vmem = NULL;

#ifdef CONFIG_VGA_SHOW_SCREEN
#ifndef CONFIG_TARGET_AM
#include <SDL2/SDL.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen()
{
    SDL_Window *window = NULL;
    char title[128];
    sprintf(title, "%s-NPC", str(__GUEST_ISA__));
    SDL_Init(SDL_INIT_VIDEO);
    SDL_CreateWindowAndRenderer(
        SCREEN_W * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
        SCREEN_H * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
        0, &window, &renderer);
    SDL_SetWindowTitle(window, title);
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
    SDL_RenderPresent(renderer);
}

static inline void update_screen()
{
    SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
}
#else
static void init_screen() {}

static inline void update_screen()
{
    io_write(AM_GPU_FBDRAW, 0, 0, vmem, screen_width(), screen_height(), true);
}
#endif
#endif

bool screen_sync = false;
void vga_update_screen()
{
    // TODO: call `update_screen()` when the sync register is non-zero,
    // then zero out the sync register
    if (screen_sync)
    {
        update_screen();
        screen_sync = 0;
    }
}

uint32_t getScreenSize()
{
    return (screen_width() << 16) | screen_height();
}

void write_vmem(paddr_t addr, uint32_t data, int len)
{
    switch (len)
    {
    case 1:
        *((uint8_t *)(vmem + addr)) = (uint8_t)data;
        break;
    case 2:
        *((uint16_t *)(vmem + addr)) = (uint16_t)data;
        break;
    case 4:
        *((uint32_t *)(vmem + addr)) = (uint32_t)data;
        break;
    default:
        break;
    }
}

void init_vga()
{
    vmem = new_space(screen_size());
    Assert(vmem != NULL, "new space failed");
    IFDEF(CONFIG_VGA_SHOW_SCREEN, init_screen());
    IFDEF(CONFIG_VGA_SHOW_SCREEN, memset(vmem, 0, screen_size()));
}
