#version 420 compatibility

#define gbuffers_solid
#define gbuffers_entities
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying vec3 viewPos;

uniform ivec2 atlasSize;
uniform vec4 entityColor;
uniform float frameTimeCounter;
uniform int entityId;
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
uniform ivec4 blendFunc;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;
uniform float alphaTestRef;

#include "/lib/fog.glsl"

#if Floodfill > 0
	varying vec3 voxelLightColor;
#endif

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {
	#ifdef affine_mapping
		#ifdef affine_clamp_enabled
			vec2 affine = AffineMapping(texcoordAffine, texcoord, 1.0 / atlasSize, affine_clamp * 4.0);
		#else
			vec2 affine = texcoordAffine.xy / texcoordAffine.z;
		#endif
	#else 
		vec2 affine = texcoord;
	#endif

	if(entityId == 10001) {
		colorOut = vec4(1.0);
	}
	else {
		colorOut = texture2D(texture, affine) * color;
		colorOut.rgb = mix(colorOut.rgb, entityColor.rgb, entityColor.a);
		
		#if Floodfill > 0
			vec4 lighting = vec4(voxelLightColor, 0.0);
			vec2 lightCoords = vec2(1.0/32.0, lmcoord.y);

			// make glow item frames glow
			if(entityId == 10008)
				lightCoords.x = lmcoord.x;

			lighting += (texture2D(lightmap, lightCoords) * 0.8 + 0.2);
		#else
			vec4 lighting = texture2D(lightmap, lmcoord.xy) * 0.8 + 0.2;
		#endif

		if(entityId == 10003) {
			lighting.rgb += mix(vec3(item_darkColor), vec3(item_lightColor), sin(frameTimeCounter * item_speed) * 0.5 + 0.5);
		}

		colorOut *= lighting;

		#ifdef Player_Ignore_Post
			if(entityId == 10002) {
				vec3 hsv = rgb2hsv(colorOut.rgb);
				hsv.y /= saturation;
				colorOut.rgb = hsv2rgb(hsv);

				colorOut.rgb = (colorOut.rgb - 0.5) * (1.0/contrast) + 0.5;
			}
		#endif

		float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);
		if(entityId == 10006 && blendFunc.x == 1) {
			colorOut.rgb *= 1.0-fogDepth;
		}
		else {
			vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
			colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
		}

		if (colorOut.a < alphaTestRef) discard;
	}

	textOut = vec4(0.0);
}
