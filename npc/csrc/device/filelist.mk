DIRS-y += csrc/device/
SRCS-$(CONFIG_DEVICE) += csrc/device/device.c 
SRCS-$(CONFIG_HAS_KEYBOARD) += csrc/device/keyboard.c
SRCS-$(CONFIG_HAS_VGA) += csrc/device/vga.c

ifdef CONFIG_DEVICE
ifndef CONFIG_TARGET_AM
LIBS += $(shell sdl2-config --libs)
endif
endif
