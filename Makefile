ifeq ($(PLATFORM),mac)
export TARGET = uikitformac:latest:13.0
else
export TARGET = iphone:latest:10.0
LINK_CEPHEI := 1
endif

PROJECT_DIR := $(PWD)/NewTerm
INCLUDES := -I$(PROJECT_DIR) -I$(PROJECT_DIR)/External -I$(PROJECT_DIR)/External/ncurses

export ADDITIONAL_CFLAGS = -fobjc-arc $(INCLUDES)
export ADDITIONAL_SWIFTFLAGS = $(INCLUDES)

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm

NewTerm_FILES = $(shell find NewTerm -name \*.x -or -name \*.m -or -name \*.swift)
NewTerm_SWIFT_BRIDGING_HEADER = $(PROJECT_DIR)/SupportingFiles/BridgingHeader.h
NewTerm_LIBRARIES = curses
NewTerm_CODESIGN_FLAGS = -S$(PROJECT_DIR)/entitlements.plist

ifeq ($(LINK_CEPHEI),1)
ADDITIONAL_CFLAGS += -DLINK_CEPHEI
ADDITIONAL_SWIFTFLAGS += -DLINK_CEPHEI -Xcc -DLINK_CEPHEI

NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei CepheiUI
endif

include $(THEOS_MAKE_PATH)/application.mk

ifeq ($(LINK_CEPHEI),1)
SUBPROJECTS = prefs

include $(THEOS_MAKE_PATH)/aggregate.mk
endif

after-stage::
ifeq ($(NEWTERM_EMBEDDED),1)
	mkdir -p $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
	cp -r $(THEOS_LIBRARY_PATH)/Cephei{,Prefs,UI}.framework $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
endif

after-install::
ifneq ($(XCODE),1)
ifeq ($(PLATFORM),mac)
	install.exec "open /Applications/NewTerm.app"
else
	install.exec "killall NewTerm; sleep 0.1; sblaunch ws.hbang.Terminal"
endif
endif
