/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, animation, lava noise, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;

    flat out mat3 TBN;

    out float vertexAO;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec3 vertexColor;
    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef TERRAIN_ANIMATION
        uniform float vertexFrameTime;

        attribute vec3 at_midBlock;

        #include "/lib/vertex/waveTerrain.glsl"
    #endif

    attribute vec3 mc_Entity;

    attribute vec4 at_tangent;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION || defined TERRAIN_ANIMATION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        // Get vertex AO
        vertexAO = gl_Color.a;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = lightMapCoord(gl_MultiTexCoord1.xy);
        #endif

        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);
        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Calculate TBN matrix
	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal) * sign(at_tangent.w), vertexNormal));

        #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
            vec2 midTexCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidTexCoord = texCoord - midTexCoord;

            vTexCoordScale = abs(texMinMidTexCoord) * 2.0;
            vTexCoordPos = min(texCoord, midTexCoord - texMinMidTexCoord);
            vTexCoord = sign(texMinMidTexCoord) * 0.5 + 0.5;
        #endif

        #ifdef TERRAIN_ANIMATION
            // Apply terrain wave animation
            vertexFeetPlayerPos = getTerrainWave(vertexFeetPlayerPos, vertexWorldPos.xz, at_midBlock.y * 0.015625, mc_Entity.x, lmCoord.y, vertexFrameTime);
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;
        #endif

        #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4,1,2,3 */
    layout(location = 0) out vec3 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in int blockId;

    flat in mat3 TBN;

    in float vertexAO;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;
        in vec2 vTexCoord;
    #endif

    // Enable full vanilla AO
    const float ambientOcclusionLevel = 1.0;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform sampler2D gtexture;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/integratedPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #ifdef LAVA_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/lava.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
	    // Declare materials
	    dataPBR material;
        getPBR(material, blockId);

        if(blockId == 11100 || blockId == 13005){
            vec2 blockUv = vertexWorldPos.zy * TBN[2].x + vertexWorldPos.xz * TBN[2].y + vertexWorldPos.xy * TBN[2].z;

            // Lava noise
            if(blockId == 11100){
                #ifdef LAVA_NOISE
                    // Lava tile size inverse
                    const float lavaTileSizeInv = 1.0 / LAVA_TILE_SIZE;

                    float lavaNoise = saturate(max(getLavaNoise(blockUv * lavaTileSizeInv) * 3.0, sumOf(material.albedo.rgb)) - 1.0);
                    material.albedo.rgb = floor(material.albedo.rgb * lavaNoise * LAVA_BRIGHTNESS * 32.0) * 0.03125;
                #else
                    material.albedo.rgb *= LAVA_BRIGHTNESS;
                #endif
            }

            // Sculk noise
            else if(blockId == 13005){
                #ifdef SCULK_NOISE
                    float sculkNoise = texelFetch(noisetex, ivec2((blockUv + fragmentFrameTime) * SCULK_TILE_SIZE) & 255, 0).z;
                    material.emissive = min(1.0, material.emissive * squared(squared(sculkNoise) * 4.0) * SCULK_BRIGHTNESS);
                #else
                    material.emissive *= SCULK_BRIGHTNESS;
                #endif
            }
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 11100 && blockId != 12101) enviroPBR(material, TBN[2]);
        #endif

        // Write to HDR scene color
        sceneColOut = complexShadingForward(material);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif