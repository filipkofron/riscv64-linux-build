ROOT_DIR = $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
STAMP_DIR = $(ROOT_DIR)/stamps
PREFIX = $(ROOT_DIR)/prefix
SRC_DIR = $(ROOT_DIR)/src
BUILD_DIR = $(ROOT_DIR)/build
MUSL_SRC_PATH = $(SRC_DIR)/musl_cross_make
#DL_TO_STDOUT = wget -O - 
#UNPACK_TAR_XZ_STREAM_TO_SRC = tar xJ -C $(SRC_DIR)/
PARALLEL_JOBS = `nproc --all`
PARALLEL_OPTION = -j$(PARALLEL_JOBS)
MUSL_CROSS_MAKE_REPO = https://github.com/richfelker/musl-cross-make.git
LINUX_KERNEL_REPO = https://github.com/torvalds/linux
BUSYBOX_REPO = https://git.busybox.net/busybox
BUSYBOX_SRC_PATH = $(SRC_DIR)/busybox
BUSYBOX_BINARY = $(SRC_DIR)/busybox/busybox
LINUX_ARCH = riscv
LINUX_KERNEL_SRC_PATH = $(SRC_DIR)/linux
LINUX_KERNEL_IMAGE = $(LINUX_KERNEL_SRC_PATH)/arch/$(LINUX_ARCH)/boot/Image

TARGET = riscv64-linux-musl
export PATH := $(PATH):$(PREFIX)/bin:$(PREFIX)/$(TARGET)/bin

BUSYBOX_DL_TASK = $(STAMP_DIR)/busybox-dl
MUSL_BUILD_TASK = $(STAMP_DIR)/musl-cross-make
LINUX_KERNEL_DL_TASK = $(STAMP_DIR)/linux-kernel-dl
MUSL_DL_TASK = $(STAMP_DIR)/musl-dl
STAMPS_TASK = $(STAMP_DIR)/created

.PHONY: all clean test

all: $(MUSL_BUILD_TASK) $(LINUX_KERNEL_IMAGE) $(BUSYBOX_BINARY)

# TODO BUILD INITRAMDISKw

$(BUSYBOX_BINARY): $(BUSYBOX_DL_TASK)
	make -C $(BUSYBOX_SRC_PATH) CROSS_COMPILE=$(TARGET)- defconfig
	LDFLAGS="--static" make -C $(BUSYBOX_SRC_PATH) CROSS_COMPILE=$(TARGET)- $(PARALLEL_OPTION)
# TODO BUILD symlinks

$(BUSYBOX_DL_TASK):
	mkdir -p $(BUSYBOX_SRC_PATH)
	git clone -b 1_36_stable --depth 1 $(BUSYBOX_REPO) $(BUSYBOX_SRC_PATH)
	touch $(BUSYBOX_DL_TASK)

$(LINUX_KERNEL_IMAGE):	$(LINUX_KERNEL_DL_TASK)
	make -C $(LINUX_KERNEL_SRC_PATH) ARCH=$(LINUX_ARCH) CROSS_COMPILE=$(TARGET)- mrproper
#	make -C $(LINUX_KERNEL_SRC_PATH) ARCH=riscv CROSS_COMPILE=$(TARGET)- tinyconfig
	make -C $(LINUX_KERNEL_SRC_PATH) ARCH=$(LINUX_ARCH) CROSS_COMPILE=$(TARGET)- defconfig
	make -C $(LINUX_KERNEL_SRC_PATH) ARCH=$(LINUX_ARCH) CROSS_COMPILE=$(TARGET)- $(PARALLEL_OPTION)

$(LINUX_KERNEL_DL_TASK):
	mkdir -p $(LINUX_KERNEL_SRC_PATH)
	git clone --depth 1 $(LINUX_KERNEL_REPO) $(LINUX_KERNEL_SRC_PATH)
	touch $(LINUX_KERNEL_DL_TASK)

test: $(MUSL_BUILD_TASK)
	$(PREFIX)/bin/$(TARGET)-cc test.c -o test -static
	qemu-riscv64-static ./test
	qemu-riscv64-static $(BUSYBOX_BINARY) ls
	qemu-system-riscv64 -M virt -cpu rv64 -kernel $(LINUX_KERNEL_IMAGE) -append console=ttyS0 -serial stdio

$(MUSL_BUILD_TASK): $(MUSL_DL_TASK)
	mkdir -p $(PREFIX)
	make -C $(MUSL_SRC_PATH) TARGET=$(TARGET) OUTPUT=$(PREFIX) LINUX_VER=5.8.5 $(PARALLEL_OPTION) install
	touch $(MUSL_BUILD_TASK)

$(MUSL_DL_TASK): $(STAMPS_TASK)
	git clone --depth 1 $(MUSL_CROSS_MAKE_REPO) $(MUSL_SRC_PATH)
	touch $(MUSL_DL_TASK)

$(STAMPS_TASK):
	mkdir -p $(STAMP_DIR)
	touch $(STAMPS_TASK)

clean:
	rm -rf $(PREFIX) $(SRC_DIR) $(STAMP_DIR) test
