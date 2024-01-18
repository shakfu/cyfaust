
export PATH=`pwd`/bin:$PATH

MIN_OSX_VER="-mmacosx-version-min=13.6"
FAUST_STATICLIB="./lib/static/libfaust.a"
INTERP_TESTS="./tests/test_faust_interp"
PREFIX=`brew --prefix`


function run_test() {
	g++ -std=c++11 ${MIN_OSX_VER} -O3 \
		-DINTERP_DSP=1 \
		${INTERP_TESTS}/$1 \
		-I./include \
		-L./lib -L${PREFIX}/lib ${FAUST_STATICLIB} \
		-o /tmp/interp-test
	/tmp/interp-test tests/dsp/noise.dsp	
}

function run_audio_test() {
	g++ -std=c++11 ${MIN_OSX_VER} -O3 \
		-DINTERP_DSP=1 -D__MACOSX_CORE__ \
		${INTERP_TESTS}/$1 ./include/rtaudio/RtAudio.cpp \
		-I./include \
		-L./lib -L${PREFIX}/lib ${FAUST_STATICLIB} \
		-framework CoreFoundation -framework CoreAudio -lpthread \
		-o /tmp/audio-test
	/tmp/audio-test tests/dsp/noise.dsp
}


run_test interp-test.cpp
run_test interp-test.c
run_audio_test interp-audio-min.cpp
