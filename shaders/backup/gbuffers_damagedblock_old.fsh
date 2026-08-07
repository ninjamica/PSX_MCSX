#version 420 compatibility

#define gbuffers_solid
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

uniform ivec2 atlasSize;
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float alphaTestRef;

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;

#if Floodfill > 0
	varying vec3 voxelLightColor;
#endif

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 colorOut;

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
		vec4 lighting = texture2D(lightmap, lmcoord.xy);
	#endif

	colorOut = texture2D(texture, affine) * color * lighting;

	if (colorOut.a < alphaTestRef) discard;
}
