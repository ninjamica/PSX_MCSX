#version 420 compatibility

#define composite
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

// varying vec2 texcoord;

uniform sampler2D colortex10;
uniform sampler2D colortex9;
uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;

// (This is put here to force Optifine to bind image textures, as it doesn't search in gbuffer vertex stage)
#if Floodfill > 0
	layout (rgba8) uniform image2D colorimg5;
#endif

vec2 screenDistort(vec2 uv)
{
	uv -= vec2(.5,.5);
	uv = uv*1.2*(1./1.2+2.*uv.x*uv.x*uv.y*uv.y);
	uv += vec2(.5,.5);
	return uv;
}

layout(location = 0) out vec4 colorOut;

void main() {

	#ifdef CRT_Warp
		vec2 texcoordWarped = screenDistort(gl_FragCoord.xy * texelSize);
	#else
		vec2 texcoordWarped = gl_FragCoord.xy * texelSize;
	#endif


	#ifdef CRT_Blur
		float blurOffset = 0.5 / (viewWidth * resolution_scale.x);
		vec3 col = vec3(0.0);
		for(int i = -CRT_Blur_Samples/2; i <= CRT_Blur_Samples/2; i++) {
			col += texture2D(colortex10,texcoordWarped + vec2(blurOffset * i / (CRT_Blur_Samples/2), 0.0)).rgb;
		}
		col /= CRT_Blur_Samples;
	#else
		vec3 col = texture2D(colortex10, texcoordWarped).rgb;
	#endif

	col = (col - 0.5) * contrast + 0.5;
	
	vec3 hsv = rgb2hsv(col);
	hsv.y *= saturation;
	col = hsv2rgb(hsv);

	#ifdef CRT_Scanlines
		vec2 baseRes = vec2(viewWidth, viewHeight);
		vec2 dsRes = baseRes * resolution_scale;
		float pixelSize = dsRes.x / baseRes.x;

		vec2 downscale = floor(texcoordWarped * dsRes) / dsRes;

		float scanlineDist = abs(((texcoordWarped.y - downscale.y) / (texelSize.y / resolution_scale)) * 2.0 - 1.0);
		float scanelineFactor = smoothstep(1.0, 0.4, scanlineDist);

		col *= mix(0.7, 1.0, scanelineFactor);
	#endif

	#ifdef CRT_Warp
		vec2 edgeDistances = abs(texcoordWarped * 2.0 - 1.0);
		col *= smoothstep(1.0, 0.98, max(edgeDistances.x, edgeDistances.y));
	#endif

	colorOut = vec4(col, 1.0);
}
