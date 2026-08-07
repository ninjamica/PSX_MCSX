#version 420 compatibility

#define gbuffers_solid
#define gbuffers_hand
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

uniform float aspectRatio;
uniform int heldItemId;
uniform int heldItemId2;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D lightmap;

#if Floodfill > 0
	varying vec3 voxelLightColor;
	readonly layout (rgba8) uniform image2D colorimg5;
#endif


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	vec4 position4 = mat4(gl_ModelViewMatrix) * vec4(gl_Vertex) + gl_ModelViewMatrix[3].xyzw;

	#ifdef aspectRatio_fix
		if(!(heldItemId == 10001 && heldItemId2 != heldItemId) && abs(position4.x) > 0.2)
			position4.x -= sign(position4.x) * 0.13 * clamp01((aspectRatio - 1.7) / (1.0 - 1.7)) * position4.w;
	#endif

	vec3 position = position4.xyz;

	if(heldItemId != 10001 && heldItemId2 != 10001)
		position = PixelSnap(position4, vertex_inaccuracy_hand).xyz;

	color = gl_Color;
	
	gl_Position = gl_ProjectionMatrix * vec4(position, 1.0);

	// Voxelization
	#if Floodfill > 0
		ivec3 voxelPos = getPreviousVoxelIndex(vec3(0.0), cameraPosition, previousCameraPosition);
		if(IsInVoxelizationVolume(voxelPos)) {
			float lightMult = getLightMult(lmcoord.y, lightmap);
			ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
			voxelLightColor = imageLoad(colorimg5, voxelIndex).rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}
	#endif
}
