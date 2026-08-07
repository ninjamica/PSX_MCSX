// #version 420 compatibility

#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"


uniform sampler2D lightmap;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform ivec2 atlasSize;
uniform int frameCounter;

in vec4 at_tangent;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 color;
out vec3 viewPos;

#ifdef gbuffers_terrain
    in vec4 mc_Entity;
    in vec3 at_midBlock;
#endif

#ifdef gbuffers_water
    uniform float frameTimeCounter;
    out float isWaterBackface;
#endif

#ifdef gbuffers_block
    uniform int blockEntityId;
    out float isText;
#endif

#ifdef gbuffers_entities
    uniform mat4 gbufferModelView;
    uniform int entityId;

    #ifdef Billboarding
        uniform sampler2D gtexture;
    #endif
#endif

#ifdef gbuffers_hand
    uniform float aspectRatio;
    uniform int heldItemId;
    uniform int heldItemId2;
#endif

#ifdef gbuffers_armor_glint
    uniform int renderStage;
#endif

#ifdef affine_mapping
    out vec3 texcoordAffine;
#endif

#if Floodfill > 0
	readonly layout (rgba8) uniform image2D colorimg5;
	out vec3 voxelLightColor;
#endif

#ifdef Floodfill_Write
    #ifdef gbuffers_water
        layout (rgba8) uniform image2D colorimg3;
        layout (rgba8) uniform image2D colorimg4;
    #else
        writeonly layout (rgba8) uniform image2D colorimg3;
        writeonly layout (rgba8) uniform image2D colorimg4;
    #endif
#endif


