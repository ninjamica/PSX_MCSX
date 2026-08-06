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

attribute vec4 mc_Entity;
attribute vec3 at_midBlock;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform sampler2D lightmap;
uniform mat4 gbufferModelViewInverse;
uniform int frameCounter;

#if Floodfill > 0
	varying vec3 voxelLightColor;
	writeonly layout (rgba8) uniform image2D colorimg3;
	writeonly layout (rgba8) uniform image2D colorimg4;
	readonly layout (rgba8) uniform image2D colorimg5;
#endif


void main() {
	int blockID = int(mc_Entity.x + 0.5);

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	
	color = gl_Color;

	vec4 vertexPos = gl_Vertex;

	// Cross models with offset (grass, plants, flowers)
	if((blockID == 10950 || blockID == 10951 || blockID == 10952)  && gl_Normal.y == 0.0) {
		#ifdef Billboarding
			if(sign(gl_Normal.xz) != vec2(1.0, 1.0)) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * sign(at_tangent.w) * atlasSize.x / 16.0, 0.0);
			vec2 centerPos = vertexPos.xz - 1.8 * facePos.x * normalize(at_tangent).xz * sign(at_tangent.w);

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			// vec2 viewVec = -normalize(vertexPos.xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif

		if(blockID == 10951) {
			blockID = 11000;
		}
		else if(blockID == 10952) {
			texcoord.y -= 2.0 * (texcoord.y - mc_midTexCoord.y);

			if(abs((texcoord.x - mc_midTexCoord.x) * atlasSize.x) > 2.0) {
				vertexPos.y -= 9.0/16.0;
			}
			else {
				vertexPos.y += 6.0/16.0;
			}
		}
	}
	// Vertical Amythest Buds
	else if(blockID == 10953) {
		#ifdef Billboarding
			if(sign(gl_Normal.xz) != vec2(1.0, 1.0)) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2(0.5 * sign(at_midBlock.z) * sign(at_tangent.w), 0.0);
			vec2 centerPos = vertexPos.xz - 0.905 * sign(texcoord.x - mc_midTexCoord.x) * normalize(at_tangent).xz;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif

		blockID = 11004;
	}
	// East/West Amythest Buds
	if(blockID == 10954) {
		#ifdef Billboarding
			if(sign(gl_Normal.yz) != vec2(1.0, 1.0)) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2(0.5 * -sign(at_midBlock.y), 0.0);
			vec2 centerPos = vertexPos.yz + at_midBlock.yz / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].yz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.yz = (rotationMatrix * facePos) + centerPos;
		#endif

		blockID = 11004;
	}
	// North/South Amythest Buds
	if(blockID == 10955) {
		#ifdef Billboarding
			if(sign(gl_Normal.xy) != vec2(1.0, 1.0)) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2(0.5 * -sign(at_midBlock.x), 0.0);
			vec2 centerPos = vertexPos.xy + at_midBlock.xy / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xy);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xy = (rotationMatrix * facePos) + centerPos;
		#endif

		blockID = 11004;
	}
	// Chain x axis
	else if(blockID == 10957) {
		#ifdef Billboarding
			vec2 facePos = vec2(1.5/16.0 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
			vec2 centerPos = vertexPos.yz + at_midBlock.yz / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].yz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.yz = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	// Chain y axis
	else if(blockID == 10958) {
		#ifdef Billboarding
			vec2 facePos = vec2(1.5/16.0 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
			vec2 centerPos = vertexPos.xz + at_midBlock.xz / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	// Chain z axis
	else if(blockID == 10959) {
		#ifdef Billboarding
			vec2 facePos = vec2(1.5/16.0 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
			vec2 centerPos = vertexPos.xy + at_midBlock.xy / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xy);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xy = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	// Hashes and torches
	else if(blockID >= 10960 && blockID < 10964) {
		#ifdef Billboarding
			if(gl_Normal.y != 0.0 /* || at_midBlock.x/64.0 > 0.0 */) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * atlasSize.x / 16.0, 0.0);
			vec2 centerPos = vertexPos.xz + at_midBlock.xz / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif

		if(blockID == 10961) {
			blockID = 11001;
		}
		else if(blockID == 10962) {
			blockID = 11003;
		}
		else if(blockID == 10963) {
			blockID = 11005;
		}
	}
	// Bamboo
	else if(blockID == 10964) {
		#ifdef Billboarding
			if(gl_Normal.z < 0.5 || gl_Normal.x < 0.0) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos;
			vec2 centerPos;
			if(gl_Normal.z > 0.9) {
				facePos = vec2(1.5/16.0 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
				centerPos = vertexPos.xz + vec2(-0.09 * sign(texcoord.x - mc_midTexCoord.x), -1.5/16.0);
			}
			else {
				facePos = vec2(0.5 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
				centerPos = vertexPos.xz - 0.905 * sign(texcoord.x - mc_midTexCoord.x) * normalize(at_tangent).xz;
			}

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	// Potted Bamboo
	else if(blockID == 10982 && abs(at_midBlock.z) < 5) {
		#ifdef Billboarding
			vec3 worldPos = fract(cameraPosition + (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz);
			if(!(abs(worldPos.z - 0.5) < 0.01) || gl_Normal.z > 0.0) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * atlasSize.x / 16.0, 0.0);
			vec2 centerPos = vertexPos.xz + at_midBlock.xz/64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	// Remove extra geometry frame attached melon/pumpkin stems
	else if(blockID == 10965) {
		#ifdef Billboarding
			if(all(lessThan(abs(gl_Normal.xz), vec2(0.9)))) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
		#endif
	}
	// Hanging torches
	else if(blockID >= 10970 && blockID < 10980) {
		#ifdef Billboarding
			if(gl_Normal.y > -0.1 || gl_Normal.y < -0.7) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2(0.5 * sign(texcoord.x - mc_midTexCoord.x), 0.0);
			vec2 centerPos = vertexPos.xz + (at_midBlock.xz / 64.0) * sign(abs(gl_Normal.zx));

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif

		if(blockID == 10970) {
			blockID = 11001;
		}
		else if(blockID == 10971) {
			blockID = 11003;
		}
		else if(blockID == 10973) {
			blockID = 11005;
		}
	}
	// Potted Plants
	else if(blockID == 10980 && all(lessThan(abs(gl_Normal), vec3(0.9))) && gl_Normal.y == 0.0) {
		#ifdef Billboarding
			if(sign(gl_Normal.xz) != vec2(-1.0, 1.0)) {
				gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
				return;
			}
			
			vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * atlasSize.x / 16.0, 0.0);
			vec2 centerPos = vertexPos.xz + at_midBlock.xz / 64.0;

			vec2 viewVec = normalize(gl_ModelViewMatrixInverse[2].xz);
			mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
			vertexPos.xz = (rotationMatrix * facePos) + centerPos;
		#endif
	}
	
	// vec4 ftrans = ftransform();
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
			voxelLightColor = imageLoad(colorimg5, voxelIndex).rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}

		if(gl_VertexID % 4 == 0 && (blockID < 10900 || (blockID >= 11000 && blockID < 12000) || blockID == 10921)) {
			voxelPos = ivec3(floor(SceneSpaceToVoxelSpace(centerPos, cameraPosition)));
			if(IsInVoxelizationVolume(voxelPos)) {
				ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);

				vec4 lightVal = vec4(0.0, 0.0, 0.0, 0.5);
				if(blockID >= 11000) {
					lightVal = vec4(lightColors[blockID - 11000], 1.0);
				}
				else if(blockID == 10921) {
					lightVal = vec4(0.0, 0.0, 0.0, 0.75);
				}

				if (frameCounter % 2 == 0)
					imageStore(colorimg4, voxelIndex, lightVal);
				else
					imageStore(colorimg3, voxelIndex, lightVal);
			}
		}
	#endif
}
