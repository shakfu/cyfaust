
DEBUG := 0
STATIC := 0

ifeq ($(DEBUG),1)
	PYTHON := python/bin/python3 -X showrefcount -X tracemalloc
	MEMRAY := python/bin/python3 -m memray
else
	PYTHON := python3
	MEMRAY := python3 -m memray
endif

FAUST_STATICLIB := ./lib/static/libfaust.a

TESTS := \
	test_cyfaust_interp.py 	\
	test_cyfaust_box.py 	\
	test_cyfaust_signal.py 	\
	test_cyfaust_common.py


.PHONY: all setup_faust build wheel release test pytest test_wheel \
		testcpp memray docs clean reset


all: build

$(FAUST_STATICLIB):
	$(PYTHON) scripts/manage.py setup --faust

setup_faust: $(FAUST_STATICLIB)
	@echo "faust is setup for cyfaust"

# build: setup_faust
# 	@mkdir -p build
# 	@STATIC=$(STATIC) $(PYTHON) setup.py build --build-lib build 2>&1 | tee build/log.txt

build: setup_faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py build

wheel: setup_faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py wheel --build

release: setup_faust
	@STATIC=$(STATIC) $(PYTHON) scripts/manage.py wheel --release

test: build
	@$(PYTHON) scripts/manage.py test
	@echo "DONE"

test_wheel:
	@$(PYTHON) scripts/manage.py wheel --test

testcpp: setup_faust
	@scripts/test_cpp_tests.sh

pytest: setup_faust
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


# clean:
# 	@rm -rf build dist venv .venv MANIFEST.in
# 	@find . -type d \( -name '.*_cache'    \
# 					-o -name '*.egg-info'  \
# 					-o -name '.DS_Store'   \
# 					-o -name '__pycache__' \) -print0 | xargs -0 -I {} /bin/rm -rf "{}"

# reset: clean
# 	@rm -rf python bin lib share wheels
