TARGET = :clang:7.0:5.0
GO_EASY_ON_ME = 1
# ^ i'm so sorry

include theos/makefiles/common.mk

THEOS_BUILD_DIR = debs

APPLICATION_NAME = MobileTerminal
MobileTerminal_FILES = main.m $(wildcard Classes/*.m) $(wildcard Classes/*/*.m)
MobileTerminal_FRAMEWORKS = UIKit CoreGraphics QuartzCore CoreText
MobileTerminal_PRIVATE_FRAMEWORKS = Preferences
MobileTerminal_CFLAGS = -Iheaders -IClasses -include MobileTerminal_Prefix.pch
MobileTerminal_LIBRARIES = curses

include $(THEOS_MAKE_PATH)/application.mk

after-install::
ifeq ($(shell uname -sp),Darwin arm)
	killall MobileTerminal || true
	sleep 0.2
	sblaunch ws.hbang.Terminal
else
	install.exec "killall MobileTerminal || true; sleep 0.2; sblaunch ws.hbang.Terminal"
endif
