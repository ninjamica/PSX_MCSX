#version 420 compatibility

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float alphaTestRef;

/* RENDERTARGETS: 10 */
layout(location = 0) out vec4 colorOut;

void main() {
	colorOut = texture2D(texture, texcoord);

	if(colorOut.a < alphaTestRef)
		discard;

	colorOut *= texture2D(lightmap, lmcoord) * color;
}
