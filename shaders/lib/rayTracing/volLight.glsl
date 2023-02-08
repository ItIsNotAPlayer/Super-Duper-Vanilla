#ifdef VOL_LIGHT
#endif

vec3 getVolumetricLight(in vec3 feetPlayerPos, in float depth, in float dither){
	// Return 0 if volumetric brightness is 0
	if(VOL_LIGHT_BRIGHTNESS == 0) return vec3(0);

	float feetPlayerDist = length(feetPlayerPos);

	vec3 nFeetPlayerPos = feetPlayerPos / feetPlayerDist;

	#ifdef FORCE_DISABLE_WEATHER
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY : FOG_TOTAL_DENSITY * TAU;
    #else
        float totalFogDensity = isEyeInWater == 0 ? FOG_TOTAL_DENSITY * (rainStrength * PI + 1.0) : FOG_TOTAL_DENSITY * TAU;
    #endif

	float heightFade = 1.0;

	// Fade VL, but do not apply to underwater VL
	if(isEyeInWater != 1 && nFeetPlayerPos.y > 0){
		heightFade = 1.0 - squared(nFeetPlayerPos.y);
		heightFade = depth == 1 ? squared(squared(heightFade * heightFade)) : heightFade * heightFade;

		#ifndef FORCE_DISABLE_WEATHER
			heightFade += (1.0 - heightFade) * rainStrength * 0.5;
		#endif
	}

	// Border fog
	// Modified Complementary border fog calculation, thanks Emin!
	#ifdef BORDER_FOG
		float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity - exp2(feetPlayerDist / far * 21.0 - 18.0));
	#else
		float volumetricFogDensity = 1.0 - exp2(-feetPlayerDist * totalFogDensity);
	#endif

	#if defined VOL_LIGHT && defined SHD_ENABLE
		// Normalize then unormalize with feetPlayerDist and clamping it at minimum distance between far and current shadowDistance
		vec3 endPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * (nFeetPlayerPos * min(min(far, shadowDistance), feetPlayerDist))) * 0.14285714;

		// Apply dithering added to the eyePlayerPos "camera" position converted to shadow clip space
		vec3 startPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * shadowModelView[3].xyz + shadowProjection[3].xyz + endPos * dither;
		
		vec3 rayData = vec3(0);
		for(int x = 0; x < 7; x++){
			// No need to do anymore fancy matrix multiplications during the loop
			rayData += getShdCol(distort(startPos) * 0.5 + 0.5);
			// We continue tracing!
			startPos += endPos;
		}
		
		return lightCol * rayData * (min(1.0, VOL_LIGHT_BRIGHTNESS + VOL_LIGHT_BRIGHTNESS * isEyeInWater) * volumetricFogDensity * heightFade * shdFade * 0.14285714);
	#else
		if(isEyeInWater == 1) return lightCol * toLinear(fogColor) * (min(1.0, VOL_LIGHT_BRIGHTNESS * 2.0) * volumetricFogDensity * heightFade * shdFade);
		else return lightCol * (volumetricFogDensity * heightFade * eyeBrightFact * shdFade * VOL_LIGHT_BRIGHTNESS);
	#endif
}