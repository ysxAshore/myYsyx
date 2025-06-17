#include <cpu/cpu.h>
#include <isa.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <memory/paddr.h>

#include "sdb.h"

static int is_batch_mode = false;

extern NPCState npc_state;

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char *rl_gets()
{
    static char *line_read = NULL;

    if (line_read)
    {
        free(line_read);
        line_read = NULL;
    }

    line_read = readline("(npc) ");

    if (line_read && *line_read)
    {
        add_history(line_read);
    }

    return line_read;
}

static int cmd_c(char *args)
{
    if (args == NULL)
        cpu_exec(-1);
    else
        printf("Unkown command 'c %s',c must have zero argument\n", args);

    return 0;
}

static int cmd_si(char *args)
{
    uint64_t n = 1;
    if (args == NULL)
        cpu_exec(1);
    else
    {
        if (strspn(args, "0123456789") == strlen(args))
        { // 判断args是否完全是数字
            sscanf(args, "%ld", &n);
            cpu_exec(n);
        }
        else
            printf("Unkown command 'si %s',si could have a num argument\n", args);
    }
    return 0;
}

static int cmd_q(char *args)
{
    if (args == NULL)
    {
        npc_state.state = NPC_QUIT;
        cpu_exec(0);
    }
    else
        printf("Unkown command 'q %s',q must have zero argument\n", args);
    return -1;
}

static int cmd_info(char *args)
{
    char *arg = strtok(NULL, " ");
    if (arg == NULL)
    {
        printf("Unkown command,info must have one argument\n");
    }
    else
    {
        char *tmp = strtok(NULL, " ");
        if (tmp == NULL)
        {
            if (strcmp(arg, "r") == 0)
                isa_reg_display();
            if (strcmp(arg, "w") == 0)
                displayWatchPoint();
        }
        else
        {
            printf("Unkown command 'info %s',info must have one argument\n", args);
        }
    }
    return 0;
}

static int cmd_x(char *args)
{
    if (args == NULL)
        printf("Unknown command 'x',x must have two arguments\n");
    else
    {
        char *arg = strtok(NULL, " ");
        if (strspn(arg, "0123456789") != strlen(arg))
            printf("Unknown command 'x %s',the first argument must be a number\n", args);
        else
        {
            uint64_t N;
            sscanf(arg, "%ld", &N);
            arg = strtok(NULL, " ");
            char *tmp = strtok(NULL, " ");
            if (strspn(arg, "0123456789abcdefx") == strlen(arg) && tmp == NULL)
            {
                paddr_t address;
                sscanf(arg, "%x", &address);
                int i;
                for (i = 0; i < N / 4; ++i)
                {
                    printf("%#x:%#x\n", address, paddr_read(address, 4));
                    address += 4;
                }
                if (i * 4 < N)
                    printf("%#x:%#x\n", address, paddr_read(address, N - i * 4));
            }
            else
                printf("Unknown command 'x %s',the second argument must be a hex number\n", args);
        }
    }
    return 0;
}

static int cmd_expr(char *args)
{
    if (args == NULL)
    {
        printf("Unknown command 'expr',test must have no argument\n");
    }
    else
    {
        bool success = true;
        word_t val = expr(args, &success);
        if (success)
            printf("%0x\n", val);
        else
            printf("The %s expression evals failed\n", args);
    }
    return 0;
}

static int cmd_d(char *args)
{
    if (args == NULL)
        printf("the command d needs a parameter reprented the WatchPoint Number\n");
    else
    {
        char *number = strtok(NULL, " ");
        char *temp = strtok(NULL, " ");
        if (temp == NULL)
        {
            int N;
            int tag = sscanf(number, "%d", &N);
            if (tag == 0 || tag == EOF)
                printf("the %s must be a integer\n", args);
            else
                deleteWatchPoint(N);
        }
        else
            printf("the %s must be only a parameter\n", args);
    }
    return 0;
}

static int cmd_w(char *args)
{
    if (args == NULL)
        printf("the command w needs a parameter reprented the expression watched\n");
    else
    {
        createWatchPoint(args);
    }
    return 0;
}

static int cmd_help(char *args);

static struct
{
    const char *name;
    const char *description;
    int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    {"si", "Excute cpu n steps", cmd_si},
    {"info", "Print the information which prefered by args,supported r and w", cmd_info},
    {"x", "print the N elements in memory that begin with address", cmd_x},
    {"expr", "get the expr value", cmd_expr},
    {"d", "delete the Number N watchpoint", cmd_d},
    {"w", "add a watchpoint,the argument refers the expression", cmd_w},
    /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args)
{
    /* extract the first argument */
    char *arg = strtok(NULL, " ");
    int i;

    if (arg == NULL)
    {
        /* no argument given */
        for (i = 0; i < NR_CMD; i++)
        {
            printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        }
    }
    else
    {
        char *tmp = strtok(NULL, " ");
        for (i = 0; i < NR_CMD; i++)
        {
            if (strcmp(arg, cmd_table[i].name) == 0 && tmp == NULL)
            {
                printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
                return 0;
            }
        }
        printf("Unknown command '%s'\n", arg);
    }
    return 0;
}

void sdb_set_batch_mode()
{
    is_batch_mode = true;
}

void sdb_mainloop()
{
    if (is_batch_mode)
    {
        cmd_c(NULL);
        return;
    }

    for (char *str; (str = rl_gets()) != NULL;)
    {
        char *str_end = str + strlen(str);

        /* extract the first token as the command */
        char *cmd = strtok(str, " ");
        if (cmd == NULL)
        {
            continue;
        }

        /* treat the remaining string as the arguments,
         * which may need further parsing
         */
        char *args = cmd + strlen(cmd) + 1;
        if (args >= str_end)
        {
            args = NULL;
        }

#ifdef CONFIG_DEVICE
        extern void sdl_clear_event_queue();
        sdl_clear_event_queue();
#endif

        int i;
        for (i = 0; i < NR_CMD; i++)
        {
            if (strcmp(cmd, cmd_table[i].name) == 0)
            {
                if (cmd_table[i].handler(args) < 0)
                {
                    return;
                }
                break;
            }
        }

        if (i == NR_CMD)
        {
            printf("Unknown command '%s'\n", cmd);
        }
    }
}

void init_sdb()
{
    /* Compile the regular expressions. */
    init_regex();

    /* Initialize the watchpoint pool. */
    init_wp_pool();
}
