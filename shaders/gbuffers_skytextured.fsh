#version 420 compatibility

#define gbuffers_skytextured
#include "/shaders.settings"
#include "/lib/psx_util.glsl"

varying vec4 color;
varying vec2 texcoord;

uniform sampler2D gtexture;
uniform sampler2D colortex10;
uniform sampler2D colortex12;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform ivec2 eyeBrightnessSmooth;
uniform float sunAngle;
uniform float rainStrength;
uniform float thunderStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform float eyeAltitude;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;

#include "/lib/fog.glsl"

vec3 screenToView(vec3 screenPos) {
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

/* RENDERTARGETS: 10,11 */
layout(location = 0) out vec3 colorOut;
layout(location = 1) out vec3 skytexOut;

void main() {
	vec3 skyFogCol;

	if(inNether) {
		skyFogCol = normalize(fogColor) * 0.3 + 0.1;
	}
	else if(inEnd) {
		skyFogCol = texture2D(gtexture,texcoord).rgb * end_sky_brightness + fogColor;
	}
	else {
		vec3 skytex = (texture2D(gtexture, texcoord) * color * fog_sunmoon).rgb;
		vec3 viewDir = normalize(screenToView(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0)));
		float caveFactor = fogCaveFactor(eyeAltitude, eyeBrightnessSmooth.y, colortex12);

		float upDot = dot(viewDir, gbufferModelView[1].xyz);
		skytex *= smoothstep(-0.2, 0.0, upDot)
			   *  mix(1.0, fog_sunmoon_rain, rainStrength)
		       *  (1.0 - thunderStrength)
		       *  caveFactor;
		
		skyFogCol = getOverworldSkyColor(viewDir, sunAngle, fogColor, skyColor, rainStrength, gbufferModelView);
		if(dot(viewDir, normalize(sunPosition)) > 0.5) {
			skyFogCol = mix(skyFogCol, 2.1*skytex, 1.3*skytex.r);
		}
		else {
			skyFogCol += skytex;
		}

		skyFogCol *= mix(0.12, 1.0, caveFactor);
	}

	vec3 fogCol = getFogColor(isEyeInWater, skyFogCol, fogColor);

	colorOut = fogCol;
	skytexOut = fogCol;
}
