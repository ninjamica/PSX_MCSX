#version 420 compatibility

/*
const int  colortex10Format  = RGBA8;
const vec4 colortex10ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const int  colortex1Format  = RG8;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const int  colortex2Format  = RGBA8;
const int  colortex3Format  = RGBA8;
const bool colortex3Clear  = false;
const int  colortex4Format  = RGBA8;
const bool colortex4Clear  = false;
const int  colortex5Format  = RGBA8;
const bool colortex5Clear   = false;
const int  colortex7Format  = RGBA8;
const int  colortex8Format  = RGBA8;
const int  colortex11Format = RGBA8;
const int  colortex12Format = RGBA8_SNORM;
const bool colortex12Clear  = false;
*/

#define composite
#include "/shaders.settings"
#include "/lib/psx_util.glsl"

#define DITHER_COLORS 128

uniform sampler2D colortex10;
uniform sampler2D colortex1;
uniform float viewWidth;
uniform float viewHeight;

vec3 GetDither(ivec2 pos, vec3 c, float intensity) {
	int DITHER_THRESHOLDS[16] = int[]( -4, 0, -3, 1, 2, -2, 3, -1, -3, 1, -4, 0, 3, -1, 2, -2 );
	int index = (pos.x & 3) * 4 + (pos.y & 3);

	c.xyz = clamp(c.xyz * (DITHER_COLORS-1) + DITHER_THRESHOLDS[index] * (intensity * 100), vec3(0), vec3(DITHER_COLORS-1));

	c /= DITHER_COLORS;
	return c;
}

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 colorOut;

void main() {
	ivec2 nativeCoord = ivec2(gl_FragCoord.xy);
	ivec2 downscaleCoord = ivec2(gl_FragCoord.xy * resolution_scale);
	ivec2 rescaleCoord = ivec2(downscaleCoord / resolution_scale);

	vec2 textCol     = texelFetch(colortex1, nativeCoord, 0).rg;
	vec2 textColDown = texelFetch(colortex1, rescaleCoord, 0).rg;
	if(textCol.r > 0.5 || textColDown.r > 0.5)
		rescaleCoord = nativeCoord;

    vec3 col = texelFetch(colortex10, rescaleCoord, 0).rgb;

	col = clamp01(1.2 * (col - 0.5) + 0.5);
	col = GetDither(downscaleCoord, col, dither_amount);
	col = clamp01(floor(col * color_depth) / color_depth);

	colorOut.rgb = col;
}
