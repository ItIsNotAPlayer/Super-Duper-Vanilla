// Wave animation movements for shadow
vec3 getWaterWave(in vec3 vertexShdEyePlayerPos, in vec2 vertexShadowWorldPosXZ, in float id, in float currTime){
    // Current affected blocks
    if(CURRENT_SPEED > 0){
        // Calculate current strength
        float currentStrength = cos(-sumOf(vertexShadowWorldPosXZ) * CURRENT_FREQUENCY + currTime * CURRENT_SPEED);

        // Water
        if(id == 11102){
            #ifdef PHYSICS_OCEAN
                // basic texture to determine how shallow/far away from the shore the water is
                float physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

                // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
                vertexShdEyePlayerPos.y += physics_waveHeight((gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale, physics_localWaviness);
            #endif

            vertexShdEyePlayerPos.y += currentStrength * 0.0625;

            return vertexShdEyePlayerPos;
        }
    }

    return vertexShdEyePlayerPos;
}