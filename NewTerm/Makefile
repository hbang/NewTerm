include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m) $(wildcard *.x) $(wildcard ../VT100/*.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics QuartzCore
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei
NewTerm_LIBRARIES = curses
NewTerm_CFLAGS = -I../headers -I../VT100 -fobjc-arc
NewTerm_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

after-NewTerm-stage::
ifeq ($(NEWTERM_EMBEDDED),1)
	mkdir -p $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
	cp -r $(THEOS_LIBRARY_PATH)/Cephei{,Prefs}.framework $(THEOS_STAGING_DIR)/Applications/NewTerm.app/Frameworks
endif
