/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Solid complex shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 skyCol;

    noperspective out vec2 texCoord;

    #ifdef WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat out vec3 sRGBSunCol;
            flat out vec3 sunCol;
            flat out vec3 sRGBMoonCol;
            flat out vec3 moonCol;
        #endif
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        skyCol = toLinear(SKY_COLOR_DATA_BLOCK);

        #ifdef WORLD_LIGHT
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
                lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COL_DATA_BLOCK;
                sunCol = toLinear(sRGBSunCol);
                sRGBMoonCol = MOON_COL_DATA_BLOCK;
                moonCol = toLinear(sRGBMoonCol);
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol);
                lightCol = toLinear(sRGBLightCol);
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 sceneColOut; // gcolor

    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

    #if ANTI_ALIASING >= 2 || defined PREVIOUS_FRAME || defined AUTO_EXPOSURE
        // Disable buffer clear if TAA, previous frame reflections, or auto exposure is on
        const bool colortex5Clear = false;
    #endif

    flat in vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat in vec3 sRGBSunCol;
            flat in vec3 sunCol;
            flat in vec3 sRGBMoonCol;
            flat in vec3 moonCol;
        #endif
    #endif

    noperspective in vec2 texCoord;

    uniform int isEyeInWater;

    uniform float borderFar;

    uniform float blindness;
    uniform float nightVision;
    uniform float lightningFlash;
    uniform float darknessFactor;
    uniform float darknessLightFactor;

    uniform float fragmentFrameTime;

    uniform vec3 fogColor;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    // Main HDR buffer
    uniform sampler2D gcolor;
    uniform sampler2D colortex1;
    // For SSAO and material masks
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;
    
    uniform sampler2D depthtex0;

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    #if ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float dayCycleAdjust;
    #endif

    #if defined STORY_MODE_CLOUDS && !defined FORCE_DISABLE_CLOUDS
        uniform sampler2D colortex4;
    #endif

    #ifdef DISTANT_HORIZONS
        uniform mat4 dhProjection;
        uniform mat4 dhProjectionInverse;

        uniform sampler2D dhDepthTex0;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #include "/lib/utility/projectionFunctions.glsl"

    #ifdef PREVIOUS_FRAME
        uniform vec3 previousCameraPosition;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D colortex5;

        #include "/lib/utility/prevProjectionFunctions.glsl"
    #endif

    #ifdef SSAO
        float getSSAOBoxBlur(in ivec2 screenTexelCoord){
            ivec2 topRightCorner = screenTexelCoord + 1;
            ivec2 bottomLeftCorner = screenTexelCoord - 1;

            float sample0 = texelFetch(colortex2, topRightCorner, 0).a;
            float sample1 = texelFetch(colortex2, bottomLeftCorner, 0).a;
            float sample2 = texelFetch(colortex2, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).a;
            float sample3 = texelFetch(colortex2, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).a;

            return sample0 + sample1 + sample2 + sample3;
        }
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #if OUTLINES != 0
        #if OUTLINES == 1
            uniform float near;
        #endif

        #include "/lib/post/outline.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"
    
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Distant Horizons apparently uses a different depth texture
        #ifdef DISTANT_HORIZONS
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
            bool realSky = depth == 1;
            if(realSky) depth = texelFetch(dhDepthTex0, screenTexelCoord, 0).x;
        #else
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;
        #endif

        // Get screen pos
        vec3 screenPos = vec3(texCoord, depth);

        // Get sky mask
        bool skyMask = screenPos.z == 1;

        // Jitter the sky only
        #if ANTI_ALIASING == 2
            if(skyMask) screenPos.xy += jitterPos(-0.5);
        #endif

        // Distant Horizons apparently uses a different projection matrix
        #ifdef DISTANT_HORIZONS
            vec3 viewPos = getViewPos(realSky ? dhProjectionInverse : gbufferProjectionInverse, screenPos);
        #else
            vec3 viewPos = getViewPos(gbufferProjectionInverse, screenPos);
        #endif

        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

        // Get view distance
        float viewDot = lengthSquared(viewPos);
	    float viewDotInvSqrt = inversesqrt(viewDot);

        // Get normalized eyePlayerPos
        vec3 nEyePlayerPos = eyePlayerPos * viewDotInvSqrt;

        // Get scene color
        sceneColOut = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        // Get sky pos by shadow model view
        vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;

        #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
            // Flip if the sun has gone below the horizon
            if(dayCycle < 1) skyPos.xz = -skyPos.xz;
        #endif

        // Get basic sky simple color
        vec3 currSkyCol = getSkyBasic(nEyePlayerPos.y, skyPos.z);

        // If sky, do full sky render and return immediately
        if(skyMask){
            sceneColOut = getFullSkyRender(nEyePlayerPos, skyPos, currSkyCol + sceneColOut) * exp2(-borderFar * (blindness + darknessFactor));
            return;
        }

        #if ANTI_ALIASING >= 2
            vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
        #else
            vec3 dither = getRng3(screenTexelCoord & 255);
        #endif

        // Declare and get materials
        vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;
        vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
        vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

        // Apply deffered shading
        sceneColOut = complexShadingDeferred(sceneColOut, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, viewDotInvSqrt, matRaw0.x, matRaw0.y, dither);

        #if OUTLINES != 0
            // Outline calculation
            sceneColOut *= 1.0 + getOutline(screenTexelCoord, screenPos.z) * OUTLINE_BRIGHTNESS;
        #endif

        #ifdef SSAO
            // Apply ambient occlusion with simple blur
            sceneColOut *= getSSAOBoxBlur(screenTexelCoord);
        #endif

        float viewDist = viewDot * viewDotInvSqrt;

        // Get basic sky fog color
        vec3 fogSkyCol = getSkyFogRender(nEyePlayerPos, skyPos, currSkyCol);
        // Get fog factor
        float fogFactor = getFogFactor(viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);

        // Border fog
        #ifdef BORDER_FOG
            fogFactor = (fogFactor - 1.0) * getBorderFog(viewDist) + 1.0;
        #endif

        // Apply fog and darkness fog
        sceneColOut = ((fogSkyCol - sceneColOut) * fogFactor + sceneColOut) * getFogDarknessFactor(viewDist);
    }
#endif