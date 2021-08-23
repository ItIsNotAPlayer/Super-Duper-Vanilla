vec4 complexShadingGbuffers(matPBR material, positionVectors posVector, vec3 dither){
	#if defined USE_SKY_LIGHTMAP
		material.light_m.y = (material.light_m.y * SKY_LIGHT_AMOUNT) / 0.95;
	#else
		material.light_m.y = SKY_LIGHT_AMOUNT;
	#endif

	// Get positions
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nNegEyePlayerPos = normalize(-posVector.eyePlayerPos);

	#if !defined ENABLE_LIGHT
		vec3 directLight = vec3(0);
	#else
		#if defined ENTITIES_GLOWING || !defined SHD_ENABLE
			// Get direct light diffuse color
			vec3 directLight = getDiffuse(material.normal_m, nLightPos, material.ss_m) * smoothstep(0.98, 0.99, material.light_m.y) * material.light_m.y * lightCol;
		#else
			// Cave fix
			float caveFixShdFactor = smoothstep(0.2, 0.4, material.light_m.y) * (1.0 - eyeBrightFact) + eyeBrightFact;
			// Get direct light diffuse color
			vec3 directLight = getShdMapping(posVector.shdPos, material.normal_m, nLightPos, dither.r, material.ss_m) * caveFixShdFactor * lightCol;
		#endif
	#endif

	// Get globally illuminated sky
	vec3 GISky = ambientLighting + getSkyRender(material.normal_m, lightCol, 0.0, false) * material.light_m.y * material.light_m.y;

	// Get fresnel
	vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nNegEyePlayerPos),
		material.metallic_m == 1 ? material.albedo_t.rgb : vec3(material.metallic_m));
	
	vec3 specCol = vec3(0);
	vec3 reflectedSkyRender = vec3(0);

	if(material.roughness_m != 1){
		#ifdef ENABLE_LIGHT
			// Get specular GGX
			if(maxC(directLight) > 0 && material.roughness_m != 1) specCol = getSpecGGX(nNegEyePlayerPos, nLightPos, normalize(posVector.lightPos - posVector.eyePlayerPos), material.normal_m, fresnel, material.roughness_m) * directLight;
		#endif
		
		reflectedSkyRender = ambientLighting + getSkyRender(reflect(posVector.eyePlayerPos, material.normal_m), directLight, 1.0, material.light_m.y >= 0.95) * material.light_m.y;
	}

	// Mask reflections
	vec3 reflectCol = reflectedSkyRender * material.ambient_m; // Will change this later...

	#ifdef ENABLE_LIGHT
		float rainDiff = isEyeInWater == 1 ? 0.2 : rainStrength * 0.5;
		directLight = directLight * (1.0 - rainDiff) + material.light_m.y * rainDiff;
	#endif

	#ifdef WATER
		float greyFresnel = maxC(fresnel);
		material.albedo_t.a = material.albedo_t.a * (1.0 - greyFresnel) + greyFresnel;
	#endif
 
	vec3 totalDiffuse = (directLight + GISky * material.ambient_m + cubed(material.light_m.x) * BLOCK_LIGHT_COL * pow(material.ambient_m, 1.0 / 4.0));
	return vec4(mix(material.albedo_t.rgb * totalDiffuse, reflectCol, fresnel * squared(1.0 - material.roughness_m)) + specCol + material.albedo_t.rgb * material.emissive_m, material.albedo_t.a);
}