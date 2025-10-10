// GUI Static Member Definitions
//
// This file provides definitions for GUI class static members that are
// declared in faust/gui/GUI.h but not defined elsewhere.
//
// These static members are used for global GUI management and timed zone mapping.

#include "faust/gui/GUI.h"
#include "faust/gui/ring-buffer.h"

// Global list of all GUI instances
std::list<GUI*> GUI::fGuiList;

// Global map for timed zone management
std::map<FAUSTFLOAT*, ringbuffer_t*> GUI::gTimedZoneMap;
