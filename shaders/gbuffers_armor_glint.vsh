#version 420 compatibility

#define gbuffers_armor_glint
#define gbuffers_hand
#define gbuffers_entities
#define gbuffers_solid
#define vertex_inaccuracy vertex_inaccuracy_hand
#define PixelSnap_ViewSpace

#undef affine_mapping
#define Floodfill 0

#include "/shaders.settings"

#include "/programs/gbuffers.vsh"