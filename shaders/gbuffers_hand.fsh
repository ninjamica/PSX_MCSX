#version 420 compatibility

#define gbuffers_hand
#define gbuffers_solid

#include "/shaders.settings"

#undef affine_mapping

#ifdef Player_Ignore_Post
    #define Use_Player_Ignore_Post
#endif


#include "/programs/gbuffers.fsh"