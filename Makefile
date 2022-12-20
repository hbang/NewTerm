export TARGET = iphone:latest:14.0
export ARCHS = arm64

ifeq ($(ROOTLESS),1)
	export DEB_ARCH = iphoneos-arm64
	export INSTALL_PREFIX = /var/jb
else
	export DEB_ARCH = iphoneos-arm
endif

INSTALL_TARGET_PROCESSES = NewTerm

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = NewTerm

NewTerm_XCODE_SCHEME = NewTerm (iOS)
NewTerm_XCODEFLAGS = INSTALL_PREFIX=$(INSTALL_PREFIX)
NewTerm_CODESIGN_FLAGS = -SApp/entitlements.plist
NewTerm_INSTALL_PATH = $(INSTALL_PREFIX)/Applications

include $(THEOS_MAKE_PATH)/xcodeproj.mk

before-package::
	perl -i -pe s/iphoneos-arm/$(DEB_ARCH)/ $(THEOS_STAGING_DIR)/DEBIAN/control

after-stage::
	@$(TARGET_CODESIGN) $(NewTerm_CODESIGN_FLAGS) $(THEOS_STAGING_DIR)$(INSTALL_PREFIX)/Applications/NewTerm.app/NewTermLoginHelper
