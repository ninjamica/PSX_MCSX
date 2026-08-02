#version 420 compatibility

#define moodSpeed 0.1

uniform sampler2D colortex12;
uniform float playerMood;
uniform ivec2 eyeBrightness;
uniform float frameTime;

flat out float moodVelocity;
flat out float moodAccumulation;
flat out float moodMultiplier;

void main() {
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    vec3 moodData = texture2D(colortex12, vec2(0.0)).rgb;
    float diff = playerMood - moodData.r;
    float dir = (playerMood == 0.0 && eyeBrightness.y > 0) ? -1.0 : (abs(diff) > 0.004 ? sign(diff) : 0.0);

    moodVelocity = moodData.g + dir;

    if(abs(moodVelocity) < 0.1 * frameTime)
        moodVelocity = 0.0;
    else
        moodVelocity -= sign(moodVelocity) * 0.1 * frameTime;

    moodAccumulation = moodData.b + moodSpeed * sign(moodVelocity);

    moodMultiplier = smoothstep(0.89, 0.11, moodAccumulation);
}