void main() {

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;
	
	vec4 vertexPos = gl_Vertex;

    // Fixes for specific objects
    #ifdef gbuffers_block
        isText = float(blockEntityId == 10920 && atlasSize.x == 0);
    #endif

    #ifdef gbuffers_entities
        #ifdef disable_sheepColor
        if(entityId == 10005)
            color.rgb = vec3(1.0);
        #endif
        #ifdef remove_nameplate
        if(gl_Color.rgb == vec3(0.0) && gl_Color.a > 0.50 && gl_Color.a < 0.51) {
            color = vec4(0.0);
        }
        #endif

        // fix entity shadow
        if(entityId == 10009)
            vertexPos.xyz += 0.02 * gbufferModelView[1].xyz;
	#endif

    #ifdef gbuffers_damagedblock
        vertexPos.xyz += 0.1 * gl_Normal;
    #endif

    // Billboarding / vertex offsets
    #if defined gbuffers_water
        int blockID = int(mc_Entity.x + 0.5);
        if(blockID == 10001) {
            vertexPos.y += water_wave_height * sin(water_wave_speed * frameTimeCounter + water_wave_length * (cos(water_wave_angle) * (vertexPos.x + cameraPosition.x) + sin(water_wave_angle) * (vertexPos.z + cameraPosition.z)));
        }
        else if(blockID == 11030) {
            vertexPos.y += lava_wave_height * sin(lava_wave_speed * frameTimeCounter + lava_wave_length * (cos(lava_wave_angle) * (vertexPos.x + cameraPosition.x) + sin(lava_wave_angle) * (vertexPos.z + cameraPosition.z)));
        }

        // "Fixes" z fighting with waterlogged blocks
        vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
        vertexPos.xyz += normal * -0.001;
    #elif defined gbuffers_terrain
        int blockID = int(mc_Entity.x + 0.5);
        
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
    #elif defined gbuffers_entities
        // Billboarding for falling dripstone
        #ifdef Billboarding
            vec2 halfTexSize = abs(texcoord - mc_midTexCoord);
            vec4 cornerColor = texture2D(gtexture, mc_midTexCoord - vec2(-1.0, 1.0) * halfTexSize + 0.5 / atlasSize);
            
            if(entityId == 10004 && cornerColor == vec4(0.0, 123.0/255.0, 1.0, 25.0/255.0)) {
                vec3 playerPos = (gbufferModelViewInverse * vertexPos).xyz;

                vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * sign(at_tangent.w) * atlasSize.x / 16.0, 0.0);
                vec2 centerPos = playerPos.xz - 1.3 * facePos.x * normalize(mat3(gbufferModelViewInverse) * at_tangent.xyz).xz * sign(at_tangent.w);

                vec2 viewVec = normalize(gbufferModelViewInverse[2].xz);
                mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
                playerPos.xz = (rotationMatrix * facePos) + centerPos;

                vertexPos = gbufferModelView * vec4(playerPos, 1.0);
            }
            else if(entityId == 10007 && atlasSize.x > 0) {
                vec3 playerPos = (gbufferModelViewInverse * vertexPos).xyz;

                vec2 facePos = vec2((texcoord.x - mc_midTexCoord.x) * sign(at_tangent.w) * atlasSize.x / 16.0, 0.0);
                vec2 centerPos = playerPos.xz - 1.3 * facePos.x * normalize(mat3(gbufferModelViewInverse) * at_tangent.xyz).xz * sign(at_tangent.w);

                vec2 viewVec = normalize(gbufferModelViewInverse[2].xz);
                mat2 rotationMatrix = mat2(vec2(viewVec.y, -viewVec.x), vec2(viewVec.x, viewVec.y));
                playerPos.xz = (rotationMatrix * facePos) + centerPos;

                vertexPos = gbufferModelView * vec4(playerPos, 1.0);
            }
        #endif
    #endif
	
	
	viewPos = (gl_ModelViewMatrix * vertexPos).xyz;

    #if defined gbuffers_hand && defined aspectRatio_fix
		if(!(heldItemId == 10001 && heldItemId2 != heldItemId) && abs(viewPos.x) > 0.2)
			viewPos.x -= sign(viewPos.x) * 0.13 * clamp01((aspectRatio - 1.7) / (1.0 - 1.7)) * gl_Vertex.w;
	#endif

    #ifdef PixelSnap_ViewSpace
        #ifdef gbuffers_armor_glint
            if (renderStage == MC_RENDER_STAGE_HAND_SOLID) {
                if(gl_VertexID < 4 || gl_VertexID > 8) {
                    gl_Position = vec4(-10.0);
                    return;
                }
                viewPos = PixelSnap(vec4(viewPos, 1.0), vertex_inaccuracy_hand).xyz;
            }
            else {
                viewPos = PixelSnap(vec4(viewPos, 1.0), vertex_inaccuracy_entities).xyz;
            }
        #else
            viewPos = PixelSnap(vec4(viewPos, 1.0), vertex_inaccuracy).xyz;
        #endif
    #endif

	vec4 clipPos = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	float depth = clamp(clipPos.w, 0.001, 1000.0);
	float sqrtDepth = sqrt(depth);

    // TODO: check if how entities does this should be implemented here
    vec4 clipPosAdjusted = clipPos;

    #ifdef PixelSnap_ClipSpace
        #ifdef gbuffers_hand
            if(heldItemId != 10001 && heldItemId2 != 10001)
        #endif
                clipPosAdjusted = PixelSnap(clipPos, vertex_inaccuracy / sqrtDepth);
    #endif
	

    #ifdef affine_mapping
        float wVal = (mat3(gl_ProjectionMatrix) * clipPosAdjusted.xyz).z;
        wVal = clamp(wVal, -10000.0, 0.0);
        texcoordAffine = vec3(texcoord * wVal, wVal);
        
        if (atlasSize.x > 0)
            texcoordAffine.xy -= sign(mc_midTexCoord - texcoord) * 0.001/atlasSize;
        else
            texcoordAffine.xy += sign(mc_midTexCoord - texcoord) * 0.00001;
    #endif

    #ifdef gbuffers_block
        if(isText > 0.5) {
            clipPosAdjusted = clipPos;
            clipPosAdjusted.z -= 0.005;
            
            #ifdef affine_mapping
                texcoordAffine.xy = texcoord;
            #endif
        }
    #endif

	gl_Position = clipPosAdjusted;


	// Voxelization
	#if Floodfill > 0

        #if defined gbuffers_terrain
		    vec3 centerPos = gl_Vertex.xyz + at_midBlock/64.0;
        #elif defined gbuffers_block || defined gbuffers_entities
            vec2 centerDir = sign(mc_midTexCoord - texcoord);
            vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
            vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
            vec3 bitangent = cross(normal, tangent) * sign(-at_tangent.w);

            #if defined gbuffers_block
                vec3 centerPos = (gbufferModelViewInverse * vec4(viewPos + 0.5*normal + 0.01*centerDir.x*tangent + 0.01*centerDir.y*bitangent, 1.0)).xyz;
            #elif defined gbuffers_entities
                vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
                vec3 centerPos = (gbufferModelViewInverse * vec4(viewPos + 0.125*centerDir.x*tangent + 0.125*centerDir.y*bitangent, 1.0)).xyz;
            #endif
        #elif defined gbuffers_textured || defined gbuffers_beaconbeam
            vec3 centerPos = (gbufferModelViewInverse * clipPos).xyz;
        #elif defined gbuffers_hand
            vec3 centerPos = vec3(0.0);
        #endif

		ivec3 voxelPos = getPreviousVoxelIndex(centerPos, cameraPosition, previousCameraPosition);

        #ifdef gbuffers_terrain
            if(all(greaterThan(abs(at_midBlock), vec3(27.0))) && any(equal(gl_Normal * sign(at_midBlock), vec3(-1.0)))) {
                voxelPos += ivec3(gl_Normal.xyz);
            }
        #endif

		if(IsInVoxelizationVolume(voxelPos)) {
			float lightMult = getLightMult(lmcoord.y, lightmap);
			ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
			voxelLightColor = imageLoad(colorimg5, voxelIndex).rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}

        // TODO: make sure to add this define to programs
        #ifdef Floodfill_Write
            #if defined gbuffers_water
            if(gl_VertexID % 4 == 0 && (blockID >= 11000 && blockID < 12000)) {
            #elif defined gbuffers_terrain
            if(gl_VertexID % 4 == 0 && (blockID < 10900 || (blockID >= 11000 && blockID < 12000) || blockID == 10921)) {
            #elif defined gbuffers_block
            if(gl_VertexID % 4 == 0 && blockEntityId >= 11000 && blockEntityId < 12000) {
                centerPos = (gbufferModelViewInverse * vec4(viewPos - 0.5*normal + 0.01*centerDir.x*tangent + 0.01*centerDir.y*bitangent, 1.0)).xyz;
            #elif defined gbuffers_entities
            if(gl_VertexID % 4 == 0) {
                centerPos = (gbufferModelViewInverse * vec4(viewPos + 0.5*centerDir.x*tangent + 0.5*centerDir.y*bitangent, 1.0)).xyz;
            #endif
                voxelPos = ivec3(floor(SceneSpaceToVoxelSpace(centerPos, cameraPosition)));
                if(IsInVoxelizationVolume(voxelPos)) {
                    ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);

                    #if defined gbuffers_terrain
                        #ifdef gbuffers_water
                            vec4 lightVal = vec4(0.0, 0.0, 0.0, 0.75);
                        #else
                            vec4 lightVal = vec4(0.0, 0.0, 0.0, 0.5);
                        #endif

                        if(blockID >= 11000) {
                            lightVal = vec4(lightColors[blockID - 11000], 1.0);
                        }
                        #ifndef gbuffers_water
                        else if(blockID == 10921) {
                            lightVal = vec4(0.0, 0.0, 0.0, 0.75);
                        }
                        #endif
                    #elif defined gbuffers_block
                        vec4 lightVal = vec4(lightColors[blockEntityId - 11000], 1.0);
                    #elif defined gbuffers_entities
                        bool writeToMap = false;
                        vec4 lightVal;

                        if(entityId >= 11000 && entityId < 12000) {
                            writeToMap = true;
                            lightVal = vec4(lightColors[entityId - 11000], 1.0);
                        }
                        else if(atlasSize.x > 0 && clamp(lmcoord, vec2(15.0/16.0, 0.0), vec2(1.0, 1.0/16.0)) == lmcoord) {
                            writeToMap = true;
                            lightVal = vec4(lightColors[2], 1.0);
                        }
                    #endif

                    #ifdef gbuffers_entities
                    if (writeToMap) {
                    #endif
                        if (frameCounter % 2 == 0)
                            imageStore(colorimg4, voxelIndex, lightVal);
                        else
                            imageStore(colorimg3, voxelIndex, lightVal);
                    #ifdef gbuffers_entities
                    }
                    #endif
                }
            }
        #endif

        #ifdef gbuffers_water
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

        #ifdef gbuffers_block
            if(isText > 0.5 && lmcoord.x > 15.0/16.0) {
                lmcoord.y = 1.0;
                voxelLightColor = vec3(0.5);
            }
        #endif
	#endif
}
