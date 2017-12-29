include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NewTermPreferences
NewTermPreferences_FILES = $(wildcard *.m)
NewTermPreferences_INSTALL_PATH = /Applications/NewTerm.app/PreferenceBundles
NewTermPreferences_PRIVATE_FRAMEWORKS = Preferences
NewTermPreferences_EXTRA_FRAMEWORKS = CepheiPrefs
NewTermPreferences_CFLAGS = -I../headers -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
