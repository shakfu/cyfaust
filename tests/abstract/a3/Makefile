.PHONY: all clean build setup

all: build

main: main.cpp
	g++ -std=c++11 -o main main.cpp

build: main

setup:
	@python3 setup.py build_ext --inplace


test: clean setup main
	@echo "--- testing c++"
	@./main
	@echo "--- testing cython"
	@python3 test_demo.py

clean:
	@rm -rf main build demo.cpp
	@rm -f demo.cpython*.so

