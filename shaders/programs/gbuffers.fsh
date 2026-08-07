// #version 420 compatibility

#include "/lib/psx_util.glsl"
#include "/lib/voxel.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D colortex11;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform int isEyeInWater;
uniform bool inNether;
uniform bool inEnd;
uniform ivec2 atlasSize;

#ifdef gbuffers_beaconbeam
    #define alphaTestVal 0.9
#else
    uniform float alphaTestRef;
    #define alphaTestVal alphaTestRef
#endif

#include "/lib/fog.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 color;
in vec3 viewPos;

#ifdef gbuffers_water
    uniform sampler2D colortex10;
    uniform sampler2D depthtex1;
    uniform mat4 gbufferProjectionInverse;
    uniform float viewWidth;
    uniform float viewHeight;

    in float isWaterBackface;
#endif

#ifdef gbuffers_block
    uniform int blockEntityId;
    in float isText;
#endif

#ifdef gbuffers_entities
    uniform vec4 entityColor;
    uniform ivec4 blendFunc;
    uniform float frameTimeCounter;
    uniform int entityId;
#endif

#ifdef gbuffers_hand
    uniform int heldItemId;
    uniform int heldItemId2;
#endif

#ifdef affine_mapping
    in vec3 texcoordAffine;
#endif

#if Floodfill > 0
	in vec3 voxelLightColor;
#endif

/* RENDERTARGETS: 10,1 */
layout(location = 0) out vec4 colorOut;
layout(location = 1) out vec4 textOut;

void main() {

	#ifdef affine_mapping
		#ifdef affine_clamp_enabled
			vec2 texcoordAdjusted = AffineMapping(texcoordAffine, texcoord, 1.0 / atlasSize, affine_clamp);
		#else
			vec2 texcoordAdjusted = texcoordAffine.xy / texcoordAffine.z;
		#endif

        #ifdef gbuffers_block
            if(isText > 0.5) {
                texcoordAdjusted = texcoord;
            }
        #endif
	#else 
		vec2 texcoordAdjusted = texcoord;
	#endif

    colorOut = texture2D(gtexture, texcoordAdjusted) * color;
    if (colorOut.a < alphaTestVal) discard;

    #ifdef gbuffers_entities
        // Lightning
        if(entityId == 10001) {
            colorOut = vec4(1.0);
            textOut = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
    #endif

	#if Floodfill > 0
		vec4 lighting = vec4(voxelLightColor, 0.0);
        vec2 lightCoords = vec2(1.0/32.0, lmcoord.y);

        #if defined gbuffers_block
            // make glowing sign text glow
            if(isText > 0.5 && lmcoord.x == 249.0/255.0)
                lightCoords.x = lmcoord.x;
        #elif defined gbuffers_entities
            // make glow item frames glow
			if(entityId == 10008)
				lightCoords.x = lmcoord.x;
        #endif

		lighting += (texture2D(lightmap, lightCoords) * 0.8 + 0.2);
	#else
		vec4 lighting = texture2D(lightmap, lmcoord) * 0.8 + 0.2;
	#endif

    #ifdef gbuffers_entities
        colorOut.rgb = mix(colorOut.rgb, entityColor.rgb, entityColor.a);

        if(entityId == 10003) {
			lighting.rgb += mix(vec3(item_darkColor), vec3(item_lightColor), sin(frameTimeCounter * item_speed) * 0.5 + 0.5);
		}
    #endif

    colorOut *= lighting;


    #ifdef Use_Player_Ignore_Post
        #if defined gbuffers_block
		    if(blockEntityId == 10002)
        #elif defined gbuffers_entities
            if(entityId == 10002)
        #elif defined gbuffers_hand
            if(heldItemId == 10002 || (heldItemId2 == 10002 && atlasSize.x == 0))
        #endif
        {
            vec3 hsv = rgb2hsv(colorOut.rgb);
            hsv.y /= saturation;
            colorOut.rgb = hsv2rgb(hsv);

            colorOut.rgb = (colorOut.rgb - 0.5) * (1.0/contrast) + 0.5;
        }
	#endif

    #ifdef gbuffers_water
        if (isWaterBackface > 0.5) {
            vec3 oldCol = texelFetch(colortex10, ivec2(gl_FragCoord.xy), 0).rgb;
            float oldDepth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r;
            vec3 oldFogCol = getFogColor(1, vec3(0.0), vec3(0.0));
            // vec3 oldFogCol = vec3(10.0);

            vec3 oldViewPos = screenToView(gl_FragCoord.xy / vec2(viewWidth, viewHeight), oldDepth, gbufferProjectionInverse);
            float oldFogDepth = getFogDepth(oldViewPos, oldDepth, 1, near, far);
            oldCol = mix(oldCol, oldFogCol, oldFogDepth);
            // oldCol = oldFogCol;

            colorOut = vec4(oldCol, 1.0);
        }
    #endif

    #ifndef gbuffers_hand
        float fogDepth = getFogDepth(viewPos, gl_FragCoord.z, isEyeInWater, near, far);

        #ifdef gbuffers_entities
            if(entityId == 10006 && blendFunc.x == 1) {
                colorOut.rgb *= 1.0-fogDepth;
            }
            else {
                vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
                colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
            }
        #else
            vec3 fogCol = texelFetch(colortex11, ivec2(gl_FragCoord.xy), 0).rgb;
            colorOut.rgb = mix(colorOut.rgb, fogCol, fogDepth);
        #endif
    #endif
	
    #if defined gbuffers_block
        textOut = vec4(isText, 0.0, 0.0, 1.0);
    #elif defined gbuffers_textured || defined gbuffers_beaconbeam
        textOut = vec4(0.0, 1.0, 0.0, 1.0);
    #else
	    textOut = vec4(0.0, 0.0, 0.0, 1.0);
    #endif
}
