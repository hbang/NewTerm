include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m)
NewTerm_FRAMEWORKS = UIKit CoreGraphics
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = Cephei
NewTerm_CFLAGS = -Iheaders -I../VT100 -fobjc-arc
NewTerm_LDFLAGS = -F$(THEOS_OBJ_DIR) -framework VT100

include $(THEOS_MAKE_PATH)/application.mk
