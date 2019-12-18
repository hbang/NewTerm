ifeq ($(PLATFORM),mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:13.2:10.0
export ARCHS = arm64
LINK_CEPHEI := 1
endif

INSTALL_TARGET_PROCESSES = NewTerm

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = NewTerm

NewTerm_XCODEFLAGS = LINK_CEPHEI=-DLINK_CEPHEI CEPHEI_LDFLAGS="-framework Cephei -framework Preferences" SWIFT_OLD_RPATH=/usr/lib/libswift/stable
NewTerm_XCODE_SCHEME = NewTerm (iOS)
NewTerm_CODESIGN_FLAGS = -SiOS/entitlements.plist

include $(THEOS_MAKE_PATH)/xcodeproj.mk

ifeq ($(LINK_CEPHEI),1)
SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
endif
