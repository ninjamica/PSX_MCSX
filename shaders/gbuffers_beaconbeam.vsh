#version 420 compatibility

#define gbuffers_beaconbeam
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_terrain
#define PixelSnap_ViewSpace

#include "/shaders.settings"

#ifndef Floodfill_Particles
    #define Floodfill 0
#endif

#include "/programs/gbuffers.vsh"