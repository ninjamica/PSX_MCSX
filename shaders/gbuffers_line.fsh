#version 120

uniform sampler2D colortex11;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float sunAngle;
uniform float rainStrength;
uniform float eyeAltitude;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;

#include "/lib/psx_util.glsl"
#include "/lib/fog.glsl"

varying vec4 color;

/* RENDERTARGETS: 10 */
void main() {
	vec4 col = color;

	vec2 screenPos = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
	vec3 viewPos = screenToView(screenPos, gl_FragCoord.z, gbufferProjectionInverse);

	vec3 fogCol = texture2D(colortex11, screenPos).rgb;
	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	col.rgb = mix(col.rgb, fogCol, fogDepth);

	gl_FragData[0] = col;
}
