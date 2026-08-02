#version 420 compatibility

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying vec3 viewPos;

#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

uniform vec2 texelSize;
uniform sampler2D texture;
uniform sampler2D lightmap;

uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float sunAngle;
uniform float rainStrength;
uniform float eyeAltitude;
uniform float near;
uniform float far;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;
uniform float alphaTestRef;

#include "/lib/fog.glsl"

#if Floodfill > 0 && defined Floodfill_Particles
	varying vec3 voxelLightColor;
#endif

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {
	vec2 affine = AffineMapping(texcoordAffine, texcoord, texelSize, 2);
	colorOut = texture2D(texture, texcoord) * color;

	if (colorOut.a < alphaTestRef) discard;

	#if Floodfill > 0 && defined Floodfill_Particles
		vec4 lighting = vec4(voxelLightColor, 0.0);
		lighting += (texture2D(lightmap, vec2(1.0/32.0, lmcoord.y)) * 0.8 + 0.2);
	#else
		vec4 lighting = texture2D(lightmap, lmcoord.xy) * 0.8 + 0.2;
	#endif
	
	colorOut *= lighting;

	vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
	
	textOut = vec4(0.0, 1.0, 0.0, 1.0);
}
