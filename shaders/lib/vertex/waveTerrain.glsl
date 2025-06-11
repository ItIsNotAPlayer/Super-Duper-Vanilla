// Wave animation movements for shadow
vec3 getTerrainWave(in vec3 vertexShdEyePlayerPos, in vec2 vertexShadowWorldPosXZ, in float midBlockY, in float id, in float outside, in float currTime){
    // Wind affected blocks
    if(WIND_SPEED > 0){
        // Calculate wind strength
        float windStrength = sin(-sumOf(id == 10801 ? floor(vertexShadowWorldPosXZ) : vertexShadowWorldPosXZ) * WIND_FREQUENCY + currTime * WIND_SPEED) * outside;

        // Simple blocks, horizontal movement
        if(id >= 10000 && id <= 10499){
            vertexShdEyePlayerPos.xz += windStrength * 0.1;
            return vertexShdEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 10600 && id <= 10700){
            float isUpper = id == 10700 ? midBlockY - 1.5 : midBlockY - 0.5;
            vertexShdEyePlayerPos.xz += isUpper * windStrength * 0.125;
            return vertexShdEyePlayerPos;
        }

        // Single hanging cutouts
        if(id == 10800 || id == 10801){
            float isLower = midBlockY + 0.5;
            vertexShdEyePlayerPos.xz += isLower * windStrength * 0.0625;
            return vertexShdEyePlayerPos;
        }

        // Multi wall cutouts
        if(id == 10900){
            vertexShdEyePlayerPos.xz += windStrength * 0.05;
            return vertexShdEyePlayerPos;
        }
    }

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexShadowWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Simple blocks, vertical movement
        if(id == 11100 || id == 11101){
            vertexShdEyePlayerPos.y += currentStrength * 0.0625;
            return vertexShdEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id == 11600){
            float isUpper = midBlockY - 0.5;
            vertexShdEyePlayerPos.xz += isUpper * currentStrength * 0.125;
            return vertexShdEyePlayerPos;
        }
    }

    return vertexShdEyePlayerPos;
}