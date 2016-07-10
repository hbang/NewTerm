include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = VT100
VT100_FILES = $(wildcard *.m)
VT100_FRAMEWORKS = CoreGraphics CoreText QuartzCore UIKit
VT100_CFLAGS = -include ../NewTerm/NewTerm-Prefix.pch -I../headers
VT100_LIBRARIES = curses
VT100_INSTALL_PATH = /Applications/NewTerm.app/Frameworks

include $(THEOS_MAKE_PATH)/framework.mk
