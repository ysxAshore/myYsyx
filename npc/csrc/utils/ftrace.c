#include <utils.h>
#include <Vtop__Dpi.h> //DPI-C函数的头文件 在该.h中声明了DPI-C函数

typedef struct funcSymNode
{
    char *name;
    Elf_Addr addr;
    word_t size;
    struct funcSymNode *next;
} funcSymList;

typedef struct ftraceNode
{
    char *orginName;
    char *jFuncName;
    int callType; // 0 is call,1 is return;
    vaddr_t from_pc;
    vaddr_t to_pc;
    struct ftraceNode *next;
} ftraceList;

typedef struct CallStackNode
{
    const char *func;
    struct CallStackNode *next;
} CallStack;

char *strtab = NULL;
funcSymList *sym_list = NULL;
ftraceList *ftrace_list = NULL;
ftraceList *tail = NULL;

void init_symTable(const char *elf_file)
{

    // 初始化ftrace
    ftrace_list = (ftraceList *)realloc(ftrace_list, sizeof(ftraceList));
    ftrace_list->next = NULL;
    tail = ftrace_list;

    // 初始化sym_list
    sym_list = (funcSymList *)realloc(sym_list, sizeof(funcSymList));
    sym_list->next = NULL;

    Assert(elf_file, "The elf_file is null");
    FILE *fp = fopen(elf_file, "r");
    Assert(fp, "Can not open '%s'", elf_file);

    // 读取ELF文件头
    Elf_Ehdr ehdr;
    Assert(fread(&ehdr, sizeof(Elf_Ehdr), 1, fp) == 1, "read the elf header failed");

    // 验证魔数
    bool sign = ehdr.e_ident[0] == 0x7f &&
                ehdr.e_ident[1] == 'E' &&
                ehdr.e_ident[2] == 'L' &&
                ehdr.e_ident[3] == 'F';
    Assert(sign, "The '%s' file not is a elf file", elf_file);

    // 读取Section Header
    fseek(fp, ehdr.e_shoff, SEEK_SET);
    Elf_Shdr shdr;

    for (int i = 0; i < ehdr.e_shnum; ++i)
    {
        Assert(fread(&shdr, sizeof(Elf_Shdr), 1, fp) == 1, "read the elf section header failed");

        //.strtab
        if (shdr.sh_type == SHT_STRTAB)
        {
            strtab = (char *)realloc(strtab, shdr.sh_size);
            fseek(fp, shdr.sh_offset, SEEK_SET);
            Assert(fread(strtab, shdr.sh_size, 1, fp) == 1, "read the .strtab failed");
            printf("%s\n", strtab);
            break;
        }
    }
    fseek(fp, ehdr.e_shoff, SEEK_SET);
    for (int i = 0; i < ehdr.e_shnum; ++i)
    {
        Assert(fread(&shdr, sizeof(Elf_Shdr), 1, fp) == 1, "read the elf section header failed");

        //.symtab
        if (shdr.sh_type == SHT_SYMTAB)
        {
            fseek(fp, shdr.sh_offset, SEEK_SET);
            Elf_Sym sym;
            int num = shdr.sh_size / shdr.sh_entsize;
            for (int i = 0; i < num; ++i)
            {
                Assert(fread(&sym, shdr.sh_entsize, 1, fp) == 1, "read the symbol table entry failed");
                if (ELF64_ST_TYPE(sym.st_info) == STT_FUNC)
                {
                    struct funcSymNode *temp = (struct funcSymNode *)malloc(sizeof(struct funcSymNode));
                    temp->addr = sym.st_value;
                    temp->size = sym.st_size;
                    temp->name = strtab + sym.st_name;
                    temp->next = sym_list->next;
                    sym_list->next = temp;
                }
            }
            break;
        }
    }
    fclose(fp);
}

extern "C" void insertFtraceNode(int callType, const svLogicVecVal *from_pc_t, const svLogicVecVal *to_pc_t)
{
    vaddr_t from_pc = from_pc_t->aval;
    vaddr_t to_pc = to_pc_t->aval;

    struct ftraceNode *node = (struct ftraceNode *)malloc(sizeof(struct ftraceNode));
    funcSymList *p = sym_list;

    node->callType = callType;
    node->from_pc = from_pc;
    node->to_pc = to_pc;

    while (p->next)
    {
        p = p->next;
        if (to_pc >= p->addr && to_pc < p->addr + p->size)
            node->jFuncName = p->name;
        if (from_pc >= p->addr && from_pc < p->addr + p->size)
            node->orginName = p->name;
    }
    node->next = NULL;
    tail->next = node;
    tail = node;
}

#define ALIGN_COL 52 // 设定统一对齐的列数
void printFtrace()
{
    ftraceList *p = ftrace_list;
    int num = 0;
    char buf[ALIGN_COL];

    CallStack *stack = (CallStack *)malloc(sizeof(CallStack));
    stack->next = NULL;
    CallStack *node, *q;

    while (p->next)
    {
        p = p->next;
        // 打印前半部分到缓冲区，便于测长度
        int len = snprintf(buf, sizeof(buf), "[%s@" FMT_WORD "]", p->orginName, p->from_pc);

        // 输出前半部分
        printf("%s", buf);

        // 计算补齐空格
        int pad = ALIGN_COL - len;
        if (pad < 1)
            pad = 1; // 至少一个空格
        for (int i = 0; i < pad; ++i)
            putchar(' '); // 补空格直到对齐
        printf(":");
        for (int i = 0; i < num; ++i)
            printf(" ");
        if (p->callType)
        {
            printf("ret [%s]", p->jFuncName);
            node = stack->next;
            if (node->func == p->orginName)
            {
                if (node->next->func == p->jFuncName)
                {
                    printf("\n");
                    stack->next = node->next;
                    free(node);
                }
                else
                {
                    printf("(tail call---");
                    node = node->next;
                    while (node)
                    {
                        if (node->func == p->jFuncName)
                        {
                            printf("ret %s)\n", p->jFuncName);
                            break;
                        }
                        else
                            printf("ret %s,", node->func);
                        q = node;
                        node = node->next;
                        free(q);
                    }
                    stack->next = node;
                }
            }
            else
            {
                printf("(tail call---");
                printf("call %s,", p->orginName);
                while (node)
                {
                    if (node->func == p->jFuncName)
                    {
                        printf("ret %s)\n", p->jFuncName);
                        break;
                    }
                    else
                        printf("ret %s,", node->func);
                    q = node;
                    node = node->next;
                    free(q);
                }
                stack->next = node;
            }
            num -= 2;
        }
        else
        { // call
            printf("call [%s@" FMT_WORD "]\n", p->jFuncName, p->to_pc);
            num += 2;
            if (stack->next)
            {
                node = stack->next;
                q = (CallStack *)malloc(sizeof(CallStack));
                // 当上一次的call地址函数和当前调用call的函数并不相符时，需要插入一个call orginName
                if (node->func != p->orginName)
                {
                    q->func = p->orginName;
                    q->next = stack->next;
                    stack->next = q;
                }
            }
            q = (CallStack *)malloc(sizeof(CallStack));
            q->func = p->jFuncName;
            q->next = stack->next;
            stack->next = q;
        }
    }
}
