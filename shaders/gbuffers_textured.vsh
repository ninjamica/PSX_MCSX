#version 420 compatibility

#define gbuffers_textured
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_terrain
#define PixelSnap_ClipSpace

#include "/shaders.settings"

// TODO: floodfill appears to be broken for particles when enabled
#ifndef Floodfill_Particles
    #define Floodfill 0
#endif

#include "/programs/gbuffers.vsh"