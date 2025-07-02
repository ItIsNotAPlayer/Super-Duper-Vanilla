/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and dynamic clouds

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined FORCE_DISABLE_CLOUDS || CLOUD_MODE != 0
        void main(){
            gl_Position = vec4(-10);
        }
    #else
        flat out float vertexAlpha;

        #ifdef WORLD_LIGHT
            flat out float vertexNLZ;

            #ifdef SHADOW_MAPPING
                out vec3 vertexShdPos;
            #endif
        #endif

        #if defined SHADOW_MAPPING && defined WORLD_LIGHT
            uniform mat4 gbufferModelViewInverse;
        #endif

        #ifdef WORLD_LIGHT
            uniform mat4 shadowModelView;

            #ifdef SHADOW_MAPPING
                uniform mat4 shadowProjection;
            #endif
        #endif

        #if ANTI_ALIASING == 2
            uniform int frameMod;

            uniform float pixelWidth;
            uniform float pixelHeight;

            #include "/lib/utility/taaJitter.glsl"
        #endif

        void main(){
            // Get vertex alpha and emissive
            vertexAlpha = gl_Color.a;

            // Get vertex view position
            vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

            #ifdef WORLD_LIGHT
                vec3 vertexNormal = mat3(gbufferModelViewInverse) * fastNormalize(gl_NormalMatrix * gl_Normal);

                vertexNLZ = dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));

                #ifdef SHADOW_MAPPING
                    // Get vertex feet player position
                    vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

                    // Calculate shadow pos in vertex
                    vertexShdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexFeetPlayerPos + shadowModelView[3].xyz);
                    vertexShdPos.z += shadowProjection[3].z;
                    
                    vertexShdPos.z = vertexShdPos.z * 0.1 + 0.5;
                #endif
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
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #if defined FORCE_DISABLE_CLOUDS || CLOUD_MODE != 0
        void main(){
            discard; return;
        }
    #else
        /* RENDERTARGETS: 4,3 */
        layout(location = 0) out vec4 sceneColOut; // colortex4
        layout(location = 1) out vec3 materialDataOut; // colortex3

        flat in float vertexAlpha;

        #ifdef WORLD_LIGHT
            flat in float vertexNLZ;

            #ifdef SHADOW_MAPPING
                in vec3 vertexShdPos;
            #endif
        #endif

        uniform float nightVision;
        uniform float lightningFlash;

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

        #ifdef WORLD_LIGHT
            uniform float shdFade;

            #ifdef SHADOW_MAPPING
                #ifdef SHADOW_FILTER
                    #include "/lib/utility/noiseFunctions.glsl"
                #endif

                #include "/lib/lighting/shdMapping.glsl"
            #endif
        #endif

        #include "/lib/lighting/basicShadingForward.glsl"

        void main(){
            // Alpha test, discard and return immediately
            if(vertexAlpha < ALPHA_THRESHOLD){ discard; return; }

            #if COLOR_MODE == 2
                vec4 albedo = vec4(0, 0, 0, vertexAlpha);
            #else
                vec4 albedo = vec4(1, 1, 1, vertexAlpha);
            #endif

            // Apply simple shading
            sceneColOut = vec4(basicShadingForward(albedo.rgb), albedo.a);

            // Write material data
            materialDataOut = vec3(0, 0, 0.5);
        }
    #endif
#endif