THEOS_DEVICE_IP = 192.168.1.211
ARCHS = arm64
include /Users/artikushg/theos/makefiles/common.mk

TWEAK_NAME = iWantHome
iWantHome_FILES = Tweak.xm
iWantHome_FRAMEWORKS = UIKit IOKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
