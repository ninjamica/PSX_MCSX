// #version 420 compatibility

uniform sampler2D colortex5;

#include "/lib/voxel.glsl"

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 dataOut;

void main() {

	ivec2 storagePos = ivec2(gl_FragCoord.xy);

	vec4 light = texelFetch(colortex5, storagePos, 0);

	vec3 propogate = getLightColor(storagePos, colortex5);
	if(light.a > 0.4 && all(equal(light.rgb, vec3(0.0))))
		propogate = vec3(0.0);
		
	light.rgb = (light.a > 0.4) ? (max(light.rgb, propogate)) : (propogate);

	dataOut = light;

}
