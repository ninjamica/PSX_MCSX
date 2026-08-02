#version 420 compatibility
 
#define gbuffers_armor_glint
#include "/shaders.settings"
#include "/lib/psx_util.glsl"


varying vec4 color;
varying vec2 texcoord;
varying vec3 viewPos;

uniform sampler2D texture;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float near;
uniform float far;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;

#include "/lib/fog.glsl"

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 colorOut;

void main() {
	colorOut = texture2D(texture, texcoord + vec2(frameTimeCounter/8.0)) * color * enchanted_strength;

	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	colorOut *= 1.0-fogDepth;
}
