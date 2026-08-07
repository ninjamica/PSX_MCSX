#include "/shaders.settings"

const int xzRadiusBlocks = voxelMapResolution / 32;

/*
#ifdef Floodfill_HeltItemLight
#endif
#ifdef Floodfill_Particles
#endif
#ifdef Floodfill
#endif
*/

#if Floodfill > 0

    bool IsInVoxelizationVolume(ivec3 voxelIndex) {
        const ivec3 lo = ivec3(-xzRadiusBlocks    ,   0,-xzRadiusBlocks    );
        const ivec3 hi = ivec3( xzRadiusBlocks - 1, 255, xzRadiusBlocks - 1);

        return clamp(voxelIndex, lo, hi) == voxelIndex;
    }

    vec3 SceneSpaceToVoxelSpace(vec3 scenePosition, vec3 cameraPosition) {
        scenePosition.xz += fract(cameraPosition.xz);
        scenePosition.y  += fract(cameraPosition.y) + 128;
        return scenePosition;
    }
    vec3 WorldSpaceToVoxelSpace(vec3 worldPosition, vec3 cameraPosition) {
        worldPosition.xz -= floor(cameraPosition.xz);
        worldPosition.y  -= floor(cameraPosition.y) - 128;
        return worldPosition;
    }

    vec3 VoxelSpaceToSceneSpace(vec3 voxelPosition, vec3 cameraPosition) {
        voxelPosition.xz -= fract(cameraPosition.xz);
        voxelPosition.y  -= fract(cameraPosition.y) + 128;
        return voxelPosition;
    }
    vec3 VoxelSpaceToWorldSpace(vec3 voxelPosition, vec3 cameraPosition) {
        voxelPosition.xz += floor(cameraPosition.xz);
        voxelPosition.y  += floor(cameraPosition.y) - 128;
        return voxelPosition;
    }

    ivec2 GetVoxelStoragePos(ivec3 voxelIndex) {
        return (voxelIndex.xz + xzRadiusBlocks) * 16 + ivec2(voxelIndex.y & 15, voxelIndex.y >> 4);
    }

    ivec3 GetVoxelIndex(ivec2 storagePos) {
        ivec3 voxelIndex;
        voxelIndex.xz = (storagePos >> 4) - xzRadiusBlocks;
        voxelIndex.y = (storagePos.x & 15) + 16 * (storagePos.y & 15);
        return voxelIndex;
    }

    ivec3 getPreviousVoxelIndex(vec3 playerPos, vec3 cameraPosition, vec3 previousCameraPosition) {
        playerPos += cameraPosition - previousCameraPosition;
        return ivec3(floor(SceneSpaceToVoxelSpace(playerPos, previousCameraPosition)));
    }

    float getLightMult(float skyLmcoord, sampler2D lightmap) {
        vec3 skyLightVal = texture2D(lightmap, vec2(1.0/32.0, skyLmcoord)).rgb;
        vec3 fullLightVal = texture2D(lightmap, vec2(31.0/32.0, skyLmcoord)).rgb;
        return (fullLightVal.r - skyLightVal.r) * Floodfill_SkyLightFactor + (1.0 - Floodfill_SkyLightFactor) * Floodfill_Brightness;
    }

