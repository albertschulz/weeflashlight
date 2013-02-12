export SDKVERSION=5.0
export THEOS_DEVICE_IP=192.168.178.24

include theos/makefiles/common.mk

BUNDLE_NAME = WeeFlashlight
WeeFlashlight_FILES = WeeFlashlightController.m
WeeFlashlight_INSTALL_PATH = /System/Library/WeeAppPlugins/
WeeFlashlight_FRAMEWORKS = UIKit CoreGraphics AVFoundation

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
