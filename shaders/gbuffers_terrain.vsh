#version 420 compatibility

#define gbuffers_terrain
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_terrain
#define PixelSnap_ClipSpace
#define Floodfill_Write

#include "/shaders.settings"

#include "/programs/gbuffers.vsh"