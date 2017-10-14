# source dirs
GIT_DIR = ~/git
LINUX_DIR = $(GIT_DIR)/linux
WALB_DRIVER_DIR = $(GIT_DIR)/walb-driver
WALB_TOOLS_DIR = $(GIT_DIR)/walb-tools

# destination dirs
DISK_IMAGE = disk_walb_root.img
ROOTFS_DIR = root

# other
LINUX_VER = $(shell sed -n 1p $(LINUX_DIR)/Makefile | cut -d' ' -f3).$(shell sed -n 2p $(LINUX_DIR)/Makefile | cut -d' ' -f3).$(shell sed -n 3p $(LINUX_DIR)/Makefile | cut -d' ' -f3)$(shell sed -n 4p $(LINUX_DIR)/Makefile | cut -d' ' -f3)+

PHONY = all
all: prep make set run

########## prep ##########
PHONY += prep
# prep: prep_linux prep_walb_driver prep_walb_tools prep_busybox prep_disk
prep: prep_walb_driver prep_walb_tools prep_busybox prep_disk

PHONY += prep_linux
prep_linux:
	git -C $(LINUX_DIR) checkout master
	git -C $(LINUX_DIR) pull

PHONY += prep_walb_driver
prep_walb_driver:
	git -C $(WALB_DRIVER_DIR) checkout wip/fix-compile-error-4.14

PHONY += prep_walb_tools
prep_walb_tools:
	git -C $(WALB_TOOLS_DIR) checkout master
	git -C $(WALB_TOOLS_DIR) pull

PHONY += prep_busybox
prep_busybox:
	if [ ! -d busybox-static ]; then \
		apt-get download busybox-static; \
		mkdir busybox-static; \
		dpkg-deb -x busybox-static*.deb busybox-static; \
	fi

PHONY += prep_disk
prep_disk:
	if /sbin/losetup | grep -q $(DISK_IMAGE); then \
		sudo losetup -d $(shell sudo losetup | grep $(DISK_IMAGE) | cut -d' ' -f1); \
	fi

	dd if=/dev/zero of=$(DISK_IMAGE) bs=1M seek=1024 count=1
	sudo losetup $(shell sudo losetup -f) $(DISK_IMAGE)

	@echo '########## Please confirm format operation ##########'
	/sbin/losetup
	@echo command: sudo mkfs.ext4 $$(sudo losetup | grep $(DISK_IMAGE) | cut -d' ' -f1)
	@echo Press Enter to continue...
	@read _tmp
	sudo mkfs.ext4 $$(sudo losetup | grep $(DISK_IMAGE) | cut -d' ' -f1)

########## make ##########
PHONY += make
make: make_linux make_walb_driver make_walb_tools

PHONY += make_linux
make_linux:
	make -C $(LINUX_DIR) -j $(shell nproc)

PHONY += make_walb_driver
make_walb_driver:
	make -C $(WALB_DRIVER_DIR)/module -j $(nproc) KERNELDIR=$(LINUX_DIR)

PHONY += make_walb_tools
make_walb_tools:
	make -C $(WALB_TOOLS_DIR) -j $(shell nproc) ENABLE_EXEC_PROTOCOL=1 STATIC=1

########## set ##########
PHONY += set
set:
	mkdir -p $(ROOTFS_DIR)
	sudo mount $$(sudo losetup | grep $(DISK_IMAGE) | cut -d' ' -f1) $(ROOTFS_DIR)

	sudo mkdir -p $(ROOTFS_DIR)/sbin
	sudo mkdir -p $(ROOTFS_DIR)/bin
	sudo mkdir -p $(ROOTFS_DIR)/dev
	sudo mkdir -p $(ROOTFS_DIR)/proc
	sudo mkdir -p $(ROOTFS_DIR)/etc/init.d

	sudo cp busybox-static/bin/busybox $(ROOTFS_DIR)/bin/
	sudo ln -fs /bin/busybox $(ROOTFS_DIR)/sbin/init
	sudo ln -fs busybox $(ROOTFS_DIR)/bin/sh
	sudo ln -fs busybox $(ROOTFS_DIR)/bin/mount

	echo 'mount -t proc proc /proc' > rcS
	echo 'mount -o remount /dev/root /' >> rcS
	echo 'depmod $$(uname -r)' >> rcS
	echo 'sh' >> rcS
	sudo cp rcS $(ROOTFS_DIR)/etc/init.d/
	sudo chmod +x $(ROOTFS_DIR)/etc/init.d/rcS

	sudo mkdir -p $(ROOTFS_DIR)/lib/modules/$(LINUX_VER)/kernel/drivers/block/walb
	sudo cp $(WALB_DRIVER_DIR)/module/walb-mod.ko $(ROOTFS_DIR)/lib/modules/$(LINUX_VER)/kernel/drivers/block/walb/

	sudo umount $(ROOTFS_DIR)

########## run ##########
PHONY += run
run:
	qemu-system-x86_64 -kernel $(LINUX_DIR)/arch/x86/boot/bzImage -append 'console=ttyS0 root=/dev/sda' -hda $(DISK_IMAGE) -nographic
