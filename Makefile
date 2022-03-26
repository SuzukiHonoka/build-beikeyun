DTB_HEADLESS := dtbs/5.x-bsp/headless/rk3328-beikeyun-1296mhz.dtb
DTB_BOX := dtbs/4.4-bsp/box/rk3328-beikeyun.dtb

DL := input
WGET := wget -nv -P $(DL)
AXEL := axel -a -n4 -o $(DL)

OUTPUT := output
TARGETS := armbian libreelec alpine archlinux lakka

.PHONY: help build clean

help:
	@echo "Usage: make build_[system1]=y build_[system2]=y build"
	@echo "available system: $(TARGETS)"

build: $(TARGETS)

clean: $(TARGETS:%=%_clean)
	rm -f $(OUTPUT)/*.img $(OUTPUT)/*.xz

ARMBIAN_PKG_UBUNTU := Armbian_21.02.3_Rock64_focal_current_5.10.21.img.xz
ifneq ($(CI),)
ARMBIAN_URL_BASE := https://stpete-mirror.armbian.com/archive/rock64/archive
# ARMBIAN_URL_BASE := https://imola.armbian.com/dl/rock64/archive
# ARMBIAN_URL_BASE := https://archive.armbian.com/rock64/archive
# ARMBIAN_URL_BASE := https://armbian.tnahosting.net/dl/rock64/archive
else
ARMBIAN_URL_BASE := https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/rock64/archive
endif

ARMBIAN_PKG_%:
	@( if [ ! -f "$(DL)/$($(@))" ]; then \
		$(AXEL) $(ARMBIAN_URL_BASE)/$($(@)) ; \
		$(AXEL) $(ARMBIAN_URL_BASE)/$($(@)).sha ; \
	fi )

ARMBIAN_PKG_%_CLEAN:
	rm -f $(DL)/$($(@:_CLEAN=))

ifeq ($(build_armbian),y)
ARMBIAN_TARGETS := ARMBIAN_PKG_UBUNTU

armbian: $(ARMBIAN_TARGETS)
	( for pkg in $(foreach n,$^,$($(n))); do \
		sudo ./build-armbian.sh release $(DL)/$$pkg $(DTB_HEADLESS) ; \
	done )

armbian_clean: $(ARMBIAN_TARGETS:%=%_CLEAN)

else
armbian:
armbian_clean:
endif

ifeq ($(build_libreelec),y)
#LIBREELEC_URL := http://archive.libreelec.tv
LIBREELEC_URL := http://www.gtlib.gatech.edu/pub/LibreELEC

LIBREELEC_PKG := $(shell basename "`hxwls "$(LIBREELEC_URL)/?C=M;O=D" |grep 'rock64.img.gz$$' |head -1`")
libreelec: libreelec_dl libreelec_release

libreelec_clean:
	( if [ -n "$(LIBREELEC_PKG)" ]; then \
		rm -f $(DL)/$(LIBREELEC_PKG) ; \
	fi )

libreelec_dl:
	@( if [ -n "$(LIBREELEC_PKG)" ]; then \
		if [ ! -f $(DL)/$(LIBREELEC_PKG) ]; then \
			$(WGET) "$(LIBREELEC_URL)/$(LIBREELEC_PKG)" ; \
		fi \
	else \
		echo "fetch libreelec dl url fail" ; exit 1 ; \
	fi )

libreelec_release: libreelec_dl
	./build-libreelec.sh release $(DL)/$(LIBREELEC_PKG) $(DTB_BOX)

else
libreelec:
libreelec_clean:
endif

ifeq ($(build_lakka),y)
LAKKA_URL := http://le.builds.lakka.tv/Rockchip.ROCK64.arm
LAKKA_PKG := $(shell basename "`hxwls "$(LAKKA_URL)/?C=M&O=D" |grep 'img.gz$$' |head -1`")
LAKKA_IDB := loader/armbian-5.75/idbloader.bin
LAKKA_UBOOT_PATCH := loader/libreelec/u-boot.bin

lakka: lakka_dl lakka_release

lakka_clean:
	( if [ -n "$(LAKKA_PKG)" ]; then \
		rm -f $(DL)/$(LAKKA_PKG); \
	fi )

lakka_dl:
	( if [ -n "$(LAKKA_PKG)" ]; then \
		if [ ! -f $(DL)/$(LAKKA_PKG) ]; then \
			#$(WGET) "$(LAKKA_URL)/$(LAKKA_PKG)" ; \
			$(AXEL) -q "$(LAKKA_URL)/$(LAKKA_PKG)" ; \
		fi \
	else \
		echo "fetch lakka dl url fail" ; exit 1 ; \
	fi )

lakka_release: lakka_dl
	./build-lakka.sh release $(DL)/$(LAKKA_PKG) $(DTB_BOX) $(LAKKA_IDB) $(LAKKA_UBOOT_PATCH)

else
lakka:
lakka_clean:
endif

ifeq ($(build_alpine),y)
ALPINE_BRANCH := v3.10
ALPINE_VERSION := 3.10.0
ALPINE_PKG := alpine-minirootfs-$(ALPINE_VERSION)-aarch64.tar.gz

ifneq ($(CI),)
ALPINE_URL_BASE := http://dl-cdn.alpinelinux.org/alpine/$(ALPINE_BRANCH)/releases/aarch64
else
ALPINE_URL_BASE := https://mirrors.tuna.tsinghua.edu.cn/alpine/$(ALPINE_BRANCH)/releases/aarch64
endif

alpine: alpine_dl alpine_release

alpine_dl: $(DL)/$(ALPINE_PKG)

$(DL)/$(ALPINE_PKG):
	$(WGET) $(ALPINE_URL_BASE)/$(ALPINE_PKG)

alpine_release: ARMBIAN_PKG_UBUNTU alpine_dl
	sudo ./build-alpine.sh release $(DL)/$(ARMBIAN_PKG_UBUNTU) $(DTB_HEADLESS) $(DL)/$(ALPINE_PKG)

alpine_clean: ARMBIAN_PKG_UBUNTU_CLEAN
	rm -f $(DL)/$(ALPINE_PKG)

else
alpine:
alpine_clean:
endif

ifeq ($(build_archlinux),y)
ARCHLINUX_PKG := ArchLinuxARM-aarch64-latest.tar.gz

ifneq ($(CI),)
ARCHLINUX_URL_BASE := http://os.archlinuxarm.org/os
else
ARCHLINUX_URL_BASE := https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/os
endif

archlinux: archlinux_dl archlinux_release

archlinux_dl: $(DL)/$(ARCHLINUX_PKG)

$(DL)/$(ARCHLINUX_PKG):
	$(WGET) $(ARCHLINUX_URL_BASE)/$(ARCHLINUX_PKG)

archlinux_release: ARMBIAN_PKG_UBUNTU archlinux_dl
	sudo ./build-archlinux.sh release $(DL)/$(ARMBIAN_PKG_UBUNTU) $(DTB_HEADLESS) $(DL)/$(ARCHLINUX_PKG)

archlinux_clean: ARMBIAN_PKG_UBUNTU_CLEAN
	rm -f $(DL)/$(ARCHLINUX_PKG)

else
archlinux:
archlinux_clean:
endif
