include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei VT100
NewTerm_CFLAGS = -include NewTerm-Prefix.pch -Iheaders -I../VT100 -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
