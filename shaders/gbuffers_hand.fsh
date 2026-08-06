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
uniform int heldItemId;
uniform int heldItemId2;
uniform ivec2 atlasSize;
uniform float alphaTestRef;

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {
	colorOut = texture2D(texture, texcoord) * color;

	if (colorOut.a < alphaTestRef) discard;

	#if Floodfill > 0
		vec4 lighting = vec4(voxelLightColor, 0.0);
		lighting += (texture2D(lightmap, vec2(1.0/32.0, lmcoord.y)) * 0.8 + 0.2);
	#else
		vec4 lighting = texture2D(lightmap, lmcoord.xy) * 0.8 + 0.2;
	#endif

	colorOut *= lighting;

	#ifdef Player_Ignore_Post
		if(heldItemId == 10002 || (heldItemId2 == 10002 && atlasSize.x == 0)) {
			vec3 hsv = rgb2hsv(colorOut.rgb);
			hsv.y /= saturation;
			colorOut.rgb = hsv2rgb(hsv);

			colorOut.rgb = (colorOut.rgb - 0.5) * (1.0/contrast) + 0.5;
		}
	#endif
	
	textOut = vec4(0.0, 0.0, 0.0, 1.0);
}
