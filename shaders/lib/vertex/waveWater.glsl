// Wave animation movements for shadow
vec3 getWaterWave(in vec3 vertexEyePlayerPos, in vec2 vertexWorldPosXZ, in float id, in float currTime){
    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Water
        if(id == 11102){
            vertexEyePlayerPos.y += currentStrength * 0.0625;

            return vertexEyePlayerPos;
        }
    }

    return vertexEyePlayerPos;
}