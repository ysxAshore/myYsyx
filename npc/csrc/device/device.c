#include <utils.h>

#ifndef CONFIG_TARGET_AM
#include <SDL2/SDL.h>
#endif

void init_map();
void init_keyboard();
void init_vga();

void send_key(uint8_t, bool);

extern NPCState npc_state;

void device_update()
{
    static uint64_t last = 0;
    uint64_t now = get_time();
    if (now - last < 1000000 / TIMER_HZ)
    {
        return;
    }
    last = now;

    //    IFDEF(CONFIG_HAS_VGA, vga_update_screen());

#ifndef CONFIG_TARGET_AM
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        case SDL_QUIT:
            npc_state.state = NPC_QUIT;
            break;
#ifdef CONFIG_HAS_KEYBOARD
        // If a key was pressed
        case SDL_KEYDOWN:
        case SDL_KEYUP:
        {
            uint8_t k = event.key.keysym.scancode;
            bool is_keydown = (event.key.type == SDL_KEYDOWN);
            send_key(k, is_keydown);
            break;
        }
#endif
        default:
            break;
        }
    }
#endif
}

void sdl_clear_event_queue()
{
#ifndef CONFIG_TARGET_AM
    SDL_Event event;
    while (SDL_PollEvent(&event))
        ;
#endif
}

void init_device()
{
    init_map();
    IFDEF(CONFIG_HAS_KEYBOARD, init_keyboard());
    // IFDEF(CONFIG_HAS_VGA, init_vga());
}