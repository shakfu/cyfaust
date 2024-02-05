
DEBUG := 0
STATIC := 0

ifeq ($(DEBUG),1)
	PYTHON := python/bin/python3 -X showrefcount -X tracemalloc
	MEMRAY := python/bin/python3 -m memray
else
	PYTHON := python3
	MEMRAY := python3 -m memray
endif

LIBFAUST := ./lib/static/libfaust.a
LIBSAMPLERATE := ./lib/static/libsamplerate.a
LIBSNDFILE := ./lib/static/libsndfile.a


TESTS := \
	test_cyfaust_interp.py 	\
	test_cyfaust_box.py 	\
	test_cyfaust_signal.py 	\
	test_cyfaust_common.py


.PHONY: all faust samplerate sndfile build wheel release build_with_log \
		test pytest test_wheel testcpp memray docs clean reset


all: build

$(LIBFAUST):
	$(PYTHON) scripts/manage.py setup --faust

$(LIBSAMPLERATE):
	$(PYTHON) scripts/manage.py setup --samplerate

$(LIBSNDFILE):
	$(PYTHON) scripts/manage.py setup --sndfile



faust: $(LIBFAUST)
	@echo "libfaust DONE"

samplerate: $(LIBSAMPLERATE)
	@echo "libsamplerate DONE"

sndfile: $(LIBSAMPLERATE) $(LIBSNDFILE)
	@echo "libsndfile DONE"

build: faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py build

wheel: faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py wheel --build

release: faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py wheel --release

test: build
	@$(PYTHON) scripts/manage.py test
	@echo "DONE"

test_wheel:
	@$(PYTHON) scripts/manage.py wheel --test

testcpp: faust
	@scripts/test_cpp_tests.sh

pytest: faust
	@$(PYTHON) -Xfaulthandler -mpytest -vv ./tests

memray:
	@rm -rf tests/*.bin tests/*.html
	@for test in $(TESTS) ; do \
        $(MEMRAY) run --native tests/$$test ; \
    done
	@for bin in tests/*.bin ; do \
        $(MEMRAY) flamegraph $$bin ; \
    done

docs: clean
	@make
	@$(PYTHON) scripts/gen_htmldoc.py
	@make clean
	@make STATIC=1
	@$(PYTHON) scripts/gen_htmldoc.py

clean:
	@$(PYTHON) scripts/manage.py clean

reset:
	@$(PYTHON) scripts/manage.py clean --reset

build_with_log:
	@STATIC=$(STATIC) $(PYTHON) setup.py build --build-lib build 2>&1 | tee build/log.txt


