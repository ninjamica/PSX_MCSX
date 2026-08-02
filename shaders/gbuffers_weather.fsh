#version 420 compatibility

varying vec4 color;

varying vec2 texcoord;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float alphaTestRef;

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {

	vec4 colorOut = texture2D(texture, texcoord)*color;
	if (colorOut.a < alphaTestRef) discard;

	colorOut *= texture2D(lightmap, lmcoord);

	textOut = vec4(0.0);
}
