# ps2tech build — compiles the example ELF(s) in examples/ against the shared
# platform primitives in src/, using the ps2dev toolchain (see Dockerfile).
#
#   sources:  src/*.c (primitives) + examples/*.c (demos)
#   objects:  obj/*.o    (generated)
#   output:   bin/*.elf  (generated)
#
# Sources, intermediate objects, and the final ELF are kept in separate dirs so
# output never mixes in with the source.

EE_BIN_DIR      = bin
EE_OBJS_DIR     = obj
EE_SRC_DIR      = src
EE_EXAMPLES_DIR = examples

# The ps2menu example: a controller-driven list + settings demo on the libdebug
# console (the successor to the hello-world smoke test). It links the menu
# primitive (src/ps2_menu.c); the one pad bring-up call the menu makes
# (PS2Pad_Init) is provided locally by the example, because src/ps2_pad.c is
# still Doom-coupled (pulls in doomkeys.h / d_event.h) and doesn't build
# standalone yet. As primitives are degenericised, add their src/*.c to EE_OBJS
# and the ps2sdk libs they need to EE_LIBS, and grow examples/.
EE_BIN  = $(EE_BIN_DIR)/ps2menu_example.elf
EE_OBJS = $(EE_OBJS_DIR)/ps2menu_example.o \
          $(EE_OBJS_DIR)/ps2_menu.o

# libdebug (init_scr/scr_*) + libpad (controller). SifInitRpc/SifLoadModule and
# SleepThread come from the EE kernel libs linked by eeglobal automatically.
EE_LIBS = -ldebug -lpad

# Let examples/ #include the primitive headers from src/.
EE_INCS += -I$(EE_SRC_DIR)

all: $(EE_BIN)

clean:
	rm -rf $(EE_OBJS_DIR) $(EE_BIN_DIR)

# Compile src/*.c and examples/*.c into obj/. These dir-prefixed patterns win
# over eeglobal's generic `%.o: %.c` rule; DIR_GUARD creates obj/ (and bin/ for
# the link step) on demand.
$(EE_OBJS_DIR)/%.o: $(EE_SRC_DIR)/%.c
	$(DIR_GUARD)
	$(EE_C_COMPILE) -c $< -o $@

$(EE_OBJS_DIR)/%.o: $(EE_EXAMPLES_DIR)/%.c
	$(DIR_GUARD)
	$(EE_C_COMPILE) -c $< -o $@

# These ship inside the ps2dev image at $(PS2SDK)/samples.
include $(PS2SDK)/samples/Makefile.pref
include $(PS2SDK)/samples/Makefile.eeglobal
