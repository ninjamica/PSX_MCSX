#version 420 compatibility

#define gbuffers_entities
#define gbuffers_solid

#include "/shaders.settings"

#ifdef Player_Ignore_Post
    #define Use_Player_Ignore_Post
#endif

#include "/programs/gbuffers.fsh"