#ifndef FOG_GLSL
#define FOG_GLSL

#include "/shaders.settings"
#include "/lib/psx_util.glsl"

uniform vec3 sunPosition;
uniform float smoothTemp;
uniform float blindness;

const vec3 NoonHorizonColor = vec3(0.4, 0.5, 1.0);
const vec3 NoonSkyColor = vec3(0, 0.27, 0.95);
const vec3 SunriseHorizonColor = vec3(0.7, 0.6, 0.6);
const vec3 SunriseSkyColor = vec3(0.4, 0.35, 0.75);
const vec3 NightHorizonColor = vec3(0.15);
const vec3 NightSkyColor = vec3(0.0);

const vec3 Rain_NoonHorizonColor = vec3(0.65, 0.65, 0.7);
const vec3 Rain_NoonSkyColor = vec3(0.5, 0.5, 0.7);
const vec3 Rain_SunriseHorizonColor = vec3(0.7, 0.6, 0.6);
const vec3 Rain_SunriseSkyColor = vec3(0.4, 0.35, 0.75);
const vec3 Rain_NightHorizonColor = vec3(0.18, 0.18, 0.23);
const vec3 Rain_NightSkyColor = vec3(0.15, 0.15, 0.2);

const vec3 Snow_NoonHorizonColor = vec3(0.65, 0.65, 0.7);
const vec3 Snow_NoonSkyColor = vec3(0.5, 0.5, 0.7);
const vec3 Snow_SunriseHorizonColor = vec3(0.7, 0.6, 0.6);
const vec3 Snow_SunriseSkyColor = vec3(0.4, 0.35, 0.75);
const vec3 Snow_NightHorizonColor = vec3(0.18, 0.18, 0.23);
const vec3 Snow_NightSkyColor = vec3(0.15, 0.15, 0.2);

const vec3 Blindness_Color = vec3(0.0);

