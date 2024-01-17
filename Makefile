# set path so `faust` can be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

PLATFORM := $(shell uname -o)
ARCH := $(shell uname -m)

DEBUG := 0
STATIC := 0

ifeq ($(DEBUG),1)
	PYTHON := python/bin/python3 -X showrefcount -X tracemalloc
	MEMRAY := python/bin/python3 -m memray
else
	PYTHON := python3
	MEMRAY := python3 -m memray
endif

MIN_OSX_VER := -mmacosx-version-min=10.6

FAUST_STATICLIB := ./lib/static/libfaust.a
INTERP_TESTS := tests/test_faust_interp

TESTS := \
	test_cyfaust_interp.py 	\
	test_cyfaust_box.py 	\
	test_cyfaust_signal.py 	\
	test_cyfaust_common.py



.PHONY: all setup wheel release clean reset

all: setup

setup:
	@mkdir -p build
	@STATIC=$(STATIC) $(PYTHON) setup.py build --build-lib build 2>&1 | tee build/log.txt

wheel:
	@STATIC=$(STATIC) $(PYTHON) scripts/wheel_mgr.py --build

release:
	@$(PYTHON) scripts/wheel_mgr.py --release

.PHONY: test test_cpp test_c test_audio pytest memray

test_cpp:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/dsp/noise.dsp

test_c:
	@g++ -O3 $(MIN_OSX_VER) \
		-DINTERP_DSP=1 \
		$(INTERP_TESTS)/interp-test.c \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-o /tmp/interp-test
	@/tmp/interp-test tests/dsp/noise.dsp

test_audio:
	@g++ -std=c++11 $(MIN_OSX_VER) -O3 \
		-DINTERP_DSP=1 -D__MACOSX_CORE__ \
		$(INTERP_TESTS)/interp-audio-min.cpp ./include/rtaudio/RtAudio.cpp \
		-I./include \
		-L./lib -L`brew --prefix`/lib $(FAUST_STATICLIB) \
		-framework CoreFoundation -framework CoreAudio -lpthread \
		-o /tmp/audio-test
	@/tmp/audio-test tests/dsp/noise.dsp


test: setup
	@for test in $(TESTS) ; do \
        $(PYTHON) tests/$$test ; \
    done
	@echo "DONE"

pytest:
	@$(PYTHON) -Xfaulthandler -mpytest -vv ./tests

memray:
	@rm -rf tests/*.bin tests/*.html
	@for test in $(TESTS) ; do \
        $(MEMRAY) run --native tests/$$test ; \
    done
	@for bin in tests/*.bin ; do \
        $(MEMRAY) flamegraph $$bin ; \
    done


clean:
	@rm -rf build dist MANIFEST.in
	@find . -type d \( -name '.*_cache'    \
					-o -name '*.egg-info'  \
					-o -name '.DS_Store'   \
					-o -name '__pycache__' \) -print0 | xargs -0 -I {} /bin/rm -rf "{}"

reset: clean
	@rm -rf python bin lib share wheels
