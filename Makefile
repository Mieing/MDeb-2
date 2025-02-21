ARCHS = arm64
TARGET := iphone:clang:latest:14.0

DEBUG = 0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = mdeb

mdeb_FILES = main.m
mdeb_CFLAGS = -fobjc-arc
mdeb_CODESIGN_FLAGS = -Sentitlements.plist
mdeb_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