/*
(0.8f, 0.83f, 0.83f, 1f)
(0.86f, 0.37f, 0f, 1f)
(0.65f, 0.18f, 0.62f, 1f)
(0.14f, 0.53f, 0.78f, 1f)
(0.93f, 0.68f, 0.08f, 1f)
(0.37f, 0.66f, 0.1f, 1f)
(0.82f, 0.39f, 0.55f, 1f)
(0.21f, 0.22f, 0.24f, 1f)
(0.48f, 0.48f, 0.44f, 1f)
(0.09f, 0.47f, 0.53f, 1f)
(0.39f, 0.12f, 0.6f, 1f)
(0.17f, 0.18f, 0.56f, 1f)
(0.38f, 0.23f, 0.13f, 1f)
(0.28f, 0.35f, 0.14f, 1f)
(0.55f, 0.13f, 0.13f, 1f)
*/

    const vec3[] lightColors = vec3[](
        vec3(1.0, 0.85, 0.6),
        vec3(1.0, 0.7, 0.2),
        vec3(1.0, 0.5, 0.0),
        vec3(1.0, 0.3, 0.1),
        vec3(0.8, 0.2, 1.0),
        vec3(0.2, 0.7, 1.0),
        vec3(0.9, 0.9, 1.0),
        vec3(1.0, 1.0, 1.0),
        vec3(1.0, 0.7, 0.0),
        vec3(1.0, 0.0, 0.5),
        vec3(0.3, 0.7, 1.0),
        vec3(1.0, 1.0, 0.0),
        vec3(0.7, 1.0, 0.0),
        vec3(1.0, 0.5, 0.5),
        vec3(0.6, 0.6, 0.6),
        vec3(0.85, 0.85, 0.85),
        vec3(0.0, 1.0, 0.9),
        vec3(0.7, 0.0, 1.0),
        vec3(0.5, 0.5, 1.0),
        vec3(0.7, 0.5, 0.1),
        vec3(0.3, 1.0, 0.2),
        vec3(1.0, 0.3, 0.3),
        vec3(0.4, 0.4, 0.4),
        vec3(0.8, 0.3, 0.6),
        vec3(0.7, 1.0, 1.0),
        vec3(0.5, 0.6, 0.3),
        vec3(0.3, 0.3, 0.3),
        vec3(0.7, 1.0, 0.8),
        vec3(1.0, 0.7, 0.9),
        vec3(0.3, 0.53, 0.49),
        vec3(1.0, 0.7, 0.2),
        vec3(0.4, 0.3, 0.1),
        vec3(0.6, 1.0, 0.7),
        vec3(0.7, 0.05, 0.2),
        vec3(0.7, 0.48, 0.05),
        vec3(0.7, 0.6, 0.05),
        vec3(0.4, 0.7, 0.1),
        vec3(0.3, 0.5, 0.7),
        vec3(0.1, 0.3, 0.7),
        vec3(0.7, 0.05, 0.5),
        vec3(0.6, 0.6, 0.6),
        vec3(0.3, 0.3, 0.3),
        vec3(0.3, 0.3, 0.3),
        vec3(1.0, 0.9, 0.6),
        vec3(0.87f, 0.85f, 0.54f),
        vec3(0.73, 0.4, 0.2),
        vec3(0.65f, 0.63f, 0.87f),
        vec3(0.62f, 0.78f, 0.85f),
        vec3(1.0, 0.3, 0.1) * 1/15.0,
        vec3(1.0, 0.3, 0.1) * 2/15.0,
        vec3(1.0, 0.3, 0.1) * 3/15.0,
        vec3(1.0, 0.3, 0.1) * 4/15.0,
        vec3(1.0, 0.3, 0.1) * 5/15.0,
        vec3(1.0, 0.3, 0.1) * 6/15.0,
        vec3(1.0, 0.3, 0.1) * 7/15.0,
        vec3(1.0, 0.3, 0.1) * 8/15.0,
        vec3(1.0, 0.3, 0.1) * 9/15.0,
        vec3(1.0, 0.3, 0.1) * 10/15.0,
        vec3(1.0, 0.3, 0.1) * 11/15.0,
        vec3(1.0, 0.3, 0.1) * 12/15.0,
        vec3(1.0, 0.3, 0.1) * 13/15.0,
        vec3(1.0, 0.3, 0.1) * 14/15.0,
        vec3(1.0, 0.3, 0.1)
    );

    vec3 getLightColor(ivec2 storagePos, sampler2D lightSampler) {
        vec3 maxLight = vec3(0.0);

        maxLight = max(maxLight, texelFetch(lightSampler, storagePos + ivec2( 0, 16), 0).rgb);
        maxLight = max(maxLight, texelFetch(lightSampler, storagePos + ivec2( 0,-16), 0).rgb);
        maxLight = max(maxLight, texelFetch(lightSampler, storagePos + ivec2( 16, 0), 0).rgb);
        maxLight = max(maxLight, texelFetch(lightSampler, storagePos + ivec2(-16, 0), 0).rgb);

        ivec2 rowStart = (storagePos >> 4) * 16;
        int yIndex = storagePos.x - rowStart.x + 16 * (storagePos.y - rowStart.y);

        ivec2 storagePosY = rowStart + ivec2((yIndex + 1) & 15, ((yIndex + 1) >> 4));
        maxLight = max(maxLight, texelFetch(lightSampler, storagePosY, 0).rgb);

        storagePosY = rowStart + ivec2((yIndex - 1) & 15, (yIndex - 1) >> 4);
        maxLight = max(maxLight, texelFetch(lightSampler, storagePosY, 0).rgb);

        return clamp(maxLight - 1.0/16.0, 0.0, 1.0);
    }

#endif