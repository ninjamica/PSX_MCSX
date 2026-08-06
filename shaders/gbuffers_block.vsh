#version 420 compatibility

#define gbuffers_solid
#define gbuffers_terrain
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying float isText;
varying vec3 viewPos;

attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

uniform int blockEntityId;
uniform int frameCounter;
uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D lightmap;

#if Floodfill > 0
	varying vec3 voxelLightColor;
	writeonly layout (rgba8) uniform image2D colorimg3;
	writeonly layout (rgba8) uniform image2D colorimg4;
	readonly layout (rgba8) uniform image2D colorimg5;
#endif

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	isText = float(blockEntityId == 10920 && atlasSize.x == 0);
	
	color = gl_Color;

	vec4 vertexPos = gl_Vertex;
	
	viewPos = (gl_ModelViewMatrix * vertexPos).xyz;
	vec4 ftrans = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	float depth = clamp(ftrans.w, 0.001, 1000.0);
	float sqrtDepth = sqrt(depth);

	vec4 position4 = ftrans;

	position4 = PixelSnap(ftrans, vertex_inaccuracy_terrain / sqrtDepth);
	vec3 position = position4.xyz;
	
	float wVal = (mat3(gl_ProjectionMatrix) * position).z;
	wVal = clamp(wVal, -10000.0, 0.0);
	texcoordAffine = vec3(texcoord * wVal, wVal);
	texcoordAffine.xy -= sign(mc_midTexCoord - texcoord) * 0.001/atlasSize;

	if(isText > 0.5) {
		texcoordAffine.xy = texcoord;
		position4 = ftrans;
		position4.z -= 0.005;
	}

	gl_Position = position4;


	// Voxelization
	#if Floodfill > 0
		vec2 centerDir = sign(mc_midTexCoord - texcoord);
		vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
		vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
		vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 bitangent = cross(normal, tangent) * sign(-at_tangent.w);

		vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos + 0.5*normal + 0.01*centerDir.x*tangent + 0.01*centerDir.y*bitangent, 1.0)).xyz;
		ivec3 voxelPos = getPreviousVoxelIndex(playerPos, cameraPosition, previousCameraPosition);
		if(IsInVoxelizationVolume(voxelPos)) {
			float lightMult = getLightMult(lmcoord.y, lightmap);
			ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
			voxelLightColor = imageLoad(colorimg5, voxelIndex).rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}

		if(gl_VertexID % 4 == 0 && blockEntityId >= 11000 && blockEntityId < 12000) {
			playerPos = (gbufferModelViewInverse * vec4(viewPos - 0.5*normal + 0.01*centerDir.x*tangent + 0.01*centerDir.y*bitangent, 1.0)).xyz;
			voxelPos = ivec3(floor(SceneSpaceToVoxelSpace(playerPos, cameraPosition)));

			if(IsInVoxelizationVolume(voxelPos)) {
				ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
				if (frameCounter % 2 == 0)
					imageStore(colorimg4, voxelIndex, vec4(lightColors[blockEntityId - 11000], 1.0));
				else
					imageStore(colorimg3, voxelIndex, vec4(lightColors[blockEntityId - 11000], 1.0));
			}
		}

		if(isText > 0.5 && lmcoord.x > 15.0/16.0) {
			lmcoord.y = 1.0;
			voxelLightColor = vec3(0.5);
		}
	#endif
}
