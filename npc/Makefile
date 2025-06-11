# 顶层模块名称
TOPNAME = top
INC_PATH ?= 
# verilator路径
VERILATOR = verilator
# verilator编译选项
#	-MMD: 创建.d依赖文件
#	-O3: 为verilator自身生成的代码启用慢速优化(与-CFLAGS -O3不同,后者影响 C 编译器的优化.-O3可能会以编译时间为代价提高仿真性能).目前这会设置--inline-mult -1
#	--x-assign: 赋值所有未初始化的X值 "–x-assign fast"会将所有X转换为最有利于性能的值
#	--x-initial: 初始化未以其他方式初始化的变量的X值 "–x-initial fast"会将所有X初始化为最有利于性能的值
#	--noassert: 关闭所有的assertions
VERILATOR_CFLAGS += -MMD --build -cc --exe --trace\
				-O3 --x-assign fast --x-initial fast --noassert
# make输出目录
BUILD_DIR = ./build
# verilator编译得到的objdir
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

# 默认目标:使用verilator构建可执行文件
default: $(BIN)

# mkdir ./build
$(shell mkdir -p $(BUILD_DIR)) 

# project source
# 在vsrc目录下找到所有的.v文件
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v") 
# 在csrc目录下找到所有的cpp文件,此外还要包括make生成的auto_bind.cpp
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp") 

# rules for verilator
# INC_PATHS存储包含路径(include paths)的目录列表
# -DTOP_NAME 定义宏TOP_NAME 值为"V$(TOPNAME)"
INC_PATH += ./csrc/include
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += -g $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

# 编译得到可执行文件
#     --top-module: 指定顶层输入模块名称 
#     -CFLAGS: 将指定的C编译器参数添加到生成的Makefile中,对于多个标志可以使用多个-CFLAGS选项.当在生成的Makefile上运行make时,这些参数会传递给C编译器
#     -LDFLAGS: 将指定的C链接器参数添加到生成的Makefile中,对于多个标志可以使用多个-LDFLAGS参数.当在生成的Makefile上运行make时，这些参数将在被链接的主文件之后传递给C链接器
#     -Mdir: 输出对象目录名称
#     -o: 最终的可执行文件名称
$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN))

all: default

run: $(BIN)
	echo $^ $(ARGS) $(IMG)
	@$^ $(ARGS) $(IMG)

clean:
	rm -rf $(BUILD_DIR) $(BUILD_DIR)/../wave.vcd

.PHONY: default all clean run
