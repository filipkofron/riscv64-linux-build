PREFIX=prefix
GIT_CMD=git
SRC_DIR=src
BUILD_DIR=build
MUSL_SRC_PATH=$(SRC_DIR)/musl_cross_make

MUSL_CROSS_MAKE_REPO=https://github.com/richfelker/musl-cross-make.git

.PHONY: clean

musl-cross-make: musl-dl
    $(MAKE) -C $(MUSL_SRC_PATH) TARGET=riscv64-linux-musl OUTPUT=/ssd-pool/temp/riscv-linux/prefix

musl-dl:
	$(DL_CMD) pull --depth 1 $(MUSL_CROSS_MAKE_REPO) $(MUSL_SRC_PATH)

clean:
	rm -rf $(PREFIX) $(SRC_DIR)
