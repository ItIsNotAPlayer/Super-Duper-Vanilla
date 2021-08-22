vec3 complexShadingDeferred(matPBR material, positionVectors posVector, vec3 sceneCol, vec3 dither){
	// Get positions
    vec3 nEyePlayerPos = normalize(-posVector.eyePlayerPos);

	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = getSSGICol(posVector.viewPos, posVector.clipPos, gBMVNorm, toRandPerFrame(dither.xy));
	#else
		vec3 GIcol = vec3(0);
	#endif

	// Get fresnel
	vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nEyePlayerPos),
		material.metallic_m == 1 ? material.albedo_t.rgb : vec3(material.metallic_m));

	// If roughness is 1, don't do reflections
	vec4 SSRCol = vec4(0);
	#ifdef SSR
		#ifdef ROUGH_REFLECTIONS
			SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos,
				gBMVNorm + (dither * 2.0 - 1.0) * squared(material.roughness_m * material.roughness_m));
		#else
			SSRCol = getSSRCol(posVector.viewPos, posVector.clipPos, gBMVNorm);
		#endif
	#endif

	vec3 mask = fresnel * SSRCol.a * squared(1.0 - material.roughness_m);
	return mix(sceneCol + material.albedo_t.rgb * GIcol, SSRCol.rgb, mask) + material.albedo_t.rgb * material.emissive_m * mask;
}