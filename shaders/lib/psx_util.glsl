#ifndef PSX_UTIL
#define PSX_UTIL

float clamp01(float value) {
	return clamp(value, 0.0, 1.0);
}

vec2 clamp01(vec2 value) {
	return clamp(value, 0.0, 1.0);
}

vec3 clamp01(vec3 value) {
	return clamp(value, 0.0, 1.0);
}

vec4 clamp01(vec4 value) {
	return clamp(value, 0.0, 1.0);
}

vec4 PixelSnap(vec4 pos, float inaccuracy) {
	inaccuracy += 0.1;
	vec2 screenParams = vec2(1080, 1080);
	vec2 hpc = screenParams * 0.75;
	vec4 pixelPos = pos;
	pixelPos.xy = pos.xy / pos.w;
	pixelPos.xy = floor(pixelPos.xy * hpc / inaccuracy) * inaccuracy / hpc;
	pixelPos.xy *= pos.w;
	return pixelPos;
}

vec2 AffineMapping(vec3 aUv, vec2 oUv, vec2 ts, float clampAmt) {
	vec2 bounds = ts * clampAmt;
	return vec2(clamp(aUv.x / aUv.z, oUv.x - bounds.x, oUv.x + ts.x + bounds.x), clamp(aUv.y / aUv.z, oUv.y - bounds.y, oUv.y + ts.y + bounds.y));
}

float linearizeDepthFast(float depth, float near, float far) {
	return (near * far) / (depth * (near - far) + far);
}

float luminance(vec3 v) {
    return dot(v, vec3(0.2126f, 0.7152f, 0.0722f));
}

// HSV functions from Sam Hocevar (https://gamedev.stackexchange.com/a/59808/22302)
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
	vec4 homoPos = projectionMatrix * vec4(position, 1.0);
	return homoPos.xyz / homoPos.w;
}

vec3 screenToView(vec2 texcoord, float depth, mat4 inverseProjectionMatrix) {
	vec3 ndcPos = vec3(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0);
	return projectAndDivide(inverseProjectionMatrix, ndcPos);
}

#ifdef FILTER3POINT
// Wraps a texcoord value to stay within given bounds
void wrapTexcoord(inout vec2 texcoord, vec4 textureBounds) {
    vec2 texSize = (textureBounds.zw - textureBounds.xy);
    texcoord -= floor((texcoord - textureBounds.xy) / texSize) * texSize;
}

vec4 texOffsetWrap(sampler2D tex, vec2 texcoord, vec2 offset, ivec2 atlasSize, vec4 textureBounds, mat2 dFdXY) {
	texcoord -= (offset)/atlasSize;
	wrapTexcoord(texcoord, textureBounds);
	return textureGrad(tex, texcoord, dFdXY[0], dFdXY[1]);
}

vec4 texOffsetClamp(sampler2D tex, vec2 texcoord, vec2 offset, ivec2 atlasSize, vec4 textureBounds, mat2 dFdXY) {
	texcoord -= (offset)/atlasSize;
	texcoord = clamp(texcoord, textureBounds.xy, textureBounds.zw);
	return textureGrad(tex, texcoord, dFdXY[0], dFdXY[1]);
}


vec4 texture3PointWrap(sampler2D tex, vec2 texcoord, ivec2 atlasSize, vec4 textureBounds, mat2 dFdXY) {
	vec2 offset = fract(texcoord * atlasSize - vec2(0.5));
	offset -= step(1.0, offset.x + offset.y);
	vec4 c0 = texOffsetWrap(tex, texcoord, offset, atlasSize, textureBounds, dFdXY);
	vec4 c1 = texOffsetWrap(tex, texcoord, vec2(offset.x - sign(offset.x), offset.y), atlasSize, textureBounds, dFdXY);
	vec4 c2 = texOffsetWrap(tex, texcoord, vec2(offset.x, offset.y - sign(offset.y)), atlasSize, textureBounds, dFdXY);
	return c0 + abs(offset.x)*(c1-c0) + abs(offset.y)*(c2-c0);
}

vec4 texture3PointClamp(sampler2D tex, vec2 texcoord, ivec2 atlasSize, vec4 textureBounds, mat2 dFdXY) {
	vec2 offset = fract(texcoord * atlasSize - vec2(0.5));
	offset -= step(1.0, offset.x + offset.y);
	vec4 c0 = texOffsetClamp(tex, texcoord, offset, atlasSize, textureBounds, dFdXY);
	vec4 c1 = texOffsetClamp(tex, texcoord, vec2(offset.x - sign(offset.x), offset.y), atlasSize, textureBounds, dFdXY);
	vec4 c2 = texOffsetClamp(tex, texcoord, vec2(offset.x, offset.y - sign(offset.y)), atlasSize, textureBounds, dFdXY);
	return c0 + abs(offset.x)*(c1-c0) + abs(offset.y)*(c2-c0);
}
#endif

#endif