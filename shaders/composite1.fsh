#version 420 compatibility

uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int heldItemId;
uniform int heldItemId2;
uniform int frameCounter;

#include "/lib/voxel.glsl"

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 dataOut;

void main() {

	ivec2 storagePos = ivec2(gl_FragCoord.xy);
	ivec3 voxelIndex = GetVoxelIndex(storagePos);

	vec4 currentBlock;
	if (frameCounter % 2 == 0)
		currentBlock = texelFetch(colortex4, storagePos, 0);
	else
		currentBlock = texelFetch(colortex3, storagePos, 0);

	if(currentBlock.a > 0.7 && currentBlock.a < 0.8)
		currentBlock.a = 0.0;

	#if Floodfill == 2
		dataOut = currentBlock.a < 0.4 ? vec4(0.0) : currentBlock;
	#else
		ivec3 deltaCameraPos = ivec3(floor(cameraPosition.xyz) - floor(previousCameraPosition.xyz));
		storagePos = GetVoxelStoragePos(voxelIndex + deltaCameraPos);

		vec4 light = vec4(texelFetch(colortex5, storagePos, 0).rgb, 0.0);
		dataOut = currentBlock.a < 0.4 ? light : currentBlock;
	#endif

	#ifdef Floodfill_HeltItemLight
		if(all(equal(voxelIndex, ivec3(0, 128, 0)))) {
			if(heldItemId >= 11000 && heldItemId < 12000) {
				dataOut = vec4(max(dataOut.rgb, lightColors[heldItemId-11000]), 1.0);
			}
			if(heldItemId2 >= 11000 && heldItemId < 12000) {
				dataOut = vec4(max(dataOut.rgb, lightColors[heldItemId2-11000]), 1.0);
			}
		}
	#endif
}
