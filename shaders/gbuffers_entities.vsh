#version 420 compatibility

#define gbuffers_entities
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_entities
#define PixelSnap_ViewSpace
#define Floodfill_Write

#include "/shaders.settings"

#include "/programs/gbuffers.vsh"