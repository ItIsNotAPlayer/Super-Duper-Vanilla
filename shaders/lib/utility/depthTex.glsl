float getDepthTex(in ivec2 screenTexelCoord){
    #ifdef DISTANT_HORIZONS
        float mainDepth = texelFetch(depthtex0, screenTexelCoord, 0).x;

        return mainDepth == 1.0 ? texelFetch(dhDepthTex0, screenTexelCoord, 0).x : mainDepth;
    #else
        return texelFetch(depthtex0, screenTexelCoord, 0).x;
    #endif
}

float getDepthTex(in vec2 screenCoord){
    #ifdef DISTANT_HORIZONS
        float mainDepth = textureLod(depthtex0, screenCoord, 0).x;

        return mainDepth == 1.0 ? textureLod(dhDepthTex0, screenCoord, 0).x : mainDepth;
    #else
        return textureLod(depthtex0, screenCoord, 0).x;
    #endif
}