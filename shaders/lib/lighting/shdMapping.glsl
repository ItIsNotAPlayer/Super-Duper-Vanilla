vec3 getShdTex(vec3 shdPos){
	float shd0 = shadow2D(shadowtex0, shdPos).x;
	float shd1 = shadow2D(shadowtex1, shdPos).x - shd0;
	
	#ifdef SHD_COL
		return texture2D(shadowcolor0, shdPos.xy).rgb * shd1 * (1.0 - shd0) + shd0;
	#else
		return vec3(shd0);
	#endif
}

vec3 getShdFilter(vec3 shdPos, float dither, float shdRcp){
	dither *= PI2;
	vec2 randVec = vec2(sin(dither), cos(dither)) * shdRcp;

	vec3 shdCol = getShdTex(shdPos);
	shdCol += getShdTex(vec3(shdPos.xy + randVec, shdPos.z));
	shdCol += getShdTex(vec3(shdPos.xy + -randVec, shdPos.z));

	return shdCol * 0.333;
}

// Shadow function
vec3 getShdMapping(vec4 shdPos, vec3 normal, vec3 nLightPos, float dither, float ss){
	#if defined CLOUDS || defined BEACON_BEAM || defined SPIDER_EYES || defined END
		// Light diffuse
		float lightDot = dot(normal, nLightPos) * (1.0 - ss) + ss;

		return vec3(saturate(lightDot) * (1.0 - newTwilight));
	#else
		vec3 shdCol = vec3(0);
		float shdRcp = 1.0 / shadowMapResolution;

		// Light diffuse
		float lightDot = dot(normal, nLightPos) * (1.0 - ss) + ss;
		shdPos.xyz = distort(shdPos.xyz, shdPos.w) * 0.5 + 0.5;
		shdPos.z -= (shdBias + 0.125 * shdRcp) * squared(shdPos.w) / abs(lightDot);

		if(lightDot >= 0)
			#ifdef SHADOW_FILTER
				shdCol = getShdFilter(shdPos.xyz, dither, shdRcp);
			#else
				shdCol = getShdTex(shdPos.xyz);
			#endif

		return shdCol * saturate(lightDot) * (1.0 - newTwilight);
	#endif
}