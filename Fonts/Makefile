include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/null.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Applications/NewTerm.app$(ECHO_END)
	$(ECHO_NOTHING)cp $(wildcard *.ttf *.otf) $(THEOS_STAGING_DIR)/Applications/NewTerm.app$(ECHO_END)
