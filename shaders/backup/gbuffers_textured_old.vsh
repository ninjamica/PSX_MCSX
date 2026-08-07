#version 420 compatibility

#define gbuffers_solid
#define gbuffers_terrain
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

attribute vec2 mc_midTexCoord;

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying vec3 viewPos;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D lightmap;
uniform ivec2 atlasSize;


#if Floodfill > 0 && defined Floodfill_Particles
	readonly layout (rgba8) uniform image2D colorimg5;
	varying vec3 voxelLightColor;
#endif

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	vec4 position4 = mat4(gl_ModelViewMatrix) * vec4(gl_Vertex) + gl_ModelViewMatrix[3].xyzw;
	vec3 position = PixelSnap(position4, vertex_inaccuracy_terrain).xyz;
	
	float wVal = (mat3(gl_ProjectionMatrix) * position).z;
	wVal = clamp(wVal, -10000.0, 0.0);
	texcoordAffine = vec3(texcoord * wVal, wVal);
	
	if (atlasSize.x > 0)
		texcoordAffine.xy -= sign(mc_midTexCoord - texcoord) * 0.001/atlasSize;
	else
		texcoordAffine.xy += sign(mc_midTexCoord - texcoord) * 0.00001;

	color = gl_Color;
	
	viewPos = position4.xyz;
	gl_Position = gl_ProjectionMatrix * vec4(position, 1.0);

	// Voxelization
	#if Floodfill > 0 && defined Floodfill_Particles
		vec3 playerPos = (gbufferModelViewInverse * position4).xyz;
		ivec3 voxelPos = getPreviousVoxelIndex(playerPos, cameraPosition, previousCameraPosition);
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
