#include <getopt.h>
#include <memory/paddr.h>

static char *img_file = NULL;
static char *log_file = NULL;
static char *elf_file = NULL;
static char *ref_so_file = NULL;
static int port = 1234;
static uint32_t *img = NULL;

extern uint8_t fmem[0x10000000];

void init_log(const char *log_file);
void sdb_set_batch_mode();
void init_cpu();
void init_rand();
void init_sdb();
void init_disasm();
void init_symTable(const char *elf_file);
#ifdef CONFIG_DEVICE
void init_device();
#endif
#ifdef CONFIG_DIFFTEST
void init_difftest(char *ref_so_file, long img_size, int port);
#endif

static void welcome()
{
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
                          "to record the trace. This may lead to a large log file. "
                          "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NPC!\n", ANSI_FMT("RISCV32E", ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
}

static long load_img()
{
  if (img_file == NULL)
  {
    Log("No image is given. Use the default build-in image.");
    img = (uint32_t *)realloc(img, 12);
    img[0] = 0x00a00093; // addi x1,x0,10
    img[1] = 0x0ff00113; // addi x2,x0,255
    img[2] = 0x00100073; // ebreak
    // memcpy(guest_to_host(RESET_VECTOR), img, 12);
    memcpy(fmem, img, 12);
    return 12; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  // int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  int ret = fread(fmem, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static void test_fmem()
{
  /* 测试flash读取内容 SPI and FAST_FLASH */
  //  for (size_t i = 0; i < 256; ++i)
  //    fmem[i] = i;

  /* 将char-test程序复制到flash中 然后读取并拷贝到sram中的某地址 跳转并执行*/
  FILE *fp = fopen("/home/sxyang/Projects/ysyx/ysyxSoC/uart_test/char-test.bin", "rb");
  Assert(fp, "Can not open '%s'", "char-test.bin");

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  *((uint32_t *)fmem) = size;

  Log("The image is %s, size = %ld", "char-test.bin", size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(fmem + 4, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
}

static int parse_args(int argc, char *argv[])
{
  const struct option table[] = {
      {"batch", no_argument, NULL, 'b'},
      {"log", required_argument, NULL, 'l'},
      {"elf", required_argument, NULL, 'e'},
      {"diff", required_argument, NULL, 'd'},
      {"port", required_argument, NULL, 'p'},
      {0, 0, NULL, 0},
  };
  int o;
  // 保留一个-将非选项参数作为长选项处理 返回1
  while ((o = getopt_long(argc, argv, "-bl:e:d:p:", table, NULL)) != -1)
  {
    switch (o)
    {
    case 'b':
      sdb_set_batch_mode();
      break;
    case 'l':
      log_file = optarg;
      break;
    case 'e':
      elf_file = optarg;
      break;
    case 'd':
      ref_so_file = optarg;
      break;
    case 'p':
      sscanf(optarg, "%d", &port);
      break;
    case 1:
      img_file = optarg;
      return 0;
    default:
      printf("Usage: %s [OPTION...] IMAGE \n\n", argv[0]);
      printf("\t-l,--log=FILE           output log to FILE\n");
      printf("\t-e,--elf=FILE           the program elf FILE\n");
      printf("\n");
      exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[])
{
  parse_args(argc, argv);

  init_log(log_file);

  long img_size = load_img();

  init_rand();

  init_cpu();

  init_sdb();

  IFDEF(CONFIG_ITRACE, init_disasm());

  IFDEF(CONFIG_FTRACE, init_symTable(elf_file));

  IFDEF(CONFIG_DIFFTEST, init_difftest(ref_so_file, img_size, port));

  IFDEF(CONFIG_DEVICE, init_device());

  // test_fmem();

  welcome();
}
