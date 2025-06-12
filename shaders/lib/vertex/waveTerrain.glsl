// Wave animation movements for shadow
vec3 getTerrainWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float midBlockY, in float id, in float outside, in float currTime){
    // Wind affected blocks
    if(WIND_SPEED > 0){
        // Calculate wind strength
        float windStrength = sin(-sumOf(id == 10801 ? floor(vertexWorldPosXZ) : vertexWorldPosXZ) * WIND_FREQUENCY + currTime * WIND_SPEED) * outside;

        // Simple blocks, horizontal movement
        if(id >= 10000 && id <= 10499){
            vertexEyePlayerPos.xz += windStrength * 0.1;
            return vertexEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id >= 10600 && id <= 10700){
            float isUpper = id == 10700 ? midBlockY - 1.5 : midBlockY - 0.5;
            vertexEyePlayerPos.xz += isUpper * windStrength * 0.125;
            return vertexEyePlayerPos;
        }

        // Single hanging cutouts
        if(id == 10800 || id == 10801){
            float isLower = midBlockY + 0.5;
            vertexEyePlayerPos.xz += isLower * windStrength * 0.0625;
            return vertexEyePlayerPos;
        }

        // Multi wall cutouts
        if(id == 10900){
            vertexEyePlayerPos.xz += windStrength * 0.05;
            return vertexEyePlayerPos;
        }
    }

    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Simple blocks, vertical movement
        if(id == 11100 || id == 11101){
            vertexEyePlayerPos.y += currentStrength * 0.0625;
            return vertexEyePlayerPos;
        }

        // Single and double grounded cutouts
        if(id == 11600){
            float isUpper = midBlockY - 0.5;
            vertexEyePlayerPos.xz += isUpper * currentStrength * 0.125;
            return vertexEyePlayerPos;
        }
    }

    return vertexEyePlayerPos;
}