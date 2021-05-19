float getStarShape(vec2 st, float size){
    return hermiteMix(0.032, 0.016, max2(abs(st)) / size);
}

float getSunMoonShape(vec3 pos){
    return smoothstep(0.0004, 0.0, length(cubed(pos.xy)));
}

float genStar(vec2 nSkyPos){
	vec3 starRand = getRandTex(nSkyPos, 1).rgb;
    vec2 starGrid = 0.5 * sin(starRand.xy * 12.0 + 128.0) - fract(nSkyPos * noiseTextureResolution) + 0.5;
    return getStarShape(starGrid, starRand.r * 0.9 + 0.3);
}

vec3 getSkyRender(vec3 playerPos, float skyMask, vec3 skyCol, vec3 lightCol){
    // Get positions
    vec3 nPlayerPos = normalize(playerPos);
    vec3 nSkyPos = normalize(mat3(shadowProjection) * (mat3(shadowModelView) * playerPos));

    if(isEyeInWater >= 1){
        float waterVoid = smootherstep(nPlayerPos.y + (eyeBrightFact - 0.56));
        skyCol = mix(fogColor * 0.72, skyCol, waterVoid);
    }
    #ifdef NETHER
        return fogColor;
    #elif defined END
        return fogColor;
    #endif
    
    float skyFogGradient = smoothstep(-0.125, 0.125, nPlayerPos.y);
    float voidGradient = smoothstep(-0.1, -0.05, nPlayerPos.y) * 0.9;
    float lightRange = squared(smootherstep(-nSkyPos.z * 0.56)) * (1.0 - newTwilight);

    // Get sun/moon
    float sunMoon = getSunMoonShape(nSkyPos) * voidGradient;
    vec2 starPos = 0.5 > abs(nSkyPos.y) ? vec2(atan(nSkyPos.x, nSkyPos.z), nSkyPos.y) * 0.25 : nSkyPos.xz * 0.333;
    // Get star
    float star = genStar(starPos * 0.128) * night * voidGradient;

    vec3 fogCol = skyCol * 0.75 * (1.0 - voidGradient) + voidGradient * skyCol;
    return (star + sunMoon * 5.0 + lightRange * lightCol) * skyMask + mix(fogCol, skyCol, skyFogGradient);
}