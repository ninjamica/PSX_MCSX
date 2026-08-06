#version 420 compatibility

#define gbuffers_solid
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

uniform ivec2 atlasSize;
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
uniform int blockEntityId;
uniform bool inNether;
uniform bool inEnd;
uniform float alphaTestRef;

#include "/lib/fog.glsl"

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying float isText;
varying vec3 viewPos;

#if Floodfill > 0
	varying vec3 voxelLightColor;
#endif

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

	if(isText > 0.5) {
		affine = texcoord;
	}

	#if Floodfill > 0
		vec4 lighting = vec4(voxelLightColor, 0.0);
		vec2 lightCoords = vec2(1.0/32.0, lmcoord.y);

		// make glow item frames glow
		if(isText > 0.5 && lmcoord.x == 249.0/255.0)
			lightCoords.x = lmcoord.x;

		lighting += (texture2D(lightmap, lightCoords) * 0.8 + 0.2);
	#else
		vec4 lighting =  texture2D(lightmap, lmcoord.xy);
	#endif

	colorOut = texture2D(texture, affine) * color * lighting;

	if (colorOut.a < alphaTestRef) discard;

	#ifdef Player_Ignore_Post
		if(blockEntityId == 10002) {
			vec3 hsv = rgb2hsv(colorOut.rgb);
			hsv.y /= saturation;
			colorOut.rgb = hsv2rgb(hsv);

			colorOut.rgb = (colorOut.rgb - 0.5) * (1.0/contrast) + 0.5;
		}
	#endif

	vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
	float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
	colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
	
	textOut = vec4(isText, 0.0, 0.0, 1.0);
}