vec3 getOverworldSkyColor(in vec3 viewDir, float sunAngle, vec3 fogColor, vec3 skyColor, float rainStrength, mat4 modelView) {
	float upDot = max(dot(viewDir, modelView[1].xyz), 0.0);
	float mixFactor = smoothstep(0.0, 0.7, upDot);

	vec3 horizonSkyColor;
	vec3 upperSkyColor;
	vec3 rain_horizonSkyColor;
	vec3 rain_upperSkyColor;
	vec3 snow_horizonSkyColor;
	vec3 snow_upperSkyColor;

    if(rainStrength < 1.0) {
        if(sunAngle < 0.1) {
            horizonSkyColor = mix(SunriseHorizonColor, NoonHorizonColor, sunAngle / 0.1);
            upperSkyColor   = mix(SunriseSkyColor, NoonSkyColor, sunAngle / 0.1);
        }
        else if(sunAngle >= 0.1 && sunAngle < 0.4) {
            horizonSkyColor = NoonHorizonColor;
            upperSkyColor   = NoonSkyColor;
        }
        else if(sunAngle >= 0.4 && sunAngle < 0.5) {
            horizonSkyColor = mix(NoonHorizonColor, SunriseHorizonColor, (sunAngle - 0.4) / 0.1);
            upperSkyColor   = mix(NoonSkyColor, SunriseSkyColor, (sunAngle - 0.4) / 0.1);
        }
        else if(sunAngle >= 0.5 && sunAngle < 0.55) {
            horizonSkyColor = mix(SunriseHorizonColor, NightHorizonColor, (sunAngle - 0.5) / 0.05);
            upperSkyColor   = mix(SunriseSkyColor, NightSkyColor, (sunAngle - 0.5) / 0.05);
        }
        else if(sunAngle >= 0.55 && sunAngle < 0.97) {
            horizonSkyColor = NightHorizonColor;
            upperSkyColor   = NightSkyColor;
        }
        else {
            horizonSkyColor = mix(NightHorizonColor, SunriseHorizonColor, (sunAngle - 0.97) / 0.03);
            upperSkyColor   = mix(NightSkyColor, SunriseSkyColor, (sunAngle - 0.97) / 0.03);
        }

    }
    float snowFactor = smoothstep(0.1, 0.0, smoothTemp);
    if(rainStrength > 0.0) {

        if(snowFactor < 1.0) {
            if(sunAngle < 0.1) {
                rain_horizonSkyColor = mix(Rain_SunriseHorizonColor, Rain_NoonHorizonColor, sunAngle / 0.1);
                rain_upperSkyColor   = mix(Rain_SunriseSkyColor, Rain_NoonSkyColor, sunAngle / 0.1);
            }
            else if(sunAngle >= 0.1 && sunAngle < 0.4) {
                rain_horizonSkyColor = Rain_NoonHorizonColor;
                rain_upperSkyColor   = Rain_NoonSkyColor;
            }
            else if(sunAngle >= 0.4 && sunAngle < 0.5) {
                rain_horizonSkyColor = mix(Rain_NoonHorizonColor, Rain_SunriseHorizonColor, (sunAngle - 0.4) / 0.1);
                rain_upperSkyColor   = mix(Rain_NoonSkyColor, Rain_SunriseSkyColor, (sunAngle - 0.4) / 0.1);
            }
            else if(sunAngle >= 0.5 && sunAngle < 0.55) {
                rain_horizonSkyColor = mix(Rain_SunriseHorizonColor, Rain_NightHorizonColor, (sunAngle - 0.5) / 0.05);
                rain_upperSkyColor   = mix(Rain_SunriseSkyColor, Rain_NightSkyColor, (sunAngle - 0.5) / 0.05);
            }
            else if(sunAngle >= 0.55 && sunAngle < 0.97) {
                rain_horizonSkyColor = Rain_NightHorizonColor;
                rain_upperSkyColor   = Rain_NightSkyColor;
            }
            else {
                rain_horizonSkyColor = mix(Rain_NightHorizonColor, Rain_SunriseHorizonColor, (sunAngle - 0.97) / 0.03);
                rain_upperSkyColor   = mix(Rain_NightSkyColor, Rain_SunriseSkyColor, (sunAngle - 0.97) / 0.03);
            }
        }

        if(snowFactor > 0.0) {
            if(sunAngle < 0.1) {
                snow_horizonSkyColor = mix(Snow_SunriseHorizonColor, Snow_NoonHorizonColor, sunAngle / 0.1);
                snow_upperSkyColor   = mix(Snow_SunriseSkyColor, Snow_NoonSkyColor, sunAngle / 0.1);
            }
            else if(sunAngle >= 0.1 && sunAngle < 0.4) {
                snow_horizonSkyColor = Snow_NoonHorizonColor;
                snow_upperSkyColor   = Snow_NoonSkyColor;
            }
            else if(sunAngle >= 0.4 && sunAngle < 0.5) {
                snow_horizonSkyColor = mix(Snow_NoonHorizonColor, Snow_SunriseHorizonColor, (sunAngle - 0.4) / 0.1);
                snow_upperSkyColor   = mix(Snow_NoonSkyColor, Snow_SunriseSkyColor, (sunAngle - 0.4) / 0.1);
            }
            else if(sunAngle >= 0.5 && sunAngle < 0.55) {
                snow_horizonSkyColor = mix(Snow_SunriseHorizonColor, Snow_NightHorizonColor, (sunAngle - 0.5) / 0.05);
                snow_upperSkyColor   = mix(Snow_SunriseSkyColor, Snow_NightSkyColor, (sunAngle - 0.5) / 0.05);
            }
            else if(sunAngle >= 0.55 && sunAngle < 0.97) {
                snow_horizonSkyColor = Snow_NightHorizonColor;
                snow_upperSkyColor   = Snow_NightSkyColor;
            }
            else {
                snow_horizonSkyColor = mix(Snow_NightHorizonColor, Snow_SunriseHorizonColor, (sunAngle - 0.97) / 0.03);
                snow_upperSkyColor   = mix(Snow_NightSkyColor, Snow_SunriseSkyColor, (sunAngle - 0.97) / 0.03);
            }
        }
    }

    if(rainStrength > 0.0) {
        if(snowFactor == 1.0) {
            rain_horizonSkyColor = snow_horizonSkyColor;
            rain_upperSkyColor = snow_upperSkyColor;
        }
        else if(snowFactor > 0.0) {
            rain_horizonSkyColor = mix(rain_horizonSkyColor, snow_horizonSkyColor, snowFactor);
            rain_upperSkyColor = mix(rain_upperSkyColor, snow_upperSkyColor, snowFactor);
        }

        horizonSkyColor = mix(horizonSkyColor, rain_horizonSkyColor, rainStrength);
        upperSkyColor = mix(upperSkyColor, rain_upperSkyColor, rainStrength);
    }

    horizonSkyColor = mix(horizonSkyColor, Blindness_Color, blindness);
    upperSkyColor = mix(upperSkyColor, Blindness_Color, blindness);


	return mix(horizonSkyColor, upperSkyColor, mixFactor);
}

