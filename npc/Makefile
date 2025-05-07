VERILATOR = verilator
VERILATOR_FLAGS = --cc --exe --trace -Wall
SIM_TOP = ./csrc/main.cpp
TOP_MODULE = ./vsrc/example.v
SIMULATION ?= example
OBJ_DIR = obj_dir

default: compile

$(OBJ_DIR)/V$(SIMULATION): $(TOP_MODULE) $(SIM_TOP)
	$(VERILATOR) $(VERILATOR_FLAGS) $^
	cd $(OBJ_DIR) && make -f V$(SIMULATION).mk

compile: $(OBJ_DIR)/V$(SIMULATION) 

sim: compile
	$(call git_commit, "sim RTL") # git trace
	@./$(OBJ_DIR)/V$(SIMULATION)

.PHONY: clean
clean:
	-rm -rf $(OBJ_DIR) *.vcd

include ../Makefile
