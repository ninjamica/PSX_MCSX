#version 420 compatibility

uniform sampler2D colortex12;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform ivec2 eyeBrightnessSmooth;
uniform float sunAngle;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform float eyeAltitude;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;

#define gbuffers_sky
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/fog.glsl"

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

/* RENDERTARGETS: 10,11 */
layout(location = 0) out vec4 skyOut;
layout(location = 1) out vec4 fogOut;

void main() {
	
	vec3 skyFogCol;

	if(inNether) {
		skyFogCol = normalize(fogColor) * 0.3 + 0.1;
	}
	else if(inEnd) {
		skyFogCol = vec3(0.0);
	}
	else {
		vec3 viewPos = screenToView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0));
		float caveFactor = fogCaveFactor(eyeAltitude, eyeBrightnessSmooth.y, colortex12);
		
		skyFogCol = getOverworldSkyColor(normalize(viewPos), sunAngle, fogColor, skyColor, rainStrength, gbufferModelView);
		skyFogCol *= mix(0.12, 1.0, caveFactor);
	}

	vec3 fogCol = getFogColor(isEyeInWater, skyFogCol, fogColor);

	skyOut = vec4(fogCol, 1.0);
	fogOut = vec4(fogCol, 1.0);
}
