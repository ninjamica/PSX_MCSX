#version 420 compatibility

#define gbuffers_block
#define gbuffers_solid

#include "/shaders.settings"

#ifdef Player_Ignore_Post
    #define Use_Player_Ignore_Post
#endif

#include "/programs/gbuffers.fsh"