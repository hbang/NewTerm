export TARGET = iphone:clang:latest:8.0

export ADDITIONAL_LDFLAGS = -rpath @executable_path/Frameworks

include $(THEOS)/makefiles/common.mk

SUBPROJECTS = NewTerm prefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
ifneq ($(XCODE),1)
	install.exec "killall NewTerm; sblaunch ws.hbang.Terminal"
endif
