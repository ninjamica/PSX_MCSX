#version 420 compatibility

uniform float playerMood;

flat in float moodVelocity;
flat in float moodAccumulation;
flat in float moodMultiplier;

/* RENDERTARGETS: 12 */
layout(location = 0) out vec4 moodOut;

void main() {

    moodOut.r = playerMood;
    moodOut.g = moodVelocity;
    moodOut.b = moodAccumulation;
    moodOut.a = moodMultiplier;
}