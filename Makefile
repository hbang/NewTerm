export TARGET = iphone:clang:latest:7.0

PROJECT_DIR := $(PWD)/NewTerm
INCLUDES := -I$(PROJECT_DIR) -I$(PROJECT_DIR)/External -I$(PROJECT_DIR)/External/ncurses

# export TARGET_CODESIGN = jtool

export ADDITIONAL_CFLAGS = -fobjc-arc $(INCLUDES)
export ADDITIONAL_SWIFTFLAGS = $(INCLUDES)
export ADDITIONAL_LDFLAGS = -rpath @executable_path/Frameworks

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm

NewTerm_FILES = $(wildcard NewTerm/*/*.[xm]) $(wildcard NewTerm/*.swift) $(wildcard NewTerm/*/*.swift) $(wildcard NewTerm/*/*/*.swift) $(wildcard NewTerm/*/*/*.m)
NewTerm_SWIFT_BRIDGING_HEADER = $(PROJECT_DIR)/SupportingFiles/BridgingHeader.h
NewTerm_FRAMEWORKS = UIKit CoreGraphics QuartzCore
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei
NewTerm_LIBRARIES = curses
NewTerm_CODESIGN_FLAGS = -S$(PROJECT_DIR)/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
ifeq ($(NEWTERM_EMBEDDED),1)
	mkdir -p $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
	cp -r $(THEOS_LIBRARY_PATH)/Cephei{,Prefs}.framework $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
endif

after-install::
ifneq ($(XCODE),1)
	install.exec "killall NewTerm; sleep 0.1; sblaunch ws.hbang.Terminal"
endif
