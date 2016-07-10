include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m) $(wildcard SubProcess/*.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_CFLAGS = -include NewTerm-Prefix.pch -Iheaders -I../VT100 -fobjc-arc
NewTerm_EXTRA_FRAMEWORKS = Cephei CepheiPrefs VT100

include $(THEOS_MAKE_PATH)/application.mk
