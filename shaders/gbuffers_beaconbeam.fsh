#version 420 compatibility

#define gbuffers_beaconbeam
#define gbuffers_solid

#include "/shaders.settings"

#ifndef Floodfill_Particles
    #define Floodfill 0
#endif

#include "/programs/gbuffers.fsh"