#version 420 compatibility

#define gbuffers_terrain
#define gbuffers_damagedblock
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_terrain
#define PixelSnap_ClipSpace

#include "/shaders.settings"

#include "/programs/gbuffers.vsh"