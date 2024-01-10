# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

STATIC := 0

MIN_OSX_VER := -mmacosx-version-min=13.6

FAUST_STATICLIB := ./lib/libfaust.a
INTERP_TESTS := tests/test_faust_interp

.PHONY: all setup wheel clean

all: setup

setup:
	@STATIC=$(STATIC) python3 setup.py build --build-lib build

wheel:
	@python3 setup.py bdist_wheel
ifeq ($(STATIC),0)
	delocate-wheel -v dist/*.whl 
endif

.PHONY: test test_cpp test_c test_audio pytest

test_cpp:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/noise.dsp

test_c:
	@g++ -O3 $(MIN_OSX_VER) \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.c \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/noise.dsp

test_audio:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 -D__MACOSX_CORE__ \
		$(INTERP_TESTS)/interp-audio-min.cpp ./include/rtaudio/RtAudio.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-framework CoreFoundation -framework CoreAudio -lpthread \
		-o /tmp/audio-test
	@/tmp/audio-test tests/noise.dsp
# 	@/tmp/audio-test tests/test_faust_interp/foo.dsp


test: setup
	@python3 tests/test_cyfaust_interp.py
	@python3 tests/test_cyfaust_box.py
	@python3 tests/test_cyfaust_signal.py
	@python3 tests/test_cyfaust_common.py
	@echo "DONE"

pytest:
	@python3 -Xfaulthandler -mpytest -vv

clean:
	@rm -rf build dist *.egg-info .pytest_*

