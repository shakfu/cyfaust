# set path so `faust` be queried for the path to stdlib
export PATH := $(PWD)/bin:$(PATH)

DEBUG := 0
STATIC := 0

ifeq ($(DEBUG),1)
	PYTHON := python/bin/python3 -X showrefcount -X tracemalloc
	MEMRAY := python/bin/python3 -m memray

else
	PYTHON := python3
	MEMRAY := python3 -m memray
endif

MIN_OSX_VER := -mmacosx-version-min=13.6

FAUST_STATICLIB := ./lib/libfaust.a
INTERP_TESTS := tests/test_faust_interp

.PHONY: all setup wheel clean reset

all: setup

setup:
	@mkdir -p build
	@STATIC=$(STATIC) $(PYTHON) setup.py build --build-lib build 2>&1 | tee build/log.txt

wheel:
	@$(PYTHON) setup.py bdist_wheel
ifeq ($(STATIC),0)
	delocate-wheel -v dist/*.whl 
endif

.PHONY: test test_cpp test_c test_audio pytest memray

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


test: setup
	@$(PYTHON) tests/test_cyfaust_interp.py
	@$(PYTHON) tests/test_cyfaust_box.py
	@$(PYTHON) tests/test_cyfaust_signal.py
	@$(PYTHON) tests/test_cyfaust_common.py
	@echo "DONE"

pytest:
	@$(PYTHON) -Xfaulthandler -mpytest -vv ./tests

memray:
	@rm -rf tests/*.bin tests/*.html
	@$(MEMRAY) run --native tests/test_cyfaust_interp.py
	@$(MEMRAY) run --native tests/test_cyfaust_box.py
	@$(MEMRAY) run --native tests/test_cyfaust_signal.py
	@$(MEMRAY) run --native tests/test_cyfaust_common.py
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
	@rm -rf python bin lib share 
