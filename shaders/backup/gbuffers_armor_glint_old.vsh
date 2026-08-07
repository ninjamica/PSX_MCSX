#version 420 compatibility
#include "/lib/psx_util.glsl"

#define gbuffers_solid
#define gbuffers_entities
#define gbuffers_hand
#include "/shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 viewPos;

uniform int heldItemId;
uniform int heldItemId2;
uniform float aspectRatio;
uniform int renderStage;


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;

	vec4 position4 = gl_ModelViewMatrix * gl_Vertex + gl_ModelViewMatrix[3].xyzw;
	vec3 position = position4.xyz;
	
	if(renderStage == MC_RENDER_STAGE_HAND_SOLID) {
		if(gl_VertexID < 4 || gl_VertexID > 8) {
			gl_Position = vec4(-10.0);
			return;
		}

		#ifdef aspectRatio_fix
		if(!(heldItemId == 10001 && heldItemId2 != heldItemId) && abs(position4.x) > 0.2)
			position4.x -= sign(position4.x) * 0.13 * clamp01((aspectRatio - 1.7) / (1.0 - 1.7)) * position4.w;
		#endif
		
		position = PixelSnap(position4, vertex_inaccuracy_hand).xyz;
	}
	else {
		vec4 ftrans = ftransform();
		float depth = clamp(ftrans.w, 0.001, 1000.0);
		float sqrtDepth = sqrt(depth);

		position = PixelSnap(position4, vertex_inaccuracy_entities / sqrtDepth).xyz;
	}

	viewPos = position;
	
	gl_Position = gl_ProjectionMatrix * vec4(position, 1.0);

}