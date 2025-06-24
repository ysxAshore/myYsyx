CSRCS-y += csrc/npc_main.c
#如果有多个指令集的话 可以在isa内实现多个文件夹 每个文件夹表示一个指令集 根据GUEST_ISA决定编译哪个 如果导入头文件 那么INC_PATH加入GUEST_ISA文件夹下的include
DIRS-y += csrc/cpu csrc/monitor csrc/utils csrc/engine csrc/isa
DIRS-$(CONFIG_DEVICE) += csrc/device
DIRS-$(CONFIG_MODE_SYSTEM) += csrc/memory
DIRS-BLACKLIST-$(CONFIG_TARGET_AM) += csrc/monitor/sdb

SHARE = $(if $(CONFIG_TARGET_SHARE),1,0)
LIBS += $(if $(CONFIG_TARGET_NATIVE_ELF),-lreadline -ldl -pie -lgcc,)

ifdef mainargs
ASFLAGS += -DBIN_PATH=\"$(mainargs)\"
endif
CSRCS-$(CONFIG_TARGET_AM) += csrc/am-bin.S
.PHONY: csrc/am-bin.S
