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

TESTS := \
	test_cyfaust_interp.py 	\
	test_cyfaust_box.py 	\
	test_cyfaust_signal.py 	\
	test_cyfaust_common.py


.PHONY: all build wheel release clean reset test pytest testcpp memray


all: build

$(FAUST_STATICLIB):
	$(PYTHON) scripts/setup_faust.py

build: $(FAUST_STATICLIB)
	@mkdir -p build
	@STATIC=$(STATIC) $(PYTHON) setup.py build --build-lib build 2>&1 | tee build/log.txt

wheel: $(FAUST_STATICLIB)
	@STATIC=$(STATIC) $(PYTHON) scripts/wheel_mgr.py --build

release: $(FAUST_STATICLIB)
	@$(PYTHON) scripts/wheel_mgr.py --release

test: build
	@for test in $(TESTS) ; do \
        $(PYTHON) tests/$$test ; \
    done
	@echo "DONE"

testcpp: $(FAUST_STATICLIB)
	@scripts/test_cpp_tests.sh

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
