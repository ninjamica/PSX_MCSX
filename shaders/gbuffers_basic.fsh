#version 420 compatibility

uniform sampler2D colortex11;
uniform sampler2D colortex12;
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
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int blockEntityId;
uniform bool inNether;
uniform bool inEnd;
uniform vec2 texelSize;
uniform float alphaTestRef;

#include "/lib/psx_util.glsl"
#include "/lib/fog.glsl"

varying vec4 color;

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {

	if (color.a < alphaTestRef) discard;

	colorOut = color;
	vec3 viewPos = screenToView(gl_FragCoord.xy*texelSize, gl_FragCoord.z, gbufferProjectionInverse);

	vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
	
	textOut = vec4(0.0, 0.0, 0.0, 1.0);
}
