/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, and direct shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

    out vec2 texCoord;

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get vertex color
        vertexColor = gl_Color;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

        // Convert to clip position and output as final position
        // gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        gl_Position.z *= 0.9;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 sceneColOut; // colortex0

    flat in vec4 vertexColor;

    in vec2 texCoord;

    uniform int renderStage;

    #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
        uniform float twilightPhase;
    #endif

    uniform sampler2D gtexture;
    
    void main(){
        // Get albedo color
        vec4 albedo = textureLod(gtexture, texCoord, 0) * vertexColor;

        // Alpha test, discard and return immediately
        if(albedo.a < ALPHA_THRESHOLD){ discard; return; }

        #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
            // Detect sun
            if(renderStage == MC_RENDER_STAGE_SUN){
                // Convert to linear space
                sceneColOut = toLinear(albedo.rgb * albedo.a) * SUN_COL_DATA_BLOCK * sunMoonIntensitySqrd;
                return;
            }

            // Detect moon
            if(renderStage == MC_RENDER_STAGE_MOON){
                // Convert to linear space
                sceneColOut = toLinear(albedo.rgb * albedo.a) * MOON_COL_DATA_BLOCK * sunMoonIntensitySqrd;
                return;
            }
        #else
            // Otherwise BEGONE
            if(renderStage == MC_RENDER_STAGE_SUN){ discard; return; }
            if(renderStage == MC_RENDER_STAGE_MOON){ discard; return; }
        #endif

        // Otherwise calculate skybox
        sceneColOut = toLinear(albedo.rgb * albedo.a) * skyBoxIntensitySqrd;
    }
#endif