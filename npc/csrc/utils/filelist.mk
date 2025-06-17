ifeq ($(CONFIG_ITRACE)$(CONFIG_IQUEUE),)
CSRCS-BLACKLIST-y += csrc/utils/disasm.c
else
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
INC_PATH += $(NEMU_HOME)/tools/capstone/repo/include
csrc/utils/disasm.c: $(LIBCAPSTONE)
	$(CC) 
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)/tools/capstone
endif