include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NewTerm
NewTerm_FILES = $(wildcard *.m)
NewTerm_INSTALL_PATH = /Library/PreferenceBundles
NewTerm_PRIVATE_FRAMEWORKS = Preferences
NewTerm_EXTRA_FRAMEWORKS = CepheiPrefs
NewTerm_CFLAGS = -include ../NewTerm/NewTerm-Prefix.pch -I../headers -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
