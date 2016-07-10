export TARGET = iphone:clang:latest:8.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS = VT100 NewTerm

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall NewTerm" || true
