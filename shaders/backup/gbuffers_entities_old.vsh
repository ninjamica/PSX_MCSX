#version 420 compatibility

#define gbuffers_solid
#define gbuffers_entities
#include "/shaders.settings"
#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

varying vec2 texcoord;
varying vec3 texcoordAffine;
varying vec2 lmcoord;
varying vec4 color;
varying vec3 viewPos;

attribute vec2 mc_midTexCoord;
attribute vec4 at_tangent;

uniform ivec2 atlasSize;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int entityId;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform int frameCounter;

#if Floodfill > 0
	varying vec3 voxelLightColor;
	writeonly layout (rgba8) uniform image2D colorimg3;
	writeonly layout (rgba8) uniform image2D colorimg4;
	readonly layout (rgba8) uniform image2D colorimg5;
#endif


void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	color = gl_Color;

	#ifdef disable_sheepColor
	if(entityId == 10005)
		color.rgb = vec3(1.0);
	#endif

	#ifdef remove_nameplate
	if(gl_Color.rgb == vec3(0.0) && gl_Color.a > 0.50 && gl_Color.a < 0.51) {
		color = vec4(0.0);
	}
	#endif
	
	vec2 halfTexSize = abs(texcoord - mc_midTexCoord);
	vec4 cornerColor = texture2D(gtexture, mc_midTexCoord - vec2(-1.0, 1.0) * halfTexSize + 0.5 / atlasSize);
	
	vec4 vertexPos = gl_Vertex;

	// Billboarding for falling dripstone
	#ifdef Billboarding
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

	viewPos = (gl_ModelViewMatrix * vertexPos).xyz;
	vec4 ftrans = gl_ProjectionMatrix * vec4(viewPos, 1.0);
	float depth = clamp(ftrans.w, 0.001, 1000.0);
	float sqrtDepth = sqrt(depth);
	
	vec4 position4 = mat4(gl_ModelViewMatrix) * vertexPos + gl_ModelViewMatrix[3].xyzw;
	vec3 position = PixelSnap(position4, vertex_inaccuracy_entities / sqrtDepth).xyz;
	
	float wVal = (mat3(gl_ProjectionMatrix) * position).z;
	wVal = clamp(wVal, 0.0, 10000.0);
	texcoordAffine = vec3(texcoord * wVal, wVal);

	if (atlasSize.x > 0)
		texcoordAffine.xy -= sign(mc_midTexCoord - texcoord) * 0.001/atlasSize;
	else
		texcoordAffine.xy += sign(mc_midTexCoord - texcoord) * 0.00001;
	
	gl_Position = gl_ProjectionMatrix * vec4(position, 1.0);



	// Voxelization
	#if Floodfill > 0
		vec2 centerDir = sign(mc_midTexCoord - texcoord);
		vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
		vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
		vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
		vec3 bitangent = cross(normal, tangent) * sign(-at_tangent.w);

		vec3 playerPos = (gbufferModelViewInverse * vec4(viewPos + 0.125*centerDir.x*tangent + 0.125*centerDir.y*bitangent, 1.0)).xyz;
		ivec3 voxelPos = getPreviousVoxelIndex(playerPos, cameraPosition, previousCameraPosition);
		if(IsInVoxelizationVolume(voxelPos)) {
			float lightMult = getLightMult(lmcoord.y, lightmap);
			ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);
			voxelLightColor = imageLoad(colorimg5, voxelIndex).rgb * lightMult;
		}
		else {
			voxelLightColor = vec3(0.0);
		}

		playerPos = (gbufferModelViewInverse * vec4(viewPos + 0.5*centerDir.x*tangent + 0.5*centerDir.y*bitangent, 1.0)).xyz;
		voxelPos = ivec3(floor(SceneSpaceToVoxelSpace(playerPos, cameraPosition)));
		if(gl_VertexID % 4 == 0) {

			if(IsInVoxelizationVolume(voxelPos)) {
				ivec2 voxelIndex = GetVoxelStoragePos(voxelPos);

				if(entityId >= 11000 && entityId < 12000) {
					if (frameCounter % 2 == 0)
						imageStore(colorimg4, voxelIndex, vec4(lightColors[entityId - 11000], 1.0));
					else
						imageStore(colorimg3, voxelIndex, vec4(lightColors[entityId - 11000], 1.0));
				}
				else {
					if(atlasSize.x > 0 && clamp(lmcoord, vec2(15.0/16.0, 0.0), vec2(1.0, 1.0/16.0)) == lmcoord) {
						if (frameCounter % 2 == 0)
							imageStore(colorimg4, voxelIndex, vec4(lightColors[2], 1.0));
						else
							imageStore(colorimg3, voxelIndex, vec4(lightColors[2], 1.0));
					}
				}
			}
		}
	#endif
}
