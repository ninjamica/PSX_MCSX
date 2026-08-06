#version 420 compatibility

#define gbuffers_solid
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

uniform ivec2 atlasSize;

uniform sampler2D depthtex1;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform mat4 gbufferModelView;
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

#include "/lib/fog.glsl"

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying vec3 viewPos;
varying float isWaterBackface;

#if Floodfill > 0
	varying vec3 voxelLightColor;
#endif

uniform sampler2D texture;
uniform sampler2D lightmap;

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {
	#ifdef affine_mapping
		#ifdef affine_clamp_enabled
			vec2 affine = AffineMapping(texcoordAffine, texcoord, 1.0 / atlasSize, affine_clamp);
		#else
			vec2 affine = texcoordAffine.xy / texcoordAffine.z;
		#endif
	#else 
		vec2 affine = texcoord;
	#endif

	#if Floodfill > 0
		vec4 lighting = vec4(voxelLightColor, 0.0);
		lighting += (texture2D(lightmap, vec2(1.0/32.0, lmcoord.y)) * 0.8 + 0.2);
	#else
		vec4 lighting = texture2D(lightmap, lmcoord) * 0.8 + 0.2;
	#endif

	colorOut = texture2D(texture, affine) * color * lighting;

	if (isWaterBackface > 0.5) {
		vec3 oldCol = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0).rgb;
		float oldDepth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;
		vec3 oldFogCol = getFogColor(1, vec3(0.0), vec3(0.0));
		// vec3 oldFogCol = vec3(10.0);

		vec3 oldViewPos = screenToView(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oldDepth, gbufferProjectionInverse);
		float oldFogDepth = getFogDepth(oldViewPos, oldDepth, 1, near, far);
		oldCol = mix(oldCol, oldFogCol, oldFogDepth);
		// oldCol = oldFogCol;

		colorOut = vec4(oldCol, 1.0);
	}

	vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
	
	textOut = vec4(0.0);
}
