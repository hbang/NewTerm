export TARGET = iphone::6.0
export SDKVERSION_arm64 = latest
export SDKVERSION_armv7 = 9.3

# TODO: export ADDITIONAL_CFLAGS = -Wextra -Wno-unused-parameter
export ADDITIONAL_LDFLAGS = -rpath @executable_path/Frameworks

include $(THEOS)/makefiles/common.mk

SUBPROJECTS = NewTerm prefs

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
ifneq ($(XCODE),1)
	install.exec "killall NewTerm; sleep 0.1; sblaunch -p ws.hbang.Terminal"
endif
