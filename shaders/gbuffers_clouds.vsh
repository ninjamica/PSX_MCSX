#version 420 compatibility

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	
	gl_Position = ftransform();
}
