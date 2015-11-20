TARGET = iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

GLOBAL_CFLAGS = -include NewTerm/NewTerm-Prefix.pch -Iheaders -IVT100

LIBRARY_NAME = libvt100
libvt100_FILES = $(wildcard VT100/*.m)
libvt100_FRAMEWORKS = CoreGraphics CoreText QuartzCore UIKit
libvt100_CFLAGS = $(GLOBAL_CFLAGS)
libvt100_LIBRARIES = curses
libvt100_INSTALL_PATH = /Applications/NewTerm.app

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard NewTerm/*.m) $(wildcard NewTerm/SubProcess/*.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_CFLAGS = $(GLOBAL_CFLAGS) -fobjc-arc
NewTerm_LDFLAGS = -L$(THEOS_OBJ_DIR)
NewTerm_LIBRARIES = vt100
NewTerm_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/library.mk
include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall NewTerm; sleep 0.2; sblaunch ws.hbang.Terminal" || true
