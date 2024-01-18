# Errors on x86 macOS Ventura 13.6.3 running python debug build

running `make test DEBUG=1` with

faust version: 2.69.3

debug python configured as follows:

 --with-pydebug,
 --with-address-sanitizer,
 --with-undefined-behavior-sanitizer,

built using `./scripts/get_debug_python.py`

The following is an annotated part of the error output.

## initial

```c
python3(17938,0x7ff84bd83780) malloc: nano zone abandoned due to inability to reserve vm space.
```

## >> testing cyfaust.interp

### test_interp_create_dsp_factory_from_file1

```c++
cyfaust/interp.cpp:20245:12: runtime error: call to function __pyx_pw_7cyfaust_6interp_15create_dsp_factory_from_file(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
interp.cpp:12901: note: __pyx_pw_7cyfaust_6interp_15create_dsp_factory_from_file(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/interp.cpp:20245:12 in

compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
sha key 324C05454AD8094392629BF28647CF8A9C544440
openVerticalBox label : [Noise]
declare key : [acc val : 0 0 -10 0 10]
declare key : [style val : knob]
addVerticalSlider label : [/Noise/Volume init : 0.5 min : 0 max : 1 step : 0.1]
closeBox
./cyfaust/include/faust/audio/rtaudio-dsp.h:65:27: runtime error: variable length array bound evaluates to non-positive value 0
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior ./cyfaust/include/faust/audio/rtaudio-dsp.h:65:27 in

RtApiCore::stopStream(): the stream is already stopped!


RtApiCore::stopStream(): the stream is already stopped!
```

### test_create_dsp_factory_from_boxes

```c++
src/cyfaust/box.cpp:80077:12: runtime error: call to function __pyx_pw_7cyfaust_3box_25box_int(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
box.cpp:29418: note: __pyx_pw_7cyfaust_3box_25box_int(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/box.cpp:80077:12 in
compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
include pathnames: []
factory name: dspme
factory key:
```

### test_create_dsp_factory_from_signals1

```c++
src/cyfaust/signal.cpp:84487:12: runtime error: call to function __pyx_pw_7cyfaust_6signal_27sig_input(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
signal.cpp:44715: note: __pyx_pw_7cyfaust_6signal_27sig_input(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/signal.cpp:84487:12 in
compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
sha key
```

## >> testing cyfaust.box

### test_create_dsp_factory_from_boxes

```c++
src/cyfaust/box.cpp:80077:12: runtime error: call to function __pyx_pw_7cyfaust_3box_25box_int(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
box.cpp:29418: note: __pyx_pw_7cyfaust_3box_25box_int(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/box.cpp:80077:12 in
src/cyfaust/interp.cpp:20245:12: runtime error: call to function __pyx_pw_7cyfaust_6interp_21create_dsp_factory_from_boxes(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
interp.cpp:13476: note: __pyx_pw_7cyfaust_6interp_21create_dsp_factory_from_boxes(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/interp.cpp:20245:12 in
compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
include pathnames: []
factory name: dspme
factory key:
```

### test_box_split

```c++
src/cyfaust/box.cpp:80023:12: runtime error: call to function __pyx_pw_7cyfaust_3box_29box_wire(_object*, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *)'
box.cpp:29720: note: __pyx_pw_7cyfaust_3box_29box_wire(_object*, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/box.cpp:80023:12 in
_<:((_,5e+02f : @),0.5f : +),((_,3e+03f : @),1.5f : *)
```

## >> testing cyfaust.signal

### test_create_source_from_signals1

```c++
src/cyfaust/signal.cpp:84487:12: runtime error: call to function __pyx_pw_7cyfaust_6signal_25sig_real(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
signal.cpp:44558: note: __pyx_pw_7cyfaust_6signal_25sig_real(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/signal.cpp:84487:12 in
```

### test_create_dsp_factory_from_signals1

```c++
src/cyfaust/interp.cpp:20245:12: runtime error: call to function __pyx_pw_7cyfaust_6interp_19create_dsp_factory_from_signals(_object*, _object* const*, long, _object*) through pointer to incorrect function type '_object *(*)(_object *, _object *const *, long, _object *)'
interp.cpp:13278: note: __pyx_pw_7cyfaust_6interp_19create_dsp_factory_from_signals(_object*, _object* const*, long, _object*) defined here
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior src/cyfaust/interp.cpp:20245:12 in
compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
sha key
```
