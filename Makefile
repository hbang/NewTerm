ifeq ($(PLATFORM),mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:13.7:13.0
export ARCHS = arm64
endif

INSTALL_TARGET_PROCESSES = NewTerm

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = NewTerm

NewTerm_XCODEFLAGS = SWIFT_OLD_RPATH=/usr/lib/libswift/stable
NewTerm_XCODE_SCHEME = NewTerm (iOS)
# Prevent bitcode from being embedded in archive builds.
NewTerm_XCODEFLAGS = ENABLE_BITCODE=NO
NewTerm_CODESIGN_FLAGS = -SApp/entitlements.plist

include $(THEOS_MAKE_PATH)/xcodeproj.mk

all stage package install::
# TODO: This should be possible natively in Theos!
ifeq ($(or $(INSTALL_FONTS),$(FINALPACKAGE)),1)
	+$(MAKE) -C Fonts $@ THEOS_PROJECT_DIR=$(THEOS_PROJECT_DIR)/Fonts
endif