float getFogDepth(in vec3 viewPos, in float depth1, int isEyeInWater, float near, float far) {
    #if fog_depth_type == 0
		float depth = linearizeDepthFast(depth1, near, far);
	#elif fog_depth_type == 1
		float depth = length(viewPos);
	#elif fog_depth_type == 2
		float depth = length((gbufferModelViewInverse * vec4(viewPos, 1.0)).xz);
	#endif

    float fogDistance;
    float fogSlope;
        
    if(isEyeInWater == 0) {
        if(inNether) {
            fogDistance = fog_distance_nether;
            fogSlope = fog_slope_nether;
        }
        else if(inEnd) {
            fogDistance = fog_distance_end;
            fogSlope = fog_slope_end;
        }
        else {
            if(rainStrength == 0.0) {
                fogDistance = fog_distance;
                fogSlope = fog_slope;
            }
            else if(rainStrength == 1.0) {
                fogDistance = fog_distance_rain;
                fogSlope = fog_slope_rain;
            }
            else {
                fogDistance = mix(fog_distance, fog_distance_rain, rainStrength);
                fogSlope = mix(fog_slope, fog_slope_rain, rainStrength);
            }
        }
    }
    else if(isEyeInWater == 1) {
        fogDistance = fog_distance_water;
        fogSlope = fog_slope_water;
    }
    else if(isEyeInWater == 2) {
        fogDistance = fog_distance_lava;
        fogSlope = fog_slope_lava;
    }
    else if(isEyeInWater == 3) {
        fogDistance = fog_distance_snow;
        fogSlope = fog_slope_snow;
    }

    fogDistance = mix(fogDistance, fog_distance_blind, blindness);
    fogSlope = mix(fogSlope, fog_slope_blind, blindness);

    return clamp01((depth - fogDistance) / fogSlope);
}

float fogCaveFactor(float eyeAltitude, float eyeBrightness, sampler2D moodTex) {
    #if fog_Darken_Mode == 1
        return smoothstep(54.0, 58.0, eyeAltitude);
    #elif fog_Darken_Mode == 2
        return smoothstep(15, 30, eyeBrightness);
    #elif fog_Darken_Mode == 3
        return texelFetch(moodTex, ivec2(0), 0).a;
    #else
        return 1.0;
    #endif
}

vec3 getFogColor(int isEyeInWater, vec3 skyFogCol, vec3 fogColor) {
    vec3 returnFogCol;

    if(isEyeInWater == 0) {
        returnFogCol = skyFogCol;
    }
    else if(isEyeInWater == 1) {
        returnFogCol = vec3(0.1, 0.1, 1.0);
    }
    else if(isEyeInWater == 2) {
        returnFogCol = vec3(2.0, 0.4, 0.1);
    }
    else if(isEyeInWater == 3) {
        returnFogCol = vec3(1.0);
    }

    return mix(returnFogCol, Blindness_Color, blindness);
}

#endif