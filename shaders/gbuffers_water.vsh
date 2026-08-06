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
varying vec3 viewPos;
varying float isWaterBackface;

attribute vec4 mc_Entity;
attribute vec3 at_midBlock;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D lightmap;
uniform int isEyeInWater;
uniform mat4 gbufferModelViewInverse;
uniform int frameCounter;
uniform ivec2 atlasSize;

#if Floodfill > 0
	varying vec3 voxelLightColor;
	layout (rgba8) uniform image2D colorimg3;
	layout (rgba8) uniform image2D colorimg4;
	readonly layout (rgba8) uniform image2D colorimg5;
#endif


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	int blockID = int(mc_Entity.x + 0.5);

	vec4 vertexPos = gl_Vertex;


	if(blockID == 10001) {
		vertexPos.y += water_wave_height * sin(water_wave_speed * frameTimeCounter + water_wave_length * (cos(water_wave_angle) * (vertexPos.x + cameraPosition.x) + sin(water_wave_angle) * (vertexPos.z + cameraPosition.z)));
	}
	else if(blockID == 11030) {
		vertexPos.y += lava_wave_height * sin(lava_wave_speed * frameTimeCounter + lava_wave_length * (cos(lava_wave_angle) * (vertexPos.x + cameraPosition.x) + sin(lava_wave_angle) * (vertexPos.z + cameraPosition.z)));
	}

	// "Fixes" z fighting with waterlogged blocks
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	vertexPos.xyz += normal * -0.001;
	
	viewPos = (gl_ModelViewMatrix * vertexPos).xyz;
	vec4 ftrans = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	float depth = clamp(ftrans.w, 0.001, 1000.0);
	float sqrtDepth = sqrt(depth);
	
	vec4 position4 = PixelSnap(ftrans, vertex_inaccuracy_terrain / sqrtDepth);
	vec3 position = position4.xyz;
	
	float wVal = (mat3(gl_ProjectionMatrix) * position).z;
	wVal = clamp(wVal, -10000.0, 0.0);
	texcoordAffine = vec3(texcoord * wVal, wVal);
	texcoordAffine.xy -= sign(mc_midTexCoord - texcoord) * 0.001/atlasSize;
	
	gl_Position = position4;


	// Voxelization
	#if Floodfill > 0
		vec3 centerPos = gl_Vertex.xyz + at_midBlock/64.0;

		ivec3 voxelPos = getPreviousVoxelIndex(centerPos, cameraPosition, previousCameraPosition);
		if(all(greaterThan(abs(at_midBlock), vec3(27.0))) && any(equal(gl_Normal * sign(at_midBlock), vec3(-1.0)))) {
			voxelPos += ivec3(gl_Normal.xyz);
		}

		if(IsInVoxelizationVolume(voxelPos)) {
			float lightMult = getLightMult(lmcoord.y, lightmap);
			ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
			vec4 voxel_raw = imageLoad(colorimg5, voxelIndex);
			voxelLightColor = voxel_raw.rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}


		if(gl_VertexID % 4 == 0 && (blockID >= 11000 && blockID < 12000)) {
			voxelPos = ivec3(floor(SceneSpaceToVoxelSpace(centerPos, cameraPosition)));
			if(IsInVoxelizationVolume(voxelPos)) {
				ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);

				vec4 lightVal = vec4(0.0, 0.0, 0.0, 0.75);
				if(blockID >= 11000) {
					lightVal = vec4(lightColors[blockID - 11000], 1.0);
				}

				if (frameCounter % 2 == 0)
					imageStore(colorimg4, voxelIndex, lightVal);
				else
					imageStore(colorimg3, voxelIndex, lightVal);
			}
		}

		isWaterBackface = 0.0;
		if(blockID == 10001) {

			vec3 worldNormal = mat3(gbufferModelViewInverse) * normal.xyz;

			ivec3 deltaCameraPos = ivec3(floor(cameraPosition.xyz) - floor(previousCameraPosition.xyz));
			ivec3 samplePos = ivec3(floor(SceneSpaceToVoxelSpace(centerPos + 0.51*worldNormal, cameraPosition)));
			ivec2 voxelIndex = GetVoxelStoragePos(samplePos + deltaCameraPos);
			vec4 voxelData;
			if (frameCounter % 2 == 0)
				voxelData = imageLoad(colorimg3, voxelIndex);
			else
				voxelData = imageLoad(colorimg4, voxelIndex);

			isWaterBackface = 0.0;
			if(voxelData.a > 0.6 && voxelData.a < 0.8) {
				isWaterBackface = 1.0;
				color.a = 0.0;
			}
		}
	#endif

}
