const float cloudHeight0 = 195.0;

#ifdef DOUBLE_LAYERED_CLOUDS
    const float cloudHeight1 = SECOND_CLOUD_HEIGHT;
#else
    const float cloudHeight1 = 0.0;
#endif

const float cloudThickness0 = 8.0;

// This took me a while to finally understand how this all works
vec2 volumetricClouds(in vec3 feetPlayerPos, in vec3 cameraPos, in float dither, in bool isSky){
    float feetPlayerDot = lengthSquared(feetPlayerPos);
	float feetPlayerDotInvSqrt = inversesqrt(feetPlayerDot);
	float feetPlayerDist = feetPlayerDot * feetPlayerDotInvSqrt;

    vec3 nFeetPlayerPos = feetPlayerPos * feetPlayerDotInvSqrt;

    // Minimum cloud distance
    float cloudFar = far * 8.0;

    float lowerBoundDist = (-cloudThickness0 - cameraPos.y) / nFeetPlayerPos.y;
    float higherBoundDist = (cloudHeight1 - cameraPos.y) / nFeetPlayerPos.y;

    float nearestPlane = max(min(lowerBoundDist, higherBoundDist), 0.0);
	float furthestPlane = min(isSky ? cloudFar : feetPlayerDist, max(lowerBoundDist, higherBoundDist));

    // If the clouds are outside the bounding box, return nothing
    if(furthestPlane < 0) return vec2(0);

    // Calculate cloud steps that dynamically increase with distance
    uint volumetricCloudSteps = min(uint(furthestPlane - nearestPlane), 64u);
    float volumetricCloudStepsInverse = 1.0 / volumetricCloudSteps;

    vec3 lowerPlane = cameraPos + nFeetPlayerPos * nearestPlane;
    vec3 upperPlane = cameraPos + nFeetPlayerPos * furthestPlane;

    // Multiply by volumetricCloudStepsInverse to get the step size
    vec3 endPos = (upperPlane - lowerPlane) * volumetricCloudStepsInverse;

    // Camera position as its start position
    vec3 startPos = lowerPlane + endPos * dither;

    // To store the cloud data for 2 cloud layers
    vec2 clouds = vec2(0);

    // LESSS GOOOOO RAT RACING!!!11!!11!!11!!
    for(uint i = 0u; i < uint(volumetricCloudSteps); i++){
        // Get cloud fog
        float cloudFog = exp2(-exp2(length(startPos - cameraPos) / cloudFar * 21.0 - 18.0));
        // cloudFog = 1.0;

        // Get cloud texture
        vec2 cloudData = texelFetch(colortex0, ivec2(startPos.xz * 0.0625) & 255, 0).xy;

        // First cloud layer
        if(startPos.y <= cloudThickness0){
            float cloudFade = -startPos.y * 0.125;
            // Check if ray is inside a cloud
            if(cloudData.x < 0.5) clouds.x = max(clouds.x, cloudFade * cloudFog);
            if(cloudData.y < 0.5) clouds.y = max(clouds.y, cloudFade * cloudFog);
        }

        #ifdef DOUBLE_LAYERED_CLOUDS
            // Get second cloud height
            float doubleCloudHeightY = startPos.y - 128.0;

            // Second cloud layer
            if(doubleCloudHeightY >= -cloudThickness0){
                float cloudFade = -doubleCloudHeightY * 0.125;
                // Swap to to variate
                if(cloudData.x < 0.5) clouds.y = max(clouds.y, cloudFade * cloudFog);
                if(cloudData.y < 0.5) clouds.x = max(clouds.x, cloudFade * cloudFog);
            }
        #endif

        // Continue tracing
        startPos += endPos;
    }

    // Otherwise, return nothing
    return clouds;
}