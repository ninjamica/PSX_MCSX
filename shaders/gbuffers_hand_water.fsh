#version 420 compatibility

#define gbuffers_solid
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

#if Floodfill > 0
	varying vec3 voxelLightColor;
#endif

uniform sampler2D texture;
uniform sampler2D lightmap;

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {
	vec4 colorVal = texture2D(texture, texcoord) * color;

	#if Floodfill > 0
		vec4 lighting = vec4(voxelLightColor, 0.0);
		lighting += (texture2D(lightmap, vec2(1.0/32.0, lmcoord.y)) * 0.8 + 0.2);
	#else
		vec4 lighting = texture2D(lightmap, lmcoord.xy) * 0.8 + 0.2;
	#endif

	colorOut = colorVal * lighting;
	textOut = vec4(0.0);
}
