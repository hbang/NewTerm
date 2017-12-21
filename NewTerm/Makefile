include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m) $(wildcard ../VT100/*.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics QuartzCore
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei
NewTerm_LIBRARIES = curses
NewTerm_CFLAGS = -Iheaders -I../VT100 -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